import 'package:intl/intl.dart';

class Validators {
  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Validate OTP
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must contain only digits';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name must not exceed 50 characters';
    }
    return null;
  }

  /// Validate age
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Age must be a number';
    }
    if (age < 18) {
      return 'You must be at least 18 years old';
    }
    if (age > 120) {
      return 'Please enter a valid age';
    }
    return null;
  }

  /// Validate bio
  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bio is required';
    }
    if (value.length < 10) {
      return 'Bio must be at least 10 characters';
    }
    if (value.length > 500) {
      return 'Bio must not exceed 500 characters';
    }
    return null;
  }

  /// Validate budget
  static String? validateBudget(String? value) {
    if (value == null || value.isEmpty) {
      return 'Budget is required';
    }
    final budget = double.tryParse(value);
    if (budget == null) {
      return 'Please enter a valid amount';
    }
    if (budget < 0) {
      return 'Budget cannot be negative';
    }
    return null;
  }

  /// Validate budget range
  static String? validateBudgetRange(double? minBudget, double? maxBudget) {
    if (minBudget == null || maxBudget == null) {
      return 'Budget range is required';
    }
    if (minBudget < 0 || maxBudget < 0) {
      return 'Budget cannot be negative';
    }
    if (minBudget >= maxBudget) {
      return 'Max budget must be greater than min budget';
    }
    return null;
  }

  /// Validate payment amount
  static String? validatePaymentAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount < 1.0) {
      return 'Minimum payment is \$1.00';
    }
    if (amount > 10000.0) {
      return 'Maximum payment is \$10,000.00';
    }
    return null;
  }

  /// Validate description
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    if (value.length < 3) {
      return 'Description must be at least 3 characters';
    }
    if (value.length > 200) {
      return 'Description must not exceed 200 characters';
    }
    return null;
  }

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is optional';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate date is in future
  static String? validateFutureDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    if (date.isBefore(DateTime.now())) {
      return 'Date must be in the future';
    }
    return null;
  }

  /// Validate not empty
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Convenience methods (aliases for shorter names)
  static String? phone(String? value) => validatePhone(value);
  static String? otp(String? value) => validateOTP(value);
  static String? name(String? value) => validateName(value);
  static String? age(String? value) => validateAge(value);
  static String? bio(String? value) => validateBio(value);
  static String? budget(String? value) => validateBudget(value);
  static String? budgetRange(double? minBudget, double? maxBudget) => validateBudgetRange(minBudget, maxBudget);
  static String? paymentAmount(String? value) => validatePaymentAmount(value);
  static String? email(String? value) => validateEmail(value);
  static String? futureDate(DateTime? date) => validateFutureDate(date);
  static String? required(String? value, {String fieldName = 'This field'}) => validateRequired(value, fieldName: fieldName);
}

class Formatters {
  /// Format currency
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol${formatter.format(amount)}';
  }

  /// Format date
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Format date for display
  static String formatDateDisplay(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  /// Format time
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// Format phone number
  static String formatPhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    } else if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      final nineDigits = digitsOnly.substring(1);
      return '+1 (${nineDigits.substring(0, 3)}) ${nineDigits.substring(3, 6)}-${nineDigits.substring(6)}';
    }

    return phone;
  }

  /// Format percentage
  static String formatPercentage(double value, {int decimals = 0}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format compatibility score
  static String formatCompatibilityScore(double score) {
    if (score >= 80) {
      return 'Excellent Match';
    } else if (score >= 65) {
      return 'Good Match';
    } else if (score >= 50) {
      return 'Fair Match';
    } else {
      return 'Low Match';
    }
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Truncate text
  static String truncate(String text, int length, {String suffix = '...'}) {
    if (text.length <= length) return text;
    return text.substring(0, length) + suffix;
  }

  /// Format address
  static String formatAddress(String city, String state) {
    return '$city, $state';
  }

  /// Format user initial for avatar
  static String getUserInitial(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}

extension DateTimeExtension on DateTime {
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is within current week
  bool get isThisWeek {
    final now = DateTime.now();
    final diff = now.difference(this).inDays;
    return diff <= 7 && diff >= 0;
  }

  /// Get formatted relative time
  String get relativeTime {
    return Formatters.formatDate(this);
  }
}

extension StringExtension on String {
  /// Check if string is numeric
  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  /// Check if string is valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is valid phone
  bool get isValidPhone {
    final digitsOnly = replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 10;
  }

  /// Capitalize first letter
  String get capitalize {
    return Formatters.capitalize(this);
  }

  /// Truncate string
  String truncate(int length, {String suffix = '...'}) {
    return Formatters.truncate(this, length, suffix: suffix);
  }
}
