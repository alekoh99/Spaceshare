import '../models/user_model.dart';
import '../models/match_model.dart';

/// Authentication Service Specification
abstract class IAuthService {
  // Phone authentication
  Future<String> sendOTP(String phone);
  Future<String> verifyOTP(String phone, String otp, String sessionId);
  Future<void> signOut();
  Future<String?> getCurrentUserId();
  Future<bool> isAuthenticated();

  // Email verification
  Future<void> sendEmailVerification(String email);
  Future<bool> isEmailVerified(String userId);
}

/// User Service Specification
abstract class IUserService {
  Future<UserProfile> createProfile(UserProfile profile);
  Future<UserProfile> getProfile(String userId);
  Future<void> updateProfile(String userId, UserProfile profile);
  Future<void> deleteProfile(String userId);
  Future<String> uploadAvatar(String userId, String imagePath);
  Future<void> connectStripeAccount(String userId, String stripeConnectId);
  Future<Map<String, dynamic>> getUserStats(String userId);
  Future<List<UserProfile>> searchUsers({
    required String city,
    required double budgetMin,
    required double budgetMax,
    String? neighborhood,
    int limit = 50,
  });
}

/// Matching Service Specification
abstract class IMatchingService {
  /// Calculate compatibility score between two users
  /// 
  /// Algorithm:
  /// compatibilityScore = (
  ///   (1 - |userA.cleanliness - userB.cleanliness| / 10) * 0.2 +
  ///   (1 - |userA.sleepSchedule - userB.sleepSchedule| / 10) * 0.2 +
  ///   (1 - |userA.social - userB.social| / 10) * 0.2 +
  ///   (1 - |userA.noise - userB.noise| / 10) * 0.2 +
  ///   (1 - |userA.financial - userB.financial| / 10) * 0.2
  /// ) * 100
  /// 
  /// Returns score 0-100, only show if > 65
  Future<Map<String, dynamic>> calculateScore(
    UserProfile user1,
    UserProfile user2,
  );

  Future<Match> createMatch(String user1Id, String user2Id);
  Future<Match> acceptMatch(String matchId);
  Future<Match> rejectMatch(String matchId);
  Future<Match> archiveMatch(String matchId);
  
  Future<List<UserProfile>> getSwipeFeed(
    String userId, {
    int limit = 10,
    int offset = 0,
    String? city,
    double minScore = 65,
  });
  
  Future<List<Match>> getActiveMatches(String userId, {int limit = 20});
  Future<List<Match>> getMatchHistory(String userId);
  Future<Match?> getMatch(String matchId);
}

/// Messaging Service Specification
abstract class IMessagingService {
  Future<void> sendMessage(
    String matchId,
    String senderId,
    String text,
  );
  
  Future<List<Map<String, dynamic>>> getMessages(
    String matchId, {
    int limit = 50,
    int offset = 0,
  });
  
  Future<void> markMessageAsRead(String messageId);
  Future<void> markConversationAsRead(String matchId);
  
  Future<List<Map<String, dynamic>>> getConversations(String userId);
  
  // Real-time stream
  Stream<Map<String, dynamic>> getMessageStream(String matchId);
}

/// Payment Service Specification
abstract class IPaymentService {
  /// Create a Stripe PaymentIntent for rent/utility split
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String type,
    required String description,
    required String recipientUserId,
    required DateTime dueDate,
    String? matchId,
  });

  /// Confirm payment after Stripe transaction
  Future<Map<String, dynamic>> confirmPayment(
    String paymentId,
    String stripePaymentIntentId,
  );

  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(
    String userId, {
    int limit = 50,
    int offset = 0,
    String? status,
  });

  /// File a payment dispute
  Future<Map<String, dynamic>> fileDispute(
    String paymentId,
    String reason,
  );

  Future<Map<String, dynamic>> getPayment(String paymentId);
}

/// Identity Verification Service Specification
abstract class IIdentityService {
  Future<Map<String, dynamic>> startVerification(String userId);
  Future<String?> getVerificationStatus(String userId);
  Future<bool> isVerified(String userId);
}

/// Notification Service Specification
abstract class INotificationService {
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? actionUrl,
  });

  Future<List<Map<String, dynamic>>> getNotifications(
    String userId, {
    int limit = 50,
    bool unreadOnly = false,
  });

  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  
  Future<int> getUnreadCount(String userId);
}

/// Report Service Specification
abstract class IReportService {
  Future<Map<String, dynamic>> fileReport({
    required String reportedByUserId,
    required String reportedUserId,
    required String category,
    required String description,
  });

  Future<Map<String, dynamic>> getReport(String reportId);
}

/// Analytics Service Specification
abstract class IAnalyticsService {
  Future<void> logEvent(String eventName, Map<String, dynamic> parameters);
  
  Future<void> logMatchCreated(String matchId, double compatibilityScore);
  Future<void> logMatchAccepted(String matchId);
  Future<void> logMatchRejected(String matchId);
  Future<void> logMessageSent(String matchId);
  Future<void> logPaymentInitiated(double amount, String type);
  Future<void> logPaymentCompleted(double amount, String type);
  Future<void> logReportFiled(String category);
}

/// Implementation Architecture Notes:
/// 
/// 1. All services should follow the Repository Pattern
/// 2. Dependencies:
///    - AuthService: Firebase Auth, phone/email verification
///    - UserService: Firestore users collection
///    - MatchingService: Firestore matches collection, UserService for compatibility data
///    - MessagingService: Firebase Realtime DB for real-time, Firestore for history
///    - PaymentService: Stripe Connect API, Firestore payments collection
///    - IdentityService: Stripe Identity API
///    - NotificationService: Firebase Cloud Messaging, Firestore notifications
///    - ReportService: Firestore reports collection
///    - AnalyticsService: Firebase Analytics
/// 
/// 3. Error Handling:
///    - All services should throw custom exceptions (AppException)
///    - Wrap Firebase/Stripe errors with meaningful messages
///    - Log all errors for debugging
/// 
/// 4. Caching Strategy:
///    - UserService: Cache profiles for 5 minutes
///    - MatchingService: Cache matches for 1 minute
///    - MessagingService: Cache last 100 messages in-memory
/// 
/// 5. Security:
///    - Validate all inputs
///    - Use Firebase Security Rules for Firestore access
///    - Never expose sensitive data (Stripe keys, etc.)
///    - Sanitize user inputs before storage
/// 
/// 6. Logging:
///    - Use Firebase Crashlytics for errors
///    - Log all API calls with timestamp and duration
///    - Track service health metrics
