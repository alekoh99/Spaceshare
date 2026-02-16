class Validators {
  /// Validate email format
  static bool email(String? value) {
    if (value == null || value.isEmpty) return false;
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(value);
  }

  /// Validate phone number (basic)
  static bool phoneNumber(String? value) {
    if (value == null || value.isEmpty) return false;
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^\d]'), ''));
  }

  /// Validate password strength
  static bool password(String? value) {
    if (value == null || value.length < 8) return false;
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));
    return hasUppercase && hasLowercase && hasDigit;
  }

  /// Validate payment amount
  static bool paymentAmount(String? value) {
    if (value == null || value.isEmpty) return false;
    final amount = double.tryParse(value);
    return amount != null && amount > 0 && amount <= 100000;
  }

  /// Validate username
  static bool username(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.length >= 3 && value.length <= 20;
  }

  /// Validate URL
  static bool url(String? value) {
    if (value == null || value.isEmpty) return false;
    final urlRegex = RegExp(
      r'^(https?://)?'
      r'((www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*))$',
    );
    return urlRegex.hasMatch(value);
  }

  /// Validate age
  static bool age(int? value) {
    return value != null && value >= 18 && value <= 120;
  }

  /// Validate budget range
  static bool budgetRange(double? min, double? max) {
    if (min == null || max == null) return false;
    return min > 0 && max > min;
  }

  /// Required field validation
  static bool required(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validate minimum length
  static bool minLength(String? value, int length) {
    return value != null && value.length >= length;
  }

  /// Validate maximum length
  static bool maxLength(String? value, int length) {
    return value != null && value.length <= length;
  }
}
