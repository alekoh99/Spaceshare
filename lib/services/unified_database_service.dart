import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../utils/result.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;
import 'database_service.dart';
import 'firebase_realtime_database_service.dart';
import 'mongodb_database_service.dart';

/// Unified database service with dual-redundancy strategy
/// - Writes to Firebase Realtime Database (primary), then MongoDB (asynchronous)
/// - If one database fails, others still succeed (highly resilient)
/// - Reads from fastest available database (RTDB preferred for speed)
/// - Auto-syncs data between databases for consistency
class UnifiedDatabaseService extends GetxService implements IDatabaseService {
  late final FirebaseRealtimeDatabaseService _rtdbService;
  late final MongoDBDatabaseService _mongoDb;
  
  final RxString primaryDatabase = 'Firebase RTDB'.obs;
  final RxBool isRealtimeDatabaseAvailable = true.obs;
  final RxBool isMongoAvailable = false.obs;

  static UnifiedDatabaseService get to => Get.find();

  @override
  void onInit() {
    super.onInit();
    try {
      _rtdbService = Get.find<FirebaseRealtimeDatabaseService>();
      AppLogger.debug('UnifiedDatabase', 'Found existing Firebase RTDB service');
    } catch (e) {
      AppLogger.warning('UnifiedDatabase', 'Firebase RTDB service not found, creating new: $e');
      _rtdbService = FirebaseRealtimeDatabaseService();
    }
    try {
      _mongoDb = Get.find<MongoDBDatabaseService>();
      AppLogger.debug('UnifiedDatabase', 'Found existing MongoDB service');
    } catch (e) {
      AppLogger.warning('UnifiedDatabase', 'MongoDB service not found, creating new: $e');
      _mongoDb = MongoDBDatabaseService();
    }
    _initializeDatabases();
  }

  void _initializeDatabases() async {
    // Check Firebase Realtime Database availability
    try {
      final isConnected = await _rtdbService.isConnected();
      isRealtimeDatabaseAvailable.value = isConnected;
      AppLogger.info('UnifiedDatabase', 'Firebase RTDB: ${isConnected ? 'Available' : 'Unavailable'}');
    } catch (e) {
      isRealtimeDatabaseAvailable.value = false;
      AppLogger.warning('UnifiedDatabase', 'Firebase RTDB check failed: $e');
    }

    // Check MongoDB availability
    try {
      final isConnected = await _mongoDb.isConnected();
      isMongoAvailable.value = isConnected;
      AppLogger.info('UnifiedDatabase', 'MongoDB: ${isConnected ? 'Available' : 'Unavailable'}');
    } catch (e) {
      isMongoAvailable.value = false;
      AppLogger.warning('UnifiedDatabase', 'MongoDB check failed: $e');
    }
  }

  @override
  String get databaseType => primaryDatabase.value;

  @override
  Future<bool> isConnected() async {
    return isRealtimeDatabaseAvailable.value || isMongoAvailable.value;
  }

  /// Dual-write to both databases in parallel
  /// Returns success if at least ONE database succeeds
  Future<void> _dualWrite(
    Future<Result<T>> Function<T>() rtdbOp,
    Future<Result<T>> Function<T>() postgresOp,
  ) async {
    final futures = <Future>[];
    
    // Try Firebase Realtime Database
    if (isRealtimeDatabaseAvailable.value) {
      futures.add(
        rtdbOp().then((result) {
          if (result.isSuccess()) {
            AppLogger.debug('UnifiedDatabase', 'Firebase RTDB write succeeded');
          } else {
            AppLogger.warning('UnifiedDatabase', 'Firebase RTDB write failed');
            isRealtimeDatabaseAvailable.value = false;
          }
        }).catchError((e) {
          AppLogger.debug('UnifiedDatabase', 'Firebase RTDB write error: $e');
          isRealtimeDatabaseAvailable.value = false;
        }),
      );
    }
    
    // Try PostgreSQL
    if (isRealtimeDatabaseAvailable.value) {
      futures.add(
        postgresOp().then((result) {
          if (result.isSuccess()) {
            AppLogger.debug('UnifiedDatabase', 'PostgreSQL write succeeded');
          } else {
            AppLogger.warning('UnifiedDatabase', 'PostgreSQL write failed');
            isRealtimeDatabaseAvailable.value = false;
          }
        }).catchError((e) {
          AppLogger.debug('UnifiedDatabase', 'PostgreSQL write error: $e');
          isRealtimeDatabaseAvailable.value = false;
        }),
      );
    }
    
    // Wait for all writes to complete (don't fail if some fail)
    if (futures.isNotEmpty) {
      await Future.wait(futures, eagerError: false);
    }
  }

