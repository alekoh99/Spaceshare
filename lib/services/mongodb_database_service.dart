import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../utils/result.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart' as exceptions;
import 'database_service.dart';

/// MongoDB implementation of database service
/// Uses HTTP API to communicate with MongoDB backend
/// Acts as fallback when Firestore/PostgreSQL are unavailable
class MongoDBDatabaseService extends GetxService implements IDatabaseService {
  static const String _baseUrl = 'http://localhost:8080/api';
  
  final http.Client _httpClient = http.Client();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  String get databaseType => 'MongoDB';

  /// Get auth headers with Firebase ID token
  Future<Map<String, String>> _getAuthHeaders({String? userId}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final idToken = await currentUser.getIdToken();
        headers['Authorization'] = 'Bearer $idToken';
        headers['x-user-id'] = currentUser.uid;
      } else if (userId != null) {
        headers['x-user-id'] = userId;
      }
    } catch (e) {
      AppLogger.debug('MongoDBDatabase', 'Error getting auth headers: $e');
      if (userId != null) {
        headers['x-user-id'] = userId;
      }
    }
    
    return headers;
  }

  /// Helper method to parse API responses that may be wrapped by response formatter
  /// Handles both wrapped format: {success: true, data: [...], ...}
  /// and direct list/object format: [...] or {...}
  dynamic _parseResponse(String responseBody, {bool expectList = true}) {
    final decodedBody = jsonDecode(responseBody);
    
    // Check if response is wrapped by response formatter
    if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('data')) {
      return decodedBody['data'];
    }
    
    // Return as-is for unwrapped responses
    return decodedBody;
  }

  @override
  Future<bool> isConnected() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.debug('MongoDBDatabase', 'Connection check failed: $e');
      return false;
    }
  }

  @override
  Future<Result<UserProfile>> createProfile(UserProfile profile) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Creating profile: ${profile.userId}');
      
      if (profile.city.isEmpty) {
        return Result.failure(exceptions.UserException('City is required'));
      }

      final headers = await _getAuthHeaders(userId: profile.userId);
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/profiles'),
        headers: headers,
        body: jsonEncode(profile.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw exceptions.UserException('MongoDB write timeout'),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode} - ${response.body}');
      }

      AppLogger.success('MongoDBDatabase', 'Profile created: ${profile.userId}');
      return Result.success(profile);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Create profile failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<UserProfile>> getProfile(String userId) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Getting profile: $userId');
      
      final headers = await _getAuthHeaders(userId: userId);
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/profiles/$userId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        return Result.failure(exceptions.UserException('Profile not found'));
      }

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      final profile = UserProfile.fromJson(jsonDecode(response.body));
      AppLogger.success('MongoDBDatabase', 'Profile retrieved: $userId');
      return Result.success(profile);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Get profile failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Updating profile: $userId');
      
      data['lastActiveAt'] = DateTime.now().toIso8601String();

      final headers = await _getAuthHeaders(userId: userId);
      final response = await _httpClient.patch(
        Uri.parse('$_baseUrl/profiles/$userId'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw exceptions.UserException('MongoDB write timeout'),
      );

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      AppLogger.success('MongoDBDatabase', 'Profile updated: $userId');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Update profile failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> deleteProfile(String userId) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Deleting profile: $userId');
      
      final headers = await _getAuthHeaders(userId: userId);
      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl/profiles/$userId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      AppLogger.success('MongoDBDatabase', 'Profile deleted: $userId');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Delete profile failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
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
      AppLogger.info('MongoDBDatabase', 'Getting swipe feed for: $userId');
      
      final headers = await _getAuthHeaders(userId: userId);
      var url = '$_baseUrl/profiles/$userId/feed?limit=$limit&offset=$offset&minScore=$minScore';
      if (city != null) {
        url += '&city=$city';
      }
      
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        return Result.failure(exceptions.UserException('Profile not found'));
      }

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      // Handle response formatter wrapper
      final decodedData = _parseResponse(response.body);
      if (decodedData is! List) {
        throw exceptions.UserException('Expected list response for swipe feed');
      }
      
      final List<dynamic> data = decodedData as List<dynamic>;
      final profiles = data.map((item) => UserProfile.fromJson(item as Map<String, dynamic>)).toList();
      
      AppLogger.success('MongoDBDatabase', 'Got ${profiles.length} profiles');
      return Result.success(profiles);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Get swipe feed failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<UserProfile>>> getIntelligentSwipeFeed(
    String userId, {
    int limit = 20,
  }) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Getting intelligent swipe feed for: $userId');
      
      final headers = await _getAuthHeaders(userId: userId);
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/profiles/$userId/intelligent-feed?limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      // Handle response formatter wrapper
      final decodedData = _parseResponse(response.body);
      if (decodedData is! List) {
        throw exceptions.UserException('Expected list response for intelligent feed');
      }
      
      final List<dynamic> data = decodedData as List<dynamic>;
      final profiles = data.map((item) => UserProfile.fromJson(item as Map<String, dynamic>)).toList();
      
      AppLogger.success('MongoDBDatabase', 'Got ${profiles.length} intelligent feed profiles');
      return Result.success(profiles);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Get intelligent swipe feed failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  /// Get popular users sorted by popularity metrics
  Future<Result<List<UserProfile>>> getPopularUsers({
    int limit = 10,
    String? excludeUserId,
  }) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Getting popular users (limit: $limit)');
      
      final headers = await _getAuthHeaders();
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/profiles?limit=100&sort=popular'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      // Handle response formatter wrapper
      final decodedData = _parseResponse(response.body);
      
      // The response might be a list directly or a map with 'profiles' key
      List<dynamic> profilesList = [];
      if (decodedData is List) {
        profilesList = decodedData;
      } else if (decodedData is Map<String, dynamic> && decodedData.containsKey('profiles')) {
        profilesList = decodedData['profiles'] ?? [];
      }
      
      var profiles = profilesList
          .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
          .where((p) => p.isActive && !p.isSuspended && p.userId != excludeUserId)
          .toList();
      
      // Sort by popularity metrics
      profiles.sort((a, b) {
        // Verified first
        final aVerified = a.verified ? 1 : 0;
        final bVerified = b.verified ? 1 : 0;
        if (aVerified != bVerified) {
          return bVerified.compareTo(aVerified);
        }
        
        // Higher trust score
        if (a.trustScore != b.trustScore) {
          return b.trustScore.compareTo(a.trustScore);
        }
        
        // Recently active
        return b.lastActiveAt.compareTo(a.lastActiveAt);
      });
      
      final popularUsers = profiles.take(limit).toList();
      AppLogger.success('MongoDBDatabase', 'Got ${popularUsers.length} popular users');
      return Result.success(popularUsers);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Get popular users failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<UserProfile>>> getNearbyProfiles(
    String userId, {
    double radiusInMiles = 10,
    int limit = 50,
  }) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Getting nearby profiles');
      
      final headers = await _getAuthHeaders(userId: userId);
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/profiles?limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      // Handle response formatter wrapper
      final decodedData = _parseResponse(response.body);
      
      // The response might be a list directly or a map with 'profiles' key
      List<dynamic> profilesList = [];
      if (decodedData is List) {
        profilesList = decodedData;
      } else if (decodedData is Map<String, dynamic> && decodedData.containsKey('profiles')) {
        profilesList = decodedData['profiles'] ?? [];
      }
      
      final profiles = profilesList.map((item) => UserProfile.fromJson(item as Map<String, dynamic>)).toList();
      
      AppLogger.success('MongoDBDatabase', 'Got ${profiles.length} nearby profiles');
      return Result.success(profiles);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Get nearby profiles failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<UserProfile>> recordSwipe(
    String userId,
    String targetUserId,
    bool isLike,
  ) async {
    AppLogger.info('MongoDBDatabase', 'Recording swipe (not implemented)');
    return Result.success(UserProfile.empty());
  }

  @override
  Future<Result<bool>> checkMatch(String userId, String targetUserId) async {
    AppLogger.info('MongoDBDatabase', 'Checking match (not implemented)');
    return Result.success(false);
  }

  @override
  Future<Result<List<Match>>> getActiveMatches(String userId, {int limit = 20}) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Getting active matches for: $userId');
      
      final headers = await _getAuthHeaders(userId: userId);
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/matches/active?limit=$limit'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      // Handle response formatter wrapper
      final decodedData = _parseResponse(response.body);
      if (decodedData is! List) {
        throw exceptions.UserException('Expected list response for active matches');
      }
      
      final List<dynamic> data = decodedData as List<dynamic>;
      final matches = data.map((item) => Match.fromJson(item as Map<String, dynamic>)).toList();
      
      AppLogger.success('MongoDBDatabase', 'Got ${matches.length} active matches');
      return Result.success(matches);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Get active matches failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<Match>>> getMatchHistory(String userId) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Getting match history for: $userId');
      
      final headers = await _getAuthHeaders(userId: userId);
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/matches/history'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      // Handle response formatter wrapper
      final decodedData = _parseResponse(response.body);
      if (decodedData is! List) {
        throw exceptions.UserException('Expected list response for match history');
      }
      
      final List<dynamic> data = decodedData as List<dynamic>;
      final matches = data.map((item) => Match.fromJson(item as Map<String, dynamic>)).toList();
      
      AppLogger.success('MongoDBDatabase', 'Got ${matches.length} historical matches');
      return Result.success(matches);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Get match history failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Match?>> getMatch(String matchId) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Getting match: $matchId');
      
      final headers = await _getAuthHeaders();
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/matches/$matchId'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        return Result.success(null);
      }

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      final match = Match.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      AppLogger.success('MongoDBDatabase', 'Got match: $matchId');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Get match failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
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
      
      AppLogger.info('MongoDBDatabase', 'Creating match between $user1Id and $user2Id');
      
      final headers = await _getAuthHeaders(userId: user1Id);
      final payload = {
        'user1Id': user1Id,
        'user2Id': user2Id,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/matches'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      final match = Match.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      AppLogger.success('MongoDBDatabase', 'Match created');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Create match failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Match>> acceptMatch(String matchId) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Accepting match: $matchId');
      
      final headers = await _getAuthHeaders();
      final response = await _httpClient.patch(
        Uri.parse('$_baseUrl/matches/$matchId/accept'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      final match = Match.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      AppLogger.success('MongoDBDatabase', 'Match accepted');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Accept match failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Match>> rejectMatch(String matchId) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Rejecting match: $matchId');
      
      final headers = await _getAuthHeaders();
      final response = await _httpClient.patch(
        Uri.parse('$_baseUrl/matches/$matchId/reject'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      final match = Match.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      AppLogger.success('MongoDBDatabase', 'Match rejected');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Reject match failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Match>> archiveMatch(String matchId) async {
    try {
      AppLogger.info('MongoDBDatabase', 'Archiving match: $matchId');
      
      final headers = await _getAuthHeaders();
      final response = await _httpClient.patch(
        Uri.parse('$_baseUrl/matches/$matchId/archive'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw exceptions.UserException('MongoDB error: ${response.statusCode}');
      }

      final match = Match.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      AppLogger.success('MongoDBDatabase', 'Match archived');
      return Result.success(match);
    } catch (e) {
      AppLogger.error('MongoDBDatabase', 'Archive match failed', e);
      return Result.failure(exceptions.UserException('MongoDB: ${e.toString()}'));
    }
  }}