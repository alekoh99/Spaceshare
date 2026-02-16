import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IResponseTimeTrackingService {
  Future<Result<void>> recordMessageSent(String messageId, String senderId);
  Future<Result<void>> recordMessageRead(String messageId, String readBy);
  Future<Result<void>> recordResponseTime(String userId, Duration responseTime);
  Future<Result<Map<String, dynamic>>> getResponseTimeStats(String userId);
}

class ResponseTimeTrackingService implements IResponseTimeTrackingService {
  late final UnifiedDatabaseService _databaseService;

  ResponseTimeTrackingService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize ResponseTimeTrackingService: $e');
    }
  }

  @override
  Future<Result<void>> recordMessageSent(String messageId, String senderId) async {
    try {
      final result = await _databaseService.createPath(
        'messageSentTimes/$messageId',
        {
          'messageId': messageId,
          'senderId': senderId,
          'sentAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to record message sent: $e'));
    }
  }

  @override
  Future<Result<void>> recordMessageRead(String messageId, String readBy) async {
    try {
      final result = await _databaseService.updatePath(
        'messageSentTimes/$messageId',
        {
          'readBy': readBy,
          'readAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to record message read: $e'));
    }
  }

  @override
  Future<Result<void>> recordResponseTime(String userId, Duration responseTime) async {
    try {
      final recordId = 'response_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await _databaseService.createPath(
        'userResponseTimes/$userId/$recordId',
        {
          'recordId': recordId,
          'duration': responseTime.inSeconds,
          'recordedAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to record response time: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getResponseTimeStats(String userId) async {
    try {
      final result = await _databaseService.readPath('userResponseTimes/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final records = data.values
            .whereType<Map<String, dynamic>>()
            .toList();

        if (records.isEmpty) {
          return Result.success({
            'averageResponseTime': 0,
            'fastestResponse': 0,
            'slowestResponse': 0,
            'totalResponses': 0,
          });
        }

        final durations = records
            .map((r) => (r['duration'] as num?)?.toInt() ?? 0)
            .toList();

        return Result.success({
          'averageResponseTime': durations.reduce((a, b) => a + b) ~/ durations.length,
          'fastestResponse': durations.reduce((a, b) => a < b ? a : b),
          'slowestResponse': durations.reduce((a, b) => a > b ? a : b),
          'totalResponses': durations.length,
        });
      }

      return Result.success({
        'averageResponseTime': 0,
        'fastestResponse': 0,
        'slowestResponse': 0,
        'totalResponses': 0,
      });
    } catch (e) {
      return Result.failure(Exception('Failed to get response time stats: $e'));
    }
  }
}
