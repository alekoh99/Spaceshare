import 'package:firebase_auth/firebase_auth.dart';

extension FirebaseAuthErrorHandler on FirebaseAuthException {
  String get userFriendlyMessage {
    switch (code) {
      // Email/Password errors
      case 'user-not-found':
        return 'No account found with this email. Please create a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'invalid-email':
        return 'Invalid email format. Please check and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'This authentication method is not available. Please try another.';
      
      // Account errors
      case 'account-exists-with-different-credential':
        return 'An account exists with this email using a different sign-in method.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'credential-already-in-use':
        return 'This credential is already in use by another account.';
      
      // Network/Connection errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'service-not-available':
        return 'Service temporarily unavailable. Please try again.';
      
      // Google Sign-In specific
      case 'invalid-api-key':
        return 'Authentication configuration error. Please contact support.';
      case 'app-not-authorized':
        return 'App not authorized for authentication. Please contact support.';
      
      // Default
      default:
        return message ?? 'Authentication failed. Please try again.';
    }
  }

  bool get isNetworkError {
    return code == 'network-request-failed' ||
        code == 'service-not-available' ||
        code == 'timeout';
  }

  bool get isCredentialError {
    return code == 'wrong-password' ||
        code == 'user-not-found' ||
        code == 'invalid-credential';
  }

  bool get isAccountError {
    return code == 'email-already-in-use' ||
        code == 'account-exists-with-different-credential' ||
        code == 'user-disabled';
  }

  bool get isRetryable {
    return isNetworkError || code == 'too-many-requests';
  }
}

class AuthValidationHelper {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  static String? validatePasswordConfirm(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (password != confirm) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  static bool isStrongPassword(String password) {
    return password.length >= 12 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }
}

class AuthSessionHelper {
  static const Duration defaultSessionTimeout = Duration(minutes: 30);
  static const Duration rememberMeSessionTimeout = Duration(days: 30);

  static bool isSessionExpired(DateTime lastActivity) {
    return DateTime.now().difference(lastActivity) > defaultSessionTimeout;
  }

  static bool isRememberMeSessionExpired(DateTime createdAt) {
    return DateTime.now().difference(createdAt) > rememberMeSessionTimeout;
  }
}

class AuthConstants {
  static const String googleSignInScopes = 'email profile';
  static const int maxSignInAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
}
