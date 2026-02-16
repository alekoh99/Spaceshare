import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../utils/result.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;
import 'database_service.dart';

/// Firebase Realtime Database implementation of database service
class FirebaseRealtimeDatabaseService extends GetxService implements IDatabaseService {
  late final FirebaseDatabase _database;
  bool _networkEnabled = true;
  
  // Timeout constants
  static const Duration _readTimeout = Duration(seconds: 20);
  static const Duration _writeTimeout = Duration(seconds: 15);
  static const int _maxRetries = 3;

  @override
  Future<void> onInit() async {
    super.onInit();
    _database = FirebaseDatabase.instance;
    // Set persistence enabled for offline support (not available on web)
    if (!kIsWeb) {
      try {
        _database.setPersistenceEnabled(true);
      } catch (e) {
        AppLogger.warning('RealtimeDatabase', 'Could not enable persistence: $e');
      }
    }
  }

  @override
  String get databaseType => 'Firebase Realtime Database';

  /// Retry helper for database operations
  Future<T> _retryOperation<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < _maxRetries) {
      try {
        attempt++;
        AppLogger.debug('RealtimeDatabase', '$operationName attempt $attempt/$_maxRetries');
        return await operation().timeout(_readTimeout);
      } on TimeoutException catch (e) {
        lastError = e;
        AppLogger.warning('RealtimeDatabase', '$operationName timeout on attempt $attempt: $e');
        if (attempt < _maxRetries) {
          final delayMs = 500 * (1 << (attempt - 1));
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } catch (e) {
        rethrow;
      }
    }

    throw lastError ?? Exception('Max retries exceeded for $operationName');
  }

  @override
  Future<bool> isConnected() async {
    try {
      final connectedRef = _database.ref('.info/connected');
      final event = await connectedRef.once().timeout(const Duration(seconds: 5));
      final connected = event.snapshot.value as bool? ?? false;
      return connected;
    } catch (e) {
      AppLogger.debug('RealtimeDatabase', 'Connection check failed: $e');
      return false;
    }
  }

  @override
  Future<Result<UserProfile>> createProfile(UserProfile profile) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Creating profile: ${profile.userId}');
      
      if (profile.city.isEmpty) {
        return Result.failure(exceptions.UserException('City is required'));
      }

      final profileData = profile.toJson();
      profileData['lastActiveAt'] = DateTime.now().toIso8601String();
      profileData['createdAt'] = DateTime.now().toIso8601String();

      await _retryOperation(
        () => _database.ref('users/${profile.userId}').set(profileData),
        'createProfile(${profile.userId})',
      );

      AppLogger.success('RealtimeDatabase', 'Profile created: ${profile.userId}');
      return Result.success(profile);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Create profile failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<UserProfile>> getProfile(String userId) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Getting profile: $userId');
      
      final event = await _retryOperation(
        () => _database.ref('users/$userId').once(),
        'getProfile($userId)',
      );

      if (event.snapshot.value == null) {
        return Result.failure(exceptions.UserException('Profile not found'));
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final profile = UserProfile.fromJson(data);
      AppLogger.success('RealtimeDatabase', 'Profile retrieved: $userId');
      return Result.success(profile);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Get profile failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Updating profile: $userId');
      
      data['lastActiveAt'] = DateTime.now().toIso8601String();

      await _retryOperation(
        () => _database.ref('users/$userId').update(data),
        'updateProfile($userId)',
      );

      AppLogger.success('RealtimeDatabase', 'Profile updated: $userId');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Update profile failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> deleteProfile(String userId) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Deleting profile: $userId');
      
      await _retryOperation(
        () => _database.ref('users/$userId').remove(),
        'deleteProfile($userId)',
      );

      AppLogger.success('RealtimeDatabase', 'Profile deleted: $userId');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Delete profile failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<UserProfile>>> getSwipeFeed(
    String userId, {
    int limit = 10,
    int offset = 0,
    String? city,
    double minScore = 65,
  }) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Getting swipe feed for: $userId');
      
      // Get current user
      final userEvent = await _retryOperation(
        () => _database.ref('users/$userId').once(),
        'getSwipeFeed - get user',
      );

      if (userEvent.snapshot.value == null) {
        return Result.failure(exceptions.UserException('User not found'));
      }

      final userData = Map<String, dynamic>.from(userEvent.snapshot.value as Map);
      final currentUser = UserProfile.fromJson(userData);
      final searchCity = city ?? currentUser.city;

      if (searchCity.isEmpty) {
        return Result.failure(exceptions.UserException('City is required for swipe feed'));
      }

      // Get all users in the city
      final usersEvent = await _retryOperation(
        () => _database.ref('users').once(),
        'getSwipeFeed - get all users',
      );

      if (usersEvent.snapshot.value == null) {
        return Result.success([]);
      }

      final usersData = Map<String, dynamic>.from(usersEvent.snapshot.value as Map);
      
      // Get matched users
      final matchedEvent = await _retryOperation(
        () => _database.ref('matches').once(),
        'getSwipeFeed - get matches',
      );
      
      final matchedUserIds = <String>{};
      if (matchedEvent.snapshot.value != null) {
        final matchesData = Map<String, dynamic>.from(matchedEvent.snapshot.value as Map);
        matchesData.forEach((key, value) {
          final match = Map<String, dynamic>.from(value as Map);
          if (match['user1Id'] == userId) {
            matchedUserIds.add(match['user2Id'] as String);
          }
        });
      }

      // Filter profiles
      final profiles = <UserProfile>[];
      usersData.forEach((key, value) {
        if (profiles.length >= limit) return;
        
        try {
          final profileData = Map<String, dynamic>.from(value as Map);
          
          // Skip if missing required fields
          if (!profileData.containsKey('userId') || !profileData.containsKey('city')) {
            AppLogger.debug('RealtimeDatabase', 'Skipping incomplete profile: $key');
            return;
          }
          
          // Validate userId format
          final userIdStr = profileData['userId'] as String?;
          if (userIdStr == null || userIdStr.isEmpty || userIdStr == 'unknown') {
            AppLogger.debug('RealtimeDatabase', 'Skipping profile with invalid userId: $key');
            return;
          }
          
          final profile = UserProfile.fromJson(profileData);
          
          if (profile.userId == userId || matchedUserIds.contains(profile.userId)) {
            return;
          }
          
          if (profile.city != searchCity || !profile.isActive) {
            return;
          }
          
          if (profile.budgetMin <= currentUser.budgetMax && 
              profile.budgetMax >= currentUser.budgetMin) {
            profiles.add(profile);
          }
        } catch (e) {
          AppLogger.debug('RealtimeDatabase', 'Failed to parse swipe feed profile $key: $e');
          // Continue with next profile instead of failing
        }
      });

      AppLogger.success('RealtimeDatabase', 'Swipe feed retrieved: ${profiles.length} profiles');
      return Result.success(profiles.take(limit).toList());
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Get swipe feed failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<UserProfile>>> getIntelligentSwipeFeed(
    String userId, {
    int limit = 20,
  }) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Getting intelligent swipe feed for: $userId');
      
      final userEvent = await _retryOperation(
        () => _database.ref('users/$userId').once(),
        'getIntelligentSwipeFeed - get user',
      );

      if (userEvent.snapshot.value == null) {
        return Result.failure(exceptions.UserException('User not found'));
      }

      final userData = Map<String, dynamic>.from(userEvent.snapshot.value as Map);
      final currentUser = UserProfile.fromJson(userData);

      // Get all active users
      final usersEvent = await _retryOperation(
        () => _database.ref('users').once(),
        'getIntelligentSwipeFeed - get users',
      );

      if (usersEvent.snapshot.value == null) {
        return Result.success([]);
      }

      final usersData = Map<String, dynamic>.from(usersEvent.snapshot.value as Map);
      
      // Get matches
      final matchedEvent = await _retryOperation(
        () => _database.ref('matches').once(),
        'getIntelligentSwipeFeed - get matches',
      );
      
      final matchedUserIds = <String>{};
      if (matchedEvent.snapshot.value != null) {
        final matchesData = Map<String, dynamic>.from(matchedEvent.snapshot.value as Map);
        matchesData.forEach((key, value) {
          final match = Map<String, dynamic>.from(value as Map);
          if (match['user1Id'] == userId) {
            matchedUserIds.add(match['user2Id'] as String);
          }
        });
      }

      final profiles = <UserProfile>[];
      usersData.forEach((key, value) {
        if (profiles.length >= limit) return;
        
        try {
          final profileData = Map<String, dynamic>.from(value as Map);
          
          // Skip if missing required fields
          if (!profileData.containsKey('userId') || !profileData.containsKey('city')) {
            AppLogger.debug('RealtimeDatabase', 'Skipping incomplete profile: $key');
            return;
          }
          
          // Validate userId format
          final userIdStr = profileData['userId'] as String?;
          if (userIdStr == null || userIdStr.isEmpty || userIdStr == 'unknown') {
            AppLogger.debug('RealtimeDatabase', 'Skipping profile with invalid userId: $key');
            return;
          }
          
          final profile = UserProfile.fromJson(profileData);
          
          if (profile.userId != userId && 
              !matchedUserIds.contains(profile.userId) &&
              profile.isActive &&
              (currentUser.city.isEmpty || profile.city == currentUser.city)) {
            profiles.add(profile);
          }
        } catch (e) {
          AppLogger.debug('RealtimeDatabase', 'Failed to parse profile $key: $e');
          // Continue with next profile instead of failing
        }
      });

      AppLogger.success('RealtimeDatabase', 'Intelligent feed retrieved: ${profiles.length} profiles');
      return Result.success(profiles);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Get intelligent feed failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  /// Get popular users sorted by popularity metrics
  /// Popularity determined by: verification status, trust score, last activity
  Future<Result<List<UserProfile>>> getPopularUsers({
    int limit = 10,
    String? excludeUserId,
  }) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Getting popular users (limit: $limit)');

      final usersEvent = await _retryOperation(
        () => _database.ref('users').once(),
        'getPopularUsers - get all users',
      );

      if (usersEvent.snapshot.value == null) {
        return Result.success([]);
      }

      final usersData = Map<String, dynamic>.from(usersEvent.snapshot.value as Map);
      final allProfiles = <UserProfile>[];

      // Parse all users
      usersData.forEach((key, value) {
        try {
          final profileData = Map<String, dynamic>.from(value as Map);
          
          // Skip if missing required fields
          if (!profileData.containsKey('userId')) {
            AppLogger.debug('RealtimeDatabase', 'Skipping incomplete profile: $key');
            return;
          }
          
          final userIdStr = profileData['userId'] as String?;
          if (userIdStr == null || userIdStr.isEmpty || userIdStr == 'unknown') {
            AppLogger.debug('RealtimeDatabase', 'Skipping profile with invalid userId: $key');
            return;
          }
          
          final profile = UserProfile.fromJson(profileData);
          
          // Only include active, non-suspended users (exclude current user if provided)
          if (profile.isActive && 
              !profile.isSuspended &&
              profile.userId != excludeUserId) {
            allProfiles.add(profile);
          }
        } catch (e) {
          AppLogger.debug('RealtimeDatabase', 'Failed to parse profile $key: $e');
          // Continue with next profile
        }
      });

      if (allProfiles.isEmpty) {
        return Result.success([]);
      }

      // Sort by popularity metrics:
      // 1. Verified users first
      // 2. Higher trust score
      // 3. Recently active
      allProfiles.sort((a, b) {
        // Verified status (verified first)
        final aVerified = a.verified ? 1 : 0;
        final bVerified = b.verified ? 1 : 0;
        if (aVerified != bVerified) {
          return bVerified.compareTo(aVerified);
        }
        
        // Trust score (higher first)
        if (a.trustScore != b.trustScore) {
          return b.trustScore.compareTo(a.trustScore);
        }
        
        // Recently active (newer first)
        return b.lastActiveAt.compareTo(a.lastActiveAt);
      });

      // Return top users up to limit
      final popularUsers = allProfiles.take(limit).toList();
      AppLogger.success('RealtimeDatabase', 'Popular users retrieved: ${popularUsers.length}');
      return Result.success(popularUsers);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Get popular users failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Match>>> getActiveMatches(String userId, {int limit = 20}) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Getting active matches for: $userId');

      final event = await _retryOperation(
        () => _database.ref('matches').once(),
        'getActiveMatches',
      );

      if (event.snapshot.value == null) {
        return Result.success([]);
      }

      final matchesData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final matches = <Match>[];

      matchesData.forEach((key, value) {
        if (matches.length >= limit) return;
        
        final matchData = Map<String, dynamic>.from(value as Map);
        final match = Match.fromJson(matchData);
        
        if (match.user1Id == userId && match.status == 'accepted') {
          matches.add(match);
        }
      });

      AppLogger.success('RealtimeDatabase', 'Active matches retrieved: ${matches.length}');
      return Result.success(matches);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Get active matches failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Match>>> getMatchHistory(String userId) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Getting match history for: $userId');

      final event = await _retryOperation(
        () => _database.ref('matches').once(),
        'getMatchHistory',
      );

      if (event.snapshot.value == null) {
        return Result.success([]);
      }

      final matchesData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final matches = <Match>[];

      matchesData.forEach((key, value) {
        final matchData = Map<String, dynamic>.from(value as Map);
        final match = Match.fromJson(matchData);
        
        if (match.user1Id == userId) {
          matches.add(match);
        }
      });

      AppLogger.success('RealtimeDatabase', 'Match history retrieved: ${matches.length}');
      return Result.success(matches);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Get match history failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Match?>> getMatch(String matchId) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Getting match: $matchId');

      final event = await _retryOperation(
        () => _database.ref('matches/$matchId').once(),
        'getMatch',
      );

      if (event.snapshot.value == null) {
        return Result.success(null);
      }

      final matchData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final match = Match.fromJson(matchData);
      AppLogger.success('RealtimeDatabase', 'Match retrieved: $matchId');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Get match failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Match>> createMatch(String user1Id, String user2Id) async {
    try {
      // Validate user IDs
      if (user1Id.isEmpty || user1Id == 'unknown') {
        throw exceptions.UserException('Invalid user1Id: must be a valid user ID');
      }
      if (user2Id.isEmpty || user2Id == 'unknown') {
        throw exceptions.UserException('Invalid user2Id: must be a valid user ID');
      }
      
      AppLogger.info('RealtimeDatabase', 'Creating match: $user1Id <-> $user2Id');

      final matchKey = _database.ref('matches').push().key ?? DateTime.now().millisecondsSinceEpoch.toString();
      final match = Match(
        matchId: matchKey,
        user1Id: user1Id,
        user2Id: user2Id,
        compatibilityScore: 0,
        status: 'pending',
        createdAt: DateTime.now(),
        cleanlinessScore: 0,
        sleepScheduleScore: 0,
        socialFrequencyScore: 0,
        noiseToleranceScore: 0,
        financialReliabilityScore: 0,
      );

      await _retryOperation(
        () => _database.ref('matches/$matchKey').set(match.toJson()),
        'createMatch($user1Id, $user2Id)',
      );

      AppLogger.success('RealtimeDatabase', 'Match created: ${match.matchId}');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Create match failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Match>> acceptMatch(String matchId) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Accepting match: $matchId');

      await _retryOperation(
        () => _database.ref('matches/$matchId').update({
          'status': 'accepted',
          'acceptedAt': DateTime.now().toIso8601String(),
        }),
        'acceptMatch($matchId)',
      );

      final event = await _retryOperation(
        () => _database.ref('matches/$matchId').once(),
        'acceptMatch - get updated',
      );

      final matchData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final match = Match.fromJson(matchData);
      AppLogger.success('RealtimeDatabase', 'Match accepted: $matchId');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Accept match failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Match>> rejectMatch(String matchId) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Rejecting match: $matchId');

      await _retryOperation(
        () => _database.ref('matches/$matchId').update({
          'status': 'rejected',
          'rejectedAt': DateTime.now().toIso8601String(),
        }),
        'rejectMatch($matchId)',
      );

      final event = await _retryOperation(
        () => _database.ref('matches/$matchId').once(),
        'rejectMatch - get updated',
      );

      final matchData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final match = Match.fromJson(matchData);
      AppLogger.success('RealtimeDatabase', 'Match rejected: $matchId');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Reject match failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Match>> archiveMatch(String matchId) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Archiving match: $matchId');

      await _retryOperation(
        () => _database.ref('matches/$matchId').update({
          'status': 'archived',
          'archivedAt': DateTime.now().toIso8601String(),
        }),
        'archiveMatch($matchId)',
      );

      final event = await _retryOperation(
        () => _database.ref('matches/$matchId').once(),
        'archiveMatch - get updated',
      );

      final matchData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final match = Match.fromJson(matchData);
      AppLogger.success('RealtimeDatabase', 'Match archived: $matchId');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Archive match failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  /// Generic create operation for any path
  Future<Result<Map<String, dynamic>>> createPath(String path, Map<String, dynamic> data) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Creating at path: $path');
      
      final finalData = {...data};
      finalData['createdAt'] = DateTime.now().toIso8601String();
      
      await _retryOperation(
        () => _database.ref(path).set(finalData),
        'createPath($path)',
      );

      AppLogger.success('RealtimeDatabase', 'Data created at: $path');
      return Result.success(finalData);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Create at $path failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  /// Generic read operation for any path
  Future<Result<Map<String, dynamic>>> readPath(String path) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Reading from path: $path');
      
      final event = await _retryOperation(
        () => _database.ref(path).once(),
        'readPath($path)',
      );

      if (event.snapshot.value == null) {
        return Result.success({});
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      AppLogger.success('RealtimeDatabase', 'Data read from: $path');
      return Result.success(data);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Read from $path failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  /// Generic update operation for any path
  Future<Result<void>> updatePath(String path, Map<String, dynamic> data) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Updating path: $path');
      
      final finalData = {...data};
      finalData['updatedAt'] = DateTime.now().toIso8601String();
      
      await _retryOperation(
        () => _database.ref(path).update(finalData),
        'updatePath($path)',
      );

      AppLogger.success('RealtimeDatabase', 'Data updated at: $path');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Update at $path failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  /// Generic delete operation for any path
  Future<Result<void>> deletePath(String path) async {
    try {
      AppLogger.info('RealtimeDatabase', 'Deleting path: $path');
      
      await _retryOperation(
        () => _database.ref(path).remove(),
        'deletePath($path)',
      );

      AppLogger.success('RealtimeDatabase', 'Data deleted at: $path');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('RealtimeDatabase', 'Delete at $path failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }
}
