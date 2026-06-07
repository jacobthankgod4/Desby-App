"""
Subscription Check Middleware
========================
Validates API keys and tracks subscription usage for AI Body Scan feature.

This middleware ensures:
1. Only paid subscribers can access AI measurement API
2. Tracks usage against quota limits
3. Logs usage for analytics
"""

import os
import json
from datetime import datetime, timedelta
from pathlib import Path

# ============================================================================
# CONFIGURATION
# ============================================================================

# Subscription quotas per tier (monthly scans allowed)
SUBSCRIPTION_QUOTAS = {
    'tailor_basic': 0,       # No AI scans for free tier
    'tailor_pro': 10,        # PRO tier: 10 scans/month
    'tailor_elite': 50,      # BUSINESS tier: 50 scans/month
    'enterprise': 200,      # Enterprise: 200 scans/month
}

# API keys mapping (in production, use database/Firebase)
API_KEYS_FILE = Path(__file__).parent.parent / 'data' / 'api_keys.json'

# Ensure data directory exists
API_KEYS_FILE.parent.mkdir(parents=True, exist_ok=True)

# Initialize API keys file if not exists
if not API_KEYS_FILE.exists():
    default_keys = {}
    with open(API_KEYS_FILE, 'w') as f:
        json.dump(default_keys, f)

# Usage log file
USAGE_LOG_FILE = Path(__file__).parent.parent / 'data' / 'usage_log.json'

if not USAGE_LOG_FILE.exists():
    with open(USAGE_LOG_FILE, 'w') as f:
        json.dump({}, f)

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

