import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../utils/result.dart';

/// Abstract interface for database operations
/// Supports both Firestore and PostgreSQL implementations
abstract class IDatabaseService extends GetxService {
  /// Create or update a user profile
  Future<Result<UserProfile>> createProfile(UserProfile profile);

  /// Get user profile by ID
  Future<Result<UserProfile>> getProfile(String userId);

  /// Update user profile
  Future<Result<void>> updateProfile(String userId, Map<String, dynamic> data);

  /// Delete user profile
  Future<Result<void>> deleteProfile(String userId);

  /// Check if connection is available
  Future<bool> isConnected();

  /// Get current database type
  String get databaseType;

  /// Get swipe feed for a user
  /// Returns list of potential matches for swiping
  Future<Result<List<UserProfile>>> getSwipeFeed(
    String userId, {
    int limit = 10,
    int offset = 0,
    String? city,
    double minScore = 65,
  });

  /// Get intelligent swipe feed using matching algorithm
  /// Returns optimized list of compatible matches
  Future<Result<List<UserProfile>>> getIntelligentSwipeFeed(
    String userId, {
    int limit = 20,
  });

  /// Get active matches for user
  Future<Result<List<Match>>> getActiveMatches(String userId, {int limit = 20});

  /// Get match history for user
  Future<Result<List<Match>>> getMatchHistory(String userId);

  /// Get specific match by ID
  Future<Result<Match?>> getMatch(String matchId);

  /// Create a new match between two users
  Future<Result<Match>> createMatch(String user1Id, String user2Id);

  /// Accept a match
  Future<Result<Match>> acceptMatch(String matchId);

  /// Reject a match
  Future<Result<Match>> rejectMatch(String matchId);

  /// Archive a match
  Future<Result<Match>> archiveMatch(String matchId);
}
