class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'https://us-central1-spaceshare-prod.cloudfunctions.net/api';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Firebase Configuration
  static const String firebaseProjectId = 'spaceshare-prod';
  static const String firebaseRegion = 'us-central1';

  // App Configuration
  static const String appName = 'SpaceShare';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // Feature Flags
  static const bool enableStripePayments = true;
  static const bool enableVideoCalls = false;
  static const bool enableBackgroundChecks = false;

  // Stripe Configuration
  // NOTE: Replace with actual live key from https://dashboard.stripe.com/apikeys
  static const String stripePublishableKey = 'pk_live_51234567890abcdefghijklmnop'; // UPDATE BEFORE PRODUCTION
  static const double platformFeePercentage = 0.02;

  // AdMob Configuration
  static const String admobAppId = 'ca-app-pub-1043698720771126~8457472885';
  
  // AdMob Banner Ad Unit IDs
  static const String admobBannerAdUnitId = 'ca-app-pub-1043698720771126/3891541916';
  static const String admobInterstitialAdUnitId = 'ca-app-pub-1043698720771126/3891541916';
  static const String admobRewardedAdUnitId = 'ca-app-pub-1043698720771126/3891541916';

  // Messaging
  static const int maxPreMatchMessages = 5;
  static const int messageRetentionDays = 90;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const int userProfileCacheDurationMinutes = 5;
  static const int conversationCacheDurationMinutes = 1;

  // Compatibility
  static const double minCompatibilityScore = 65.0;

  // Payment
  static const double minPaymentAmount = 1.0;
  static const double maxPaymentAmount = 10000.0;
}
