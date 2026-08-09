"""
Partner Provisioning Routes
============================
Allows verified partner apps (like Desby) to auto-provision API keys
for their users. Partner identity is validated via a shared secret
stored in environment variables. No new database tables required —
uses the existing api_keys table with partner-prefixed keys.

Flow:
  1. Partner calls POST /api/v2/keys/partner-provision
     with x-partner-key header + partner_user_id in body
  2. Korra validates partner key against env var list
  3. If user already has a key, returns it (idempotent)
  4. If not, creates api_keys entry with partner's default tier
  5. Returns the Korra API key

Environment Variables:
  PARTNER_KEYS = JSON object mapping partner_key -> {name, default_tier, allowed_tiers}
  Example: {"korra_partner_desby_abc123": {"name": "Desby OS", "default_tier": "tailor_elite", "allowed_tiers": ["tailor_pro", "tailor_elite"]}}
"""
import uuid
import os
import json
import logging
from datetime import datetime
from fastapi import APIRouter, HTTPException, Header
from pydantic import BaseModel
from typing import Optional, List
from api.services.database_service import DatabaseService
from middleware.subscription_check import SUBSCRIPTION_QUOTAS

logger = logging.getLogger("KORRA_PARTNER")

router = APIRouter()

# Partner registry from environment
def _get_partner_registry() -> dict:
    """Parse partner keys from environment variable."""
    raw = os.environ.get("PARTNER_KEYS", "{}")
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        logger.error("Invalid PARTNER_KEYS JSON")
        return {}


class PartnerProvisionRequest(BaseModel):
    """Request to provision an API key for a partner's user."""
    partner_user_id: str  # The partner's internal user ID
    tier: Optional[str] = None  # Override tier


def _validate_partner(partner_key: str) -> dict:
    """Validate partner identity against env var registry."""
    if not partner_key:
        raise HTTPException(status_code=401, detail="Partner API key required (x-partner-key header)")

    registry = _get_partner_registry()
    if partner_key not in registry:
        raise HTTPException(status_code=403, detail="Invalid or inactive partner key")

    return registry[partner_key]


def _get_or_create_api_key(db, korra_user_id: str, tier: str) -> dict:
    """Look up or create a Korra API key for a user."""
    # Check for existing active key
    result = db.table("api_keys").select("key, tier").eq(
        "user_id", korra_user_id
    ).eq("is_active", True).execute()

    if result.data:
        key_data = result.data[0]
        # Update tier if changed
        if tier and key_data.get("tier") != tier:
            db.table("api_keys").update({"tier": tier}).eq(
                "key", key_data["key"]
            ).execute()
            key_data["tier"] = tier
        return key_data

    # Create new key
    new_key = f"korra_live_{uuid.uuid4().hex[:20]}"
    db.table("api_keys").insert({
        "key": new_key,
        "user_id": korra_user_id,
        "tier": tier,
        "is_active": True,
        "created_at": datetime.utcnow().isoformat(),
    }).execute()

    return {"key": new_key, "tier": tier}


@router.post("/keys/partner-provision")
async def partner_provision_key(
    payload: PartnerProvisionRequest,
    x_partner_key: str = Header(None),
):
    """
    Provision a Korra API key for a partner's user.

    Authentication:
      - x-partner-key: Partner's API key (issued by Korra, stored in env)

    The partner_user_id is the partner's internal ID for the user.
    Korra generates and returns a Korra API key scoped to this user.

    Idempotent: calling twice returns the same key.
    """
    # 1. Validate partner identity
    partner_config = _validate_partner(x_partner_key)

    partner_name = partner_config.get("name", "unknown")
    default_tier = partner_config.get("default_tier", "tailor_pro")
    allowed_tiers = partner_config.get("allowed_tiers", ["tailor_pro", "tailor_elite"])

    # 2. Determine tier
    tier = payload.tier or default_tier
    if tier not in allowed_tiers:
        raise HTTPException(
            status_code=400,
            detail=f"Tier '{tier}' not allowed for partner '{partner_name}'. Allowed: {allowed_tiers}"
        )

    # 3. Validate tier exists
    if tier not in SUBSCRIPTION_QUOTAS:
        raise HTTPException(status_code=400, detail=f"Invalid tier: {tier}")

    # 4. Get or create API key
    db = DatabaseService.get_client()
    if not db:
        raise HTTPException(status_code=503, detail="Database unavailable")

    # Use partner-prefixed user_id to avoid collisions
    korra_user_id = f"partner_{partner_name.lower().replace(' ', '_')}_{payload.partner_user_id}"
    key_data = _get_or_create_api_key(db, korra_user_id, tier)

    logger.info(f"🔑 Partner key provisioned: partner={partner_name} user={payload.partner_user_id[:16]}... tier={tier}")

    return {
        "status": True,
        "data": {
            "api_key": key_data["key"],
            "tier": tier,
            "korra_user_id": korra_user_id,
            "quota": SUBSCRIPTION_QUOTAS.get(tier, 0),
        }
    }


@router.get("/keys/partner-status")
async def partner_user_status(
    x_partner_key: str = Header(None),
    partner_user_id: str = Header(None),
):
    """
    Check if a partner's user already has a Korra API key.
    """
    partner_config = _validate_partner(x_partner_key)
    partner_name = partner_config.get("name", "unknown")

    db = DatabaseService.get_client()
    if not db:
        raise HTTPException(status_code=503, detail="Database unavailable")

    korra_user_id = f"partner_{partner_name.lower().replace(' ', '_')}_{partner_user_id}"

    result = db.table("api_keys").select("key, tier, is_active").eq(
        "user_id", korra_user_id
    ).eq("is_active", True).execute()

    if not result.data:
        return {"status": True, "data": {"provisioned": False}}

    key_data = result.data[0]
    return {
        "status": True,
        "data": {
            "provisioned": True,
            "api_key": key_data["key"],
            "tier": key_data["tier"],
            "korra_user_id": korra_user_id,
        }
    }
