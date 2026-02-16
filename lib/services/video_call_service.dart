import 'package:get/get.dart';
import 'dart:async';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IVideoCallService {
  Future<Result<String>> initiateCall(String userId, String recipientId);
  Future<Result<void>> acceptCall(String callId);
  Future<Result<void>> rejectCall(String callId, String reason);
  Future<Result<void>> endCall(String callId);
  Future<Result<Map<String, dynamic>>> getCallDetails(String callId);
}

class VideoCallService implements IVideoCallService {
  late final UnifiedDatabaseService _databaseService;

  VideoCallService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize VideoCallService: $e');
    }
  }

  @override
  Future<Result<String>> initiateCall(String userId, String recipientId) async {
    try {
      final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
      
      final callData = {
        'callId': callId,
        'initiator': userId,
        'recipient': recipientId,
        'status': 'ringing',
        'initiatedAt': DateTime.now().toIso8601String(),
        'startedAt': null,
        'endedAt': null,
        'duration': 0,
      };

      final result = await _databaseService.createPath(
        'videoCalls/$callId',
        callData,
      );

      if (result.isSuccess()) {
        return Result.success(callId);
      } else {
        return Result.failure(result.exception ?? Exception('Failed to initiate call'));
      }
    } catch (e) {
      return Result.failure(Exception('Failed to initiate call: $e'));
    }
  }

  @override
  Future<Result<void>> acceptCall(String callId) async {
    try {
      final result = await _databaseService.updatePath(
        'videoCalls/$callId',
        {
          'status': 'active',
          'startedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to accept call: $e'));
    }
  }

  @override
  Future<Result<void>> rejectCall(String callId, String reason) async {
    try {
      final result = await _databaseService.updatePath(
        'videoCalls/$callId',
        {
          'status': 'rejected',
          'rejectionReason': reason,
          'endedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to reject call: $e'));
    }
  }

  @override
  Future<Result<void>> endCall(String callId) async {
    try {
      final callResult = await getCallDetails(callId);

      if (callResult.isSuccess()) {
        final call = callResult.data!;
        final startedAt = call['startedAt'];
        
        Duration duration = Duration.zero;
        if (startedAt != null) {
          final start = DateTime.tryParse(startedAt.toString());
          if (start != null) {
            duration = DateTime.now().difference(start);
          }
        }

        final result = await _databaseService.updatePath(
          'videoCalls/$callId',
          {
            'status': 'ended',
            'endedAt': DateTime.now().toIso8601String(),
            'duration': duration.inSeconds,
          },
        );

        return result;
      }

      return Result.failure(callResult.exception ?? Exception('Failed to get call'));
    } catch (e) {
      return Result.failure(Exception('Failed to end call: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getCallDetails(String callId) async {
    try {
      final result = await _databaseService.readPath('videoCalls/$callId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        return Result.success(result.data as Map<String, dynamic>);
      }

      return Result.failure(Exception('Call not found'));
    } catch (e) {
      return Result.failure(Exception('Failed to get call details: $e'));
    }
  }
}
