/// Validation utilities for form inputs

/// Email validation regex
/// Matches standard email formats like: user@domain.com
final RegExp emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

/// Validates an email address
/// Returns null if valid, or error message if invalid
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  
  final trimmed = value.trim();
  
  if (!emailRegex.hasMatch(trimmed)) {
    return 'Please enter a valid email address';
  }
  
  if (trimmed.length > 254) {
    return 'Email is too long';
  }
  
  return null;
}

/// Validates a password
/// Returns null if valid, or error message if invalid
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  
  return null;
}

/// Password strength levels
enum PasswordStrength {
  empty,
  weak,        // Less than 8 characters
  fair,        // 8+ characters
  good,        // 8+ with uppercase or number
  strong,      // 8+ with uppercase AND number
  excellent,   // 8+ with uppercase, number, and special char
}

/// Analyzes password strength
/// Returns PasswordStrength enum indicating how strong the password is
PasswordStrength analyzePasswordStrength(String password) {
  if (password.isEmpty) {
    return PasswordStrength.empty;
  }
  
  if (password.length < 8) {
    return PasswordStrength.weak;
  }
  
  bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
  bool hasLowercase = password.contains(RegExp(r'[a-z]'));
  bool hasNumber = password.contains(RegExp(r'[0-9]'));
  bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_-]'));
  
  int score = 0;
  if (hasUppercase) score++;
  if (hasLowercase) score++;
  if (hasNumber) score++;
  if (hasSpecial) score++;
  
  if (score >= 3 && hasSpecial) {
    return PasswordStrength.excellent;
  } else if (score >= 3) {
    return PasswordStrength.strong;
  } else if (score >= 2) {
    return PasswordStrength.good;
  } else {
    return PasswordStrength.fair;
  }
}

/// Gets a human-readable message for password strength
String getPasswordStrengthMessage(PasswordStrength strength) {
  switch (strength) {
    case PasswordStrength.empty:
      return '';
    case PasswordStrength.weak:
      return 'Too short (minimum 8 characters)';
    case PasswordStrength.fair:
      return 'Fair - add more complexity';
    case PasswordStrength.good:
      return 'Good password';
    case PasswordStrength.strong:
      return 'Strong password';
    case PasswordStrength.excellent:
      return 'Excellent password';
  }
}

/// Gets color value for password strength indicator
/// Returns: 0xFF for red, 0xFFFF9000 for orange, 0xFF00FF00 for green, etc.
int getPasswordStrengthColor(PasswordStrength strength) {
  switch (strength) {
    case PasswordStrength.empty:
      return 0xFF9E9E9E; // Grey
    case PasswordStrength.weak:
      return 0xFFF44336; // Red
    case PasswordStrength.fair:
      return 0xFFFF9800; // Orange
    case PasswordStrength.good:
      return 0xFF8BC34A; // Light Green
    case PasswordStrength.strong:
      return 0xFF4CAF50; // Green
    case PasswordStrength.excellent:
      return 0xFF2E7D32; // Dark Green
  }
}

/// Validates that two passwords match
/// Returns null if they match, or error message if they don't
String? validateConfirmPassword(String? password, String? confirmPassword) {
  if (confirmPassword == null || confirmPassword.isEmpty) {
    return 'Please confirm your password';
  }
  
  if (password != confirmPassword) {
    return 'Passwords do not match';
  }
  
  return null;
}

/// Validates a phone number (Nigerian format)
/// Returns null if valid, or error message if invalid
String? validatePhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Phone number is required';
  }
  
  final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  
  // Nigerian phone: starts with 0 (10 digits) or +234 (11 digits after country code)
  if (!RegExp(r'^(\+234|0)[789]\d{9}$').hasMatch(cleaned)) {
    return 'Please enter a valid Nigerian phone number';
  }
  
  return null;
}

/// Validates a required field
/// Returns null if not empty, or error message if empty
String? validateRequired(String? value, [String fieldName = 'This field']) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

/// Validates minimum length
/// Returns null if valid, or error message if too short
String? validateMinLength(String? value, int minLength, [String fieldName = 'This field']) {
  if (value == null || value.isEmpty) {
    return null; // Let required() handle empty
  }
  
  if (value.length < minLength) {
    return '$fieldName must be at least $minLength characters';
  }
  
  return null;
}
