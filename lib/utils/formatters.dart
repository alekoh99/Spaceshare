import 'package:intl/intl.dart';

class Formatters {
  /// Format currency amount
  static String formatCurrency(double? amount, String currencyCode) {
    if (amount == null) return '\$0.00';
    try {
      final formatter = NumberFormat.currency(
        symbol: _getCurrencySymbol(currencyCode),
        decimalDigits: 2,
      );
      return formatter.format(amount);
    } catch (e) {
      return '\$${amount.toStringAsFixed(2)}';
    }
  }

  /// Get currency symbol
  static String _getCurrencySymbol(String currencyCode) {
    const Map<String, String> symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CAD': 'C\$',
      'AUD': 'A\$',
    };
    return symbols[currencyCode.toUpperCase()] ?? '\$';
  }

  /// Format phone number
  static String formatPhoneNumber(String? number) {
    if (number == null || number.isEmpty) return '';
    final digits = number.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return number;
  }

  /// Format date
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    final formatter = DateFormat('MMM dd, yyyy');
    return formatter.format(date);
  }

  /// Format date and time
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final formatter = DateFormat('MMM dd, yyyy - hh:mm a');
    return formatter.format(dateTime);
  }

  /// Format time only
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final formatter = DateFormat('hh:mm a');
    return formatter.format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      final formatter = DateFormat('MMM dd');
      return formatter.format(dateTime);
    }
  }

  /// Format large numbers with K, M, B suffix
  static String formatCompactNumber(int? number) {
    if (number == null) return '0';
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else if (number < 1000000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    }
  }

  /// Format percentage
  static String formatPercentage(double? value) {
    if (value == null) return '0%';
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  /// Capitalize first letter
  static String capitalize(String? value) {
    if (value == null || value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Format user name (capitalize each word)
  static String formatName(String? name) {
    if (name == null || name.isEmpty) return '';
    return name.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Format address
  static String formatAddress(String? street, String? city, String? state, String? zip) {
    final parts = <String>[];
    if (street != null && street.isNotEmpty) parts.add(street);
    if (city != null && city.isNotEmpty) parts.add(city);
    if (state != null && state.isNotEmpty) parts.add(state);
    if (zip != null && zip.isNotEmpty) parts.add(zip);
    return parts.join(', ');
  }

  /// Remove special characters
  static String removeSpecialCharacters(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  /// Truncate text with ellipsis
  static String truncate(String? value, int length) {
    if (value == null || value.length <= length) return value ?? '';
    return '${value.substring(0, length)}...';
  }
}