def load_api_keys():
    """Load API keys from storage."""
    try:
        with open(API_KEYS_FILE, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_api_keys(keys):
    """Save API keys to storage."""
    with open(API_KEYS_FILE, 'w') as f:
        json.dump(keys, f, indent=2)


def load_usage_log():
    """Load usage log from storage."""
    try:
        with open(USAGE_LOG_FILE, 'r') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_usage_log(log):
    """Save usage log to storage."""
    with open(USAGE_LOG_FILE, 'w') as f:
        json.dump(log, f, indent=2)


def get_user_quota(api_key):
    """
    Get user's subscription tier and quota.
    
    Returns:
        dict: {
            'valid': bool,
            'tier': str or None,
            'quota': int,
            'used': int,
            'remaining': int,
            'reset_date': str
        }
    """
    keys = load_api_keys()
    
    if api_key not in keys:
        return {
            'valid': False,
            'error': 'Invalid API key',
            'tier': None,
            'quota': 0,
            'used': 0,
            'remaining': 0,
        }
    
    user_data = keys[api_key]
    tier = user_data.get('tier', 'tailor_basic')
    quota = SUBSCRIPTION_QUOTAS.get(tier, 0)
    
    # Get usage for this user
    usage_log = load_usage_log()
    user_usage = usage_log.get(api_key, {})
    
    # Calculate used scans this month
    now = datetime.now()
    month_key = f"{now.year}-{now.month:02d}"
    used = user_usage.get('monthly', {}).get(month_key, 0)
    
    # Calculate remaining
    remaining = max(0, quota - used)
    
    # Reset date (first of next month)
    if now.month == 12:
        reset_date = datetime(now.year + 1, 1, 1)
    else:
        reset_date = datetime(now.year, now.month + 1, 1)
    
    return {
        'valid': True,
        'tier': tier,
        'quota': quota,
        'used': used,
        'remaining': remaining,
        'reset_date': reset_date.isoformat(),
    }


def validate_subscription(api_key):
    """
    Validate subscription for API access.
    
    Args:
        api_key: API key from request header or form
        
    Returns:
        dict: {
            'valid': bool,
            'error': str or None,
            'quota_exceeded': bool
        }
    """
    # If no API key provided, reject (no guest access)
    if not api_key:
        return {
            'valid': False,
            'error': 'API key required. Upgrade to Business tier for AI Body Scan.',
            'quota_exceeded': False
        }
    
    # Get quota info
    quota_info = get_user_quota(api_key)
    
    if not quota_info.get('valid'):
        return {
            'valid': False,
            'error': quota_info.get('error', 'Invalid API key'),
            'quota_exceeded': False
        }
    
    tier = quota_info['tier']
    quota = quota_info['quota']
    
    # Check if tier has any quota
    if quota == 0:
        return {
            'valid': False,
            'error': f'AI Body Scan not included in your {tier.replace("_", " ").title()} plan. Upgrade to access.',
            'quota_exceeded': True
        }
    
    remaining = quota_info['remaining']
    
    # Check if quota exceeded
    if remaining <= 0:
        return {
            'valid': False,
            'error': f'Monthly scan quota exhausted ({quota} scans). Upgrade for more scans.',
            'quota_exceeded': True
        }
    
    return {
        'valid': True,
        'error': None,
        'quota_exceeded': False,
        'remaining': remaining
    }


def track_usage(api_key):
    """
    Track API usage for billing/analytics.
    
    Args:
        api_key: API key used
    """
    if not api_key:
        return
    
    try:
        usage_log = load_usage_log()
        
        now = datetime.now()
        month_key = f"{now.year}-{now.month:02d}"
        day_key = now.strftime('%Y-%m-%d')
        
        if api_key not in usage_log:
            usage_log[api_key] = {
                'monthly': {},
                'daily': {},
                'total': 0,
                'created': now.isoformat()
            }
        
        # Increment monthly
        if month_key not in usage_log[api_key]['monthly']:
            usage_log[api_key]['monthly'][month_key] = 0
        usage_log[api_key]['monthly'][month_key] += 1
        
        # Increment daily
        if day_key not in usage_log[api_key]['daily']:
            usage_log[api_key]['daily'][day_key] = 0
        usage_log[api_key]['daily'][day_key] += 1
        
        # Total
        usage_log[api_key]['total'] += 1
        
        # Last used
        usage_log[api_key]['last_used'] = now.isoformat()
        
        save_usage_log(usage_log)
        
        print(f"✓ Usage tracked for {api_key}: {month_key}")
        
    except Exception as e:
        print(f"⚠ Failed to track usage: {e}")


def generate_api_key(user_id, tier='tailor_elite'):
    """
    Generate a new API key for a user.
    
    Args:
        user_id: User ID (tailor ID)
        tier: Subscription tier
        
    Returns:
        str: Generated API key
    """
    import hashlib
    import secrets
    
    # Generate random key
    raw_key = f"{user_id}_{datetime.now().isoformat()}_{secrets.token_hex(16)}"
    api_key = hashlib.sha256(raw_key.encode()).hexdigest()[:32]
    
    # Store
    keys = load_api_keys()
    keys[api_key] = {
        'user_id': user_id,
        'tier': tier,
        'created': datetime.now().isoformat(),
        'active': True
    }
    save_api_keys(keys)
    
    return api_key


def revoke_api_key(api_key):
    """Revoke an API key."""
    keys = load_api_keys()
    if api_key in keys:
        keys[api_key]['active'] = False
        save_api_keys(keys)
        return True
    return False


def get_usage_stats(api_key):
    """Get usage statistics for an API key."""
    usage_log = load_usage_log()
    
    if api_key not in usage_log:
        return {
            'total': 0,
            'this_month': 0,
            'this_week': 0,
            'this_day': 0
        }
    
    user_usage = usage_log[api_key]
    now = datetime.now()
    month_key = f"{now.year}-{now.month:02d}"
    
    # This month
    this_month = user_usage.get('monthly', {}).get(month_key, 0)
    
    # This week (approximate)
    week_start = now - timedelta(days=now.weekday())
    this_week = sum(
        count for date, count in user_usage.get('daily', {}).items()
        if datetime.strptime(date, '%Y-%m-%d') >= week_start
    )
    
    # Today
    today_key = now.strftime('%Y-%m-%d')
    this_day = user_usage.get('daily', {}).get(today_key, 0)
    
    return {
        'total': user_usage.get('total', 0),
        'this_month': this_month,
        'this_week': this_week,
        'this_day': this_day
    }


# ============================================================================
# HELPER FOR TESTING
# ============================================================================

def create_test_key():
    """Create a test API key for development."""
    return generate_api_key('test_user', 'tailor_elite')


if __name__ == '__main__':
    # Test key generation
    test_key = create_test_key()
    print(f"Test API Key: {test_key}")
    
    # Validate
    result = validate_subscription(test_key)
    print(f"Validation: {result}")
    
    # Track usage
    track_usage(test_key)
    print(f"Usage: {get_usage_stats(test_key)}")
