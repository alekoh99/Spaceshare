// App Constants and Config Values

class AppPadding {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
}

class AppBorderRadius {
  static const double small = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class SuccessMessages {
  static const String profileCreated = 'Profile created successfully';
  static const String profileUpdated = 'Profile updated successfully';
  static const String avatarUploaded = 'Avatar uploaded successfully';
  static const String paymentInitiated = 'Payment initiated. Complete payment to proceed.';
  static const String paymentCompleted = 'Payment completed successfully';
  static const String matchCreated = 'Match created. You\'re connected!';
  static const String messagesSent = 'Message sent';
  static const String reportFiled = 'Report submitted. Our team will review it soon.';
  static const String notificationsSent = 'Notifications sent';
}

class ErrorMessages {
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String authenticationFailed = 'Authentication failed. Please try again.';
  static const String invalidEmail = 'Invalid email address';
  static const String invalidPhone = 'Invalid phone number';
  static const String profileNotFound = 'Profile not found';
  static const String matchNotFound = 'Match not found';
  static const String paymentFailed = 'Payment failed. Please try again.';
  static const String unknownError = 'An unexpected error occurred';
}

class PaymentMessages {
  static const String minimumAmount = 'Minimum payment is \$1.00';
  static const String maximumAmount = 'Maximum payment is \$10,000.00';
  static const String processingFee = 'This includes processing fees';
  static const String willReceive =
      'Recipient will receive after payment processing (1-2 business days)';
  static const String confirmPayment = 'Confirm payment of ';
  static const String disputeReason = 'Reason for dispute';
  static const String disputeDescription = 'Describe the issue in detail';
}

class NotificationMessages {
  static const String newMatch = 'You have a new match!';
  static const String matchAccepted = 'Your match was accepted!';
  static const String newMessage = 'You have a new message';
  static const String paymentReceived = 'Payment received';
  static const String paymentSent = 'Payment sent';
}

class ValidationMessages {
  static const String nameRequired = 'Name is required';
  static const String emailRequired = 'Email is required';
  static const String phoneRequired = 'Phone number is required';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 8 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String bioRequired = 'Bio is required';
  static const String bioTooShort = 'Bio must be at least 20 characters';
  static const String budgetRequired = 'Budget is required';
  static const String cityRequired = 'City is required';
}

class RouteNames {
  static const String splash = '/splash';
  static const String phoneEntry = '/phone-entry';
  static const String otpVerification = '/otp-verification';
  static const String profileSetup = '/profile-setup';
  static const String home = '/';
  static const String swipeFeed = '/matching';
  static const String matchDetail = '/match-detail';
  static const String activeMatches = '/conversations';
  static const String conversations = '/conversations';
  static const String chatScreen = '/chat';
  static const String paymentSplit = '/payment-split';
  static const String paymentHistory = '/payment-history';
  static const String paymentDetail = '/payment';
  static const String profile = '/profile';
  static const String profileEdit = '/edit-profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String help = '/support';
}

class AssetPaths {
  static const String imagesDir = 'assets/images/';
  static const String iconsDir = 'assets/icons/';
  static const String animationsDir = 'assets/animations/';

  // Images
  static const String placeholderAvatar = '${imagesDir}placeholder_avatar.png';
  static const String splashLogo = '${imagesDir}splash_logo.png';

  // Animations
  static const String loadingAnimation = '${animationsDir}loading.json';
  static const String emptyStateAnimation = '${animationsDir}empty_state.json';
}

class Durations {
  static const Duration short = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);
  static const Duration long = Duration(milliseconds: 800);
  static const Duration extraLong = Duration(seconds: 2);
}

class ApiEndpoints {
  static const String baseUrl = 'https://us-central1-spaceshare-prod.cloudfunctions.net/api';
  static const String createPaymentIntent = '/payments/create-intent';
  static const String confirmPayment = '/payments/confirm';
  static const String getCompatibilityScore = '/matching/compatibility';
}

class FirestoreCollections {
  static const String users = 'users';
  static const String matches = 'matches';
  static const String messages = 'messages';
  static const String conversations = 'conversations';
  static const String payments = 'payments';
  static const String notifications = 'notifications';
  static const String disputes = 'disputes';
  static const String transactions = 'transactions';
  static const String swipes = 'swipes';
  static const String userSubscriptions = 'user_subscriptions';
  static const String supportQueue = 'support_queue';
}

class MatchStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String archived = 'archived';
}

class PaymentStatus {
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String refunded = 'refunded';
  static const String disputed = 'disputed';
}

class NotificationType {
  static const String matchRequest = 'match_request';
  static const String matchAccepted = 'match_accepted';
  static const String message = 'message';
  static const String paymentReceived = 'payment_received';
  static const String paymentSent = 'payment_sent';
  static const String disputeOpened = 'dispute_opened';
  static const String disputeResolved = 'dispute_resolved';
}
