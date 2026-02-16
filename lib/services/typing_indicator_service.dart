import 'package:get/get.dart';
import 'dart:async';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class ITypingIndicatorService {
  Future<Result<void>> startTyping(String conversationId, String userId);
  Future<Result<void>> stopTyping(String conversationId, String userId);
  Future<Result<List<String>>> getTypingUsers(String conversationId);
}

class TypingIndicatorService implements ITypingIndicatorService {
  late final UnifiedDatabaseService _databaseService;
  final Map<String, Timer> _typingTimers = {};

  TypingIndicatorService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize TypingIndicatorService: $e');
    }
  }

  @override
  Future<Result<void>> startTyping(String conversationId, String userId) async {
    try {
      final key = '$conversationId:$userId';
      
      // Cancel existing timer
      _typingTimers[key]?.cancel();

      // Record typing status
      await _databaseService.createPath(
        'typingIndicators/$conversationId/$userId',
        {
          'userId': userId,
          'startedAt': DateTime.now().toIso8601String(),
        },
      );

      // Auto-remove after 3 seconds of inactivity
      _typingTimers[key] = Timer(Duration(seconds: 3), () {
        stopTyping(conversationId, userId);
      });

      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Failed to start typing indicator: $e'));
    }
  }

  @override
  Future<Result<void>> stopTyping(String conversationId, String userId) async {
    try {
      final key = '$conversationId:$userId';
      _typingTimers[key]?.cancel();
      _typingTimers.remove(key);

      final result = await _databaseService.deletePath(
        'typingIndicators/$conversationId/$userId',
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to stop typing indicator: $e'));
    }
  }

  @override
  Future<Result<List<String>>> getTypingUsers(String conversationId) async {
    try {
      final result = await _databaseService.readPath('typingIndicators/$conversationId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final typingUsers = data.keys.toList();
        return Result.success(typingUsers);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get typing users: $e'));
    }
  }

  void dispose() {
    for (var timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
  }
}