  @override
  Future<Result<UserProfile>> createProfile(UserProfile profile) async {
    AppLogger.info('UnifiedDatabase', 'Creating profile: ${profile.userId}');
    
    Result<UserProfile>? primaryResult;
    
    // Primary: Write to PostgreSQL (source of truth - SYNCHRONOUS)
    if (isRealtimeDatabaseAvailable.value) {
      try {
        primaryResult = await _rtdbService.createProfile(profile);
        if (primaryResult.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          AppLogger.success('UnifiedDatabase', 'Profile created via PostgreSQL');
        } else {
          AppLogger.warning('UnifiedDatabase', 'PostgreSQL failed');
          isRealtimeDatabaseAvailable.value = false;
          primaryResult = null;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL error: $e');
        isRealtimeDatabaseAvailable.value = false;
        primaryResult = null;
      }
    }

    // Secondary: Sync to Firebase Realtime Database ASYNCHRONOUSLY (don't wait)
    if (primaryResult?.isSuccess() == true && isRealtimeDatabaseAvailable.value) {
      _rtdbService.createProfile(profile)
          .then((result) {
            if (result.isSuccess()) {
              AppLogger.success('UnifiedDatabase', 'Firebase RTDB sync completed');
            } else {
              AppLogger.warning('UnifiedDatabase', 'Firebase RTDB sync failed');
              isRealtimeDatabaseAvailable.value = false;
            }
          })
          .catchError((e) {
            AppLogger.debug('UnifiedDatabase', 'Firebase RTDB sync error: $e');
            isRealtimeDatabaseAvailable.value = false;
          });
    }

    // Tertiary: Sync to MongoDB ASYNCHRONOUSLY (don't wait)
    if (primaryResult?.isSuccess() == true && isMongoAvailable.value) {
      _mongoDb.createProfile(profile)
          .then((result) {
            if (result.isSuccess()) {
              AppLogger.success('UnifiedDatabase', 'MongoDB sync completed');
            } else {
              AppLogger.warning('UnifiedDatabase', 'MongoDB sync failed');
              isMongoAvailable.value = false;
            }
          })
          .catchError((e) {
            AppLogger.debug('UnifiedDatabase', 'MongoDB sync error: $e');
            isMongoAvailable.value = false;
          });
    }

    // Return primary result if available
    if (primaryResult != null) {
      return primaryResult;
    }

    return Result.failure(
      exceptions.UserException('All databases unavailable. Please check your connection.'),
    );
  }

  @override
  Future<Result<UserProfile>> getProfile(String userId) async {
    AppLogger.debug('UnifiedDatabase', 'Getting profile: $userId');
    
    // Try PostgreSQL first (fastest)
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getProfile(userId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          return result;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL get failed: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Try Firebase Realtime Database second
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getProfile(userId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          return result;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB get failed: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Try MongoDB last
    if (isMongoAvailable.value) {
      try {
        final result = await _mongoDb.getProfile(userId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'MongoDB';
          return result;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'MongoDB get failed: $e');
        isMongoAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Profile not found'));
  }

  /// Ensure profile exists in all databases (sync from PostgreSQL to others if needed)
  /// This is useful during login to ensure all databases are up-to-date
  Future<Result<UserProfile>> ensureProfileSync(String userId) async {
    AppLogger.info('UnifiedDatabase', 'Ensuring profile sync for: $userId');
    
    try {
      // Get from PostgreSQL first (source of truth)
      if (isRealtimeDatabaseAvailable.value) {
        final pgResult = await _rtdbService.getProfile(userId);
        if (pgResult.isSuccess()) {
          final profile = pgResult.getOrNull()!;
          
          // Sync to Firebase Realtime Database asynchronously
          if (isRealtimeDatabaseAvailable.value) {
            _rtdbService.createProfile(profile)
                .then((result) {
                  if (result.isSuccess()) {
                    AppLogger.success('UnifiedDatabase', 'Profile synced to Firebase RTDB');
                  } else {
                    AppLogger.warning('UnifiedDatabase', 'Failed to sync profile to Firebase RTDB');
                  }
                })
                .catchError((e) {
                  AppLogger.debug('UnifiedDatabase', 'Firebase RTDB sync error: $e');
                });
          }

          // Sync to MongoDB asynchronously
          if (isMongoAvailable.value) {
            _mongoDb.createProfile(profile)
                .then((result) {
                  if (result.isSuccess()) {
                    AppLogger.success('UnifiedDatabase', 'Profile synced to MongoDB');
                  } else {
                    AppLogger.warning('UnifiedDatabase', 'Failed to sync profile to MongoDB');
                  }
                })
                .catchError((e) {
                  AppLogger.debug('UnifiedDatabase', 'MongoDB sync error: $e');
                });
          }
          
          return pgResult;
        }
      }
      
      // Fall back to Firebase Realtime Database if PostgreSQL unavailable
      if (isRealtimeDatabaseAvailable.value) {
        final rtdbResult = await _rtdbService.getProfile(userId);
        if (rtdbResult.isSuccess()) {
          return rtdbResult;
        }
      }

      // Fall back to MongoDB if both PostgreSQL and Firestore unavailable
      if (isMongoAvailable.value) {
        final mongoResult = await _mongoDb.getProfile(userId);
        if (mongoResult.isSuccess()) {
          return mongoResult;
        }
      }
      
      return Result.failure(exceptions.UserException('Profile not found'));
    } catch (e) {
      AppLogger.error('UnifiedDatabase', 'ensureProfileSync failed', e);
      return Result.failure(exceptions.UserException('Profile sync failed: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> updateProfile(String userId, Map<String, dynamic> data) async {
    AppLogger.debug('UnifiedDatabase', 'Updating profile: $userId');
    
    Result<void>? primaryResult;
    
    // Primary: Update PostgreSQL FIRST (source of truth - SYNCHRONOUS)
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.updateProfile(userId, data);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          AppLogger.success('UnifiedDatabase', 'PostgreSQL update succeeded');
          primaryResult = result;
        } else {
          AppLogger.warning('UnifiedDatabase', 'PostgreSQL update failed: ${result.getExceptionOrNull()}');
          isRealtimeDatabaseAvailable.value = false;
          primaryResult = result;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL update error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // If PostgreSQL succeeded, sync to Firebase Realtime Database ASYNCHRONOUSLY (don't wait)
    if (primaryResult?.isSuccess() == true) {
      _rtdbService.updateProfile(userId, data)
          .then((result) {
            if (result.isSuccess()) {
              AppLogger.success('UnifiedDatabase', 'Firebase RTDB async sync completed');
            } else {
              AppLogger.warning('UnifiedDatabase', 'Firebase RTDB async sync failed');
              isRealtimeDatabaseAvailable.value = false;
            }
          })
          .catchError((e) {
            AppLogger.warning('UnifiedDatabase', 'Firebase RTDB async sync error: $e');
            isRealtimeDatabaseAvailable.value = false;
          });
    }

    // Return primary result if available
    if (primaryResult != null) {
      return primaryResult;
    }

    // Fallback: Try Firebase Realtime Database if PostgreSQL unavailable
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.updateProfile(userId, data);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          AppLogger.success('UnifiedDatabase', 'Firebase RTDB update succeeded (fallback)');
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB update error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Update failed: All databases unavailable'));
  }

  @override
  Future<Result<void>> deleteProfile(String userId) async {
    AppLogger.debug('UnifiedDatabase', 'Deleting profile: $userId');
    
    // Primary: Delete from PostgreSQL (wait for it)
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.deleteProfile(userId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          AppLogger.debug('UnifiedDatabase', 'PostgreSQL delete succeeded');
          
          // Secondary: Delete from Firebase Realtime Database ASYNCHRONOUSLY (don't wait)
          if (isRealtimeDatabaseAvailable.value) {
            _rtdbService.deleteProfile(userId)
                .then((result) {
                  if (result.isSuccess()) {
                    AppLogger.debug('UnifiedDatabase', 'Firebase RTDB sync succeeded (async)');
                  } else {
                    AppLogger.warning('UnifiedDatabase', 'Firebase RTDB async sync failed');
                    isRealtimeDatabaseAvailable.value = false;
                  }
                })
                .catchError((e) {
                  AppLogger.debug('UnifiedDatabase', 'Firebase RTDB async sync error: $e');
                  isRealtimeDatabaseAvailable.value = false;
                });
          }
          
          return result; // Return immediately
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL delete error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Fallback: Try Firebase Realtime Database
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.deleteProfile(userId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          AppLogger.debug('UnifiedDatabase', 'Firebase RTDB delete succeeded (fallback)');
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB delete error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Delete failed: All databases unavailable'));
  }

  @override
  Future<Result<List<UserProfile>>> getSwipeFeed(
    String userId, {
    int limit = 10,
    int offset = 0,
    String? city,
    double minScore = 65,
  }) async {
    AppLogger.debug('UnifiedDatabase', 'Getting swipe feed for: $userId');
    
    // Try Firebase Realtime Database first
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getSwipeFeed(
          userId,
          limit: limit,
          offset: offset,
          city: city,
          minScore: minScore,
        );
        if (result.isSuccess()) {
          final profiles = result.getOrNull() ?? [];
          if (profiles.isNotEmpty) {
            primaryDatabase.value = 'Firebase RTDB';
            return result;
          }
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB swipe feed error: $e');
      }
    }

    // Fall back to MongoDB (no flag check - always try)
    try {
      final mongoDb = Get.find<MongoDBDatabaseService>();
      final result = await mongoDb.getSwipeFeed(
        userId,
        limit: limit,
        offset: offset,
        city: city,
        minScore: minScore,
      );
      if (result.isSuccess()) {
        primaryDatabase.value = 'MongoDB';
        return result;
      }
    } catch (e) {
      AppLogger.debug('UnifiedDatabase', 'MongoDB swipe feed error: $e');
    }

    return Result.failure(exceptions.UserException('Failed to load swipe feed'));
  }

  @override
  Future<Result<List<UserProfile>>> getIntelligentSwipeFeed(
    String userId, {
    int limit = 20,
  }) async {
    AppLogger.debug('UnifiedDatabase', 'Getting intelligent swipe feed for: $userId');
    
    // Try Firebase Realtime Database first (primary source of truth)
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getIntelligentSwipeFeed(
          userId,
          limit: limit,
        );
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          final profiles = result.getOrNull() ?? [];
          if (profiles.isNotEmpty) {
            AppLogger.success('UnifiedDatabase', 'Firebase RTDB intelligent feed: ${profiles.length} profiles');
            return result;
          }
        }
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB returned empty/failed, trying fallback');
      } catch (e) {
        AppLogger.warning('UnifiedDatabase', 'Firebase RTDB intelligent feed error: $e');
      }
    }

    // Fall back to MongoDB (no flag check needed - always try if available)
    try {
      AppLogger.debug('UnifiedDatabase', 'Trying MongoDB fallback for intelligent feed');
      final mongoDb = Get.find<MongoDBDatabaseService>();
      final result = await mongoDb.getIntelligentSwipeFeed(
        userId,
        limit: limit,
      );
      if (result.isSuccess()) {
        primaryDatabase.value = 'MongoDB';
        final profiles = result.getOrNull() ?? [];
        AppLogger.success('UnifiedDatabase', 'MongoDB intelligent feed: ${profiles.length} profiles');
        return result;
      }
    } catch (e) {
      AppLogger.warning('UnifiedDatabase', 'MongoDB intelligent feed error: $e');
    }

    AppLogger.error('UnifiedDatabase', 'All intelligent feed sources failed for user: $userId', null);
    return Result.failure(exceptions.UserException('Failed to load intelligent feed - no databases available'));
  }

  /// Get popular users sorted by popularity metrics
  /// Popularity is determined by:
  /// - Verification status (verified first)
  /// - Trust score (0-100)
  /// - Account activity status
  Future<Result<List<UserProfile>>> getPopularUsers({
    int limit = 10,
    String? excludeUserId,
  }) async {
    AppLogger.debug('UnifiedDatabase', 'Getting popular users (limit: $limit)');
    
    try {
      List<UserProfile> allUsers = [];
      
      // Try Firebase Realtime Database first (primary source)
      if (isRealtimeDatabaseAvailable.value) {
        try {
          final result = await _rtdbService.getPopularUsers(limit: limit, excludeUserId: excludeUserId);
          if (result.isSuccess()) {
            primaryDatabase.value = 'Firebase RTDB';
            final users = result.getOrNull() ?? [];
            allUsers.addAll(users);
            AppLogger.success('UnifiedDatabase', 'Fetched ${users.length} popular users from Firebase RTDB');
            return result;
          }
        } catch (e) {
          AppLogger.warning('UnifiedDatabase', 'Firebase RTDB popular users error: $e');
          isRealtimeDatabaseAvailable.value = false;
        }
      }
      
      // Fallback to MongoDB if Firebase unavailable
      if (isMongoAvailable.value) {
        try {
          AppLogger.debug('UnifiedDatabase', 'Trying MongoDB fallback for popular users');
          final result = await _mongoDb.getPopularUsers(limit: limit, excludeUserId: excludeUserId);
          if (result.isSuccess()) {
            primaryDatabase.value = 'MongoDB';
            final users = result.getOrNull() ?? [];
            AppLogger.success('UnifiedDatabase', 'Fetched ${users.length} popular users from MongoDB');
            return result;
          }
        } catch (e) {
          AppLogger.warning('UnifiedDatabase', 'MongoDB popular users error: $e');
        }
      }
      
      AppLogger.warning('UnifiedDatabase', 'No popular users found');
      return Result.failure(exceptions.UserException('No users available'));
    } catch (e) {
      AppLogger.error('UnifiedDatabase', 'Error getting popular users', e);
      return Result.failure(exceptions.UserException('Failed to load popular users: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Match>>> getActiveMatches(String userId, {int limit = 20}) async {
    AppLogger.debug('UnifiedDatabase', 'Getting active matches for: $userId');
    
    // Try PostgreSQL first
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getActiveMatches(userId, limit: limit);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL active matches error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Fall back to Firebase Realtime Database
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getActiveMatches(userId, limit: limit);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB active matches error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Failed to load active matches'));
  }

  @override
  Future<Result<List<Match>>> getMatchHistory(String userId) async {
    AppLogger.debug('UnifiedDatabase', 'Getting match history for: $userId');
    
    // Try PostgreSQL first
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getMatchHistory(userId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL match history error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Fall back to Firebase Realtime Database
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getMatchHistory(userId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB match history error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Failed to load match history'));
  }

  @override
  Future<Result<Match?>> getMatch(String matchId) async {
    AppLogger.debug('UnifiedDatabase', 'Getting match: $matchId');
    
    // Try PostgreSQL first
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getMatch(matchId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL get match error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Fall back to Firebase Realtime Database
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.getMatch(matchId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB get match error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Match not found'));
  }

  @override
  Future<Result<Match>> createMatch(String user1Id, String user2Id) async {
    // Validate user IDs
    if (user1Id.isEmpty || user1Id == 'unknown') {
      AppLogger.error('UnifiedDatabase', 'Creating match with invalid user1Id: $user1Id', null);
      return Result.failure(exceptions.UserException('Invalid user1Id: must be a valid user ID'));
    }
    if (user2Id.isEmpty || user2Id == 'unknown') {
      AppLogger.error('UnifiedDatabase', 'Creating match with invalid user2Id: $user2Id', null);
      return Result.failure(exceptions.UserException('Invalid user2Id: must be a valid user ID'));
    }
    
    AppLogger.info('UnifiedDatabase', 'Creating match: $user1Id <-> $user2Id');
    
    Result<Match>? primaryResult;
    
    // Primary: Create in PostgreSQL (source of truth)
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.createMatch(user1Id, user2Id);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          primaryResult = result;
          AppLogger.success('UnifiedDatabase', 'PostgreSQL match creation succeeded');
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL match creation error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Secondary: Sync to Firebase Realtime Database asynchronously
    if (primaryResult?.isSuccess() == true && isRealtimeDatabaseAvailable.value) {
      _rtdbService.createMatch(user1Id, user2Id)
          .then((result) {
            if (result.isSuccess()) {
              AppLogger.debug('UnifiedDatabase', 'Firebase RTDB match sync completed');
            } else {
              isRealtimeDatabaseAvailable.value = false;
            }
          })
          .catchError((e) {
            AppLogger.debug('UnifiedDatabase', 'Firebase RTDB match sync error: $e');
            isRealtimeDatabaseAvailable.value = false;
          });
    }

    if (primaryResult != null) {
      return primaryResult;
    }

    // Fallback: Try Firebase Realtime Database if PostgreSQL unavailable
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.createMatch(user1Id, user2Id);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB match creation error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Failed to create match'));
  }

  @override
  Future<Result<Match>> acceptMatch(String matchId) async {
    AppLogger.info('UnifiedDatabase', 'Accepting match: $matchId');
    
    Result<Match>? primaryResult;
    
    // Primary: Update in PostgreSQL
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.acceptMatch(matchId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          primaryResult = result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL accept match error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Secondary: Sync to Firebase Realtime Database asynchronously
    if (primaryResult?.isSuccess() == true && isRealtimeDatabaseAvailable.value) {
      _rtdbService.acceptMatch(matchId)
          .catchError((e) {
            AppLogger.debug('UnifiedDatabase', 'Firebase RTDB accept match sync error: $e');
            isRealtimeDatabaseAvailable.value = false;
          });
    }

    if (primaryResult != null) {
      return primaryResult;
    }

    // Fallback: Try Firebase Realtime Database if PostgreSQL unavailable
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.acceptMatch(matchId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB accept match error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Failed to accept match'));
  }

  @override
  Future<Result<Match>> rejectMatch(String matchId) async {
    AppLogger.info('UnifiedDatabase', 'Rejecting match: $matchId');
    
    Result<Match>? primaryResult;
    
    // Primary: Update in PostgreSQL
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.rejectMatch(matchId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          primaryResult = result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL reject match error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Secondary: Sync to Firestore asynchronously
    // Secondary: Sync to Firebase Realtime Database asynchronously
    if (primaryResult?.isSuccess() == true && isRealtimeDatabaseAvailable.value) {
      _rtdbService.rejectMatch(matchId)
          .catchError((e) {
            AppLogger.debug('UnifiedDatabase', 'Firebase RTDB reject match sync error: $e');
            isRealtimeDatabaseAvailable.value = false;
          });
    }

    if (primaryResult != null) {
      return primaryResult;
    }

    // Fallback: Try Firebase Realtime Database if PostgreSQL unavailable
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.rejectMatch(matchId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB reject match error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Failed to reject match'));
  }

  @override
  Future<Result<Match>> archiveMatch(String matchId) async {
    AppLogger.info('UnifiedDatabase', 'Archiving match: $matchId');
    
    Result<Match>? primaryResult;
    
    // Primary: Update in PostgreSQL
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.archiveMatch(matchId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'PostgreSQL';
          primaryResult = result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'PostgreSQL archive match error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    // Secondary: Sync to Firebase Realtime Database asynchronously
    if (primaryResult?.isSuccess() == true && isRealtimeDatabaseAvailable.value) {
      _rtdbService.archiveMatch(matchId)
          .catchError((e) {
            AppLogger.debug('UnifiedDatabase', 'Firebase RTDB archive match sync error: $e');
            isRealtimeDatabaseAvailable.value = false;
          });
    }

    if (primaryResult != null) {
      return primaryResult;
    }

    // Fallback: Try Firebase Realtime Database if PostgreSQL unavailable
    if (isRealtimeDatabaseAvailable.value) {
      try {
        final result = await _rtdbService.archiveMatch(matchId);
        if (result.isSuccess()) {
          primaryDatabase.value = 'Firebase RTDB';
          return result;
        } else {
          isRealtimeDatabaseAvailable.value = false;
        }
      } catch (e) {
        AppLogger.debug('UnifiedDatabase', 'Firebase RTDB archive match error: $e');
        isRealtimeDatabaseAvailable.value = false;
      }
    }

    return Result.failure(exceptions.UserException('Failed to archive match'));
  }

  /// Generic create operation for any path
  Future<Result<Map<String, dynamic>>> createPath(String path, Map<String, dynamic> data) async {
    try {
      AppLogger.info('UnifiedDatabase', 'Creating at path: $path');

      Result<Map<String, dynamic>>? primaryResult;

      // Primary: Write to Firebase Realtime Database
      if (isRealtimeDatabaseAvailable.value) {
        try {
          final result = await _rtdbService.createPath(path, data);
          if (result.isSuccess()) {
            primaryDatabase.value = 'Firebase RTDB';
            primaryResult = result;
          } else {
            isRealtimeDatabaseAvailable.value = false;
          }
        } catch (e) {
          AppLogger.debug('UnifiedDatabase', 'Firebase RTDB create path error: $e');
          isRealtimeDatabaseAvailable.value = false;
        }
      }

      if (primaryResult != null) {
        return primaryResult;
      }

      return Result.failure(exceptions.UserException('Failed to create at $path'));
    } catch (e) {
      AppLogger.error('UnifiedDatabase', 'Create path failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  /// Generic read operation for any path
  Future<Result<Map<String, dynamic>>> readPath(String path) async {
    try {
      AppLogger.info('UnifiedDatabase', 'Reading from path: $path');

      // Try Firebase Realtime Database
      if (isRealtimeDatabaseAvailable.value) {
        try {
          final result = await _rtdbService.readPath(path);
          if (result.isSuccess()) {
            primaryDatabase.value = 'Firebase RTDB';
            return result;
          } else {
            isRealtimeDatabaseAvailable.value = false;
          }
        } catch (e) {
          AppLogger.debug('UnifiedDatabase', 'Firebase RTDB read path error: $e');
          isRealtimeDatabaseAvailable.value = false;
        }
      }

      return Result.failure(exceptions.UserException('Failed to read from $path'));
    } catch (e) {
      AppLogger.error('UnifiedDatabase', 'Read path failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  /// Generic update operation for any path
  Future<Result<void>> updatePath(String path, Map<String, dynamic> data) async {
    try {
      AppLogger.info('UnifiedDatabase', 'Updating path: $path');

      Result<void>? primaryResult;

      // Primary: Write to Firebase Realtime Database
      if (isRealtimeDatabaseAvailable.value) {
        try {
          final result = await _rtdbService.updatePath(path, data);
          if (result.isSuccess()) {
            primaryDatabase.value = 'Firebase RTDB';
            primaryResult = result;
          } else {
            isRealtimeDatabaseAvailable.value = false;
          }
        } catch (e) {
          AppLogger.debug('UnifiedDatabase', 'Firebase RTDB update path error: $e');
          isRealtimeDatabaseAvailable.value = false;
        }
      }

      if (primaryResult != null) {
        return primaryResult;
      }

      return Result.failure(exceptions.UserException('Failed to update $path'));
    } catch (e) {
      AppLogger.error('UnifiedDatabase', 'Update path failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }

  /// Generic delete operation for any path
  Future<Result<void>> deletePath(String path) async {
    try {
      AppLogger.info('UnifiedDatabase', 'Deleting path: $path');

      Result<void>? primaryResult;

      // Primary: Delete from Firebase Realtime Database
      if (isRealtimeDatabaseAvailable.value) {
        try {
          final result = await _rtdbService.deletePath(path);
          if (result.isSuccess()) {
            primaryDatabase.value = 'Firebase RTDB';
            primaryResult = result;
          } else {
            isRealtimeDatabaseAvailable.value = false;
          }
        } catch (e) {
          AppLogger.debug('UnifiedDatabase', 'Firebase RTDB delete path error: $e');
          isRealtimeDatabaseAvailable.value = false;
        }
      }

      if (primaryResult != null) {
        return primaryResult;
      }

      return Result.failure(exceptions.UserException('Failed to delete $path'));
    } catch (e) {
      AppLogger.error('UnifiedDatabase', 'Delete path failed', e);
      return Result.failure(exceptions.UserException('Database: ${e.toString()}'));
    }
  }
}
