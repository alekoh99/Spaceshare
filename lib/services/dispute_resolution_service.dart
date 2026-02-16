import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IDisputeResolutionService {
  Future<Result<String>> createDispute(String paymentId, String initiatorId, String reason);
  Future<Result<Map<String, dynamic>>> getDispute(String disputeId);
  Future<Result<void>> submitEvidence(String disputeId, String userId, String evidence);
  Future<Result<void>> resolveDispute(String disputeId, String resolution, String resolvedBy);
}

class DisputeResolutionService implements IDisputeResolutionService {
  late final UnifiedDatabaseService _databaseService;

  DisputeResolutionService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize DisputeResolutionService: $e');
    }
  }

  @override
  Future<Result<String>> createDispute(String paymentId, String initiatorId, String reason) async {
    try {
      final disputeId = 'dispute_${DateTime.now().millisecondsSinceEpoch}';
      
      final disputeData = {
        'disputeId': disputeId,
        'paymentId': paymentId,
        'initiatorId': initiatorId,
        'reason': reason,
        'status': 'open',
        'createdAt': DateTime.now().toIso8601String(),
        'evidence': [],
        'resolution': null,
        'resolvedAt': null,
      };

      final result = await _databaseService.createPath(
        'disputes/$disputeId',
        disputeData,
      );

      if (result.isSuccess()) {
        return Result.success(disputeId);
      } else {
        return Result.failure(result.exception ?? Exception('Failed to create dispute'));
      }
    } catch (e) {
      return Result.failure(Exception('Failed to create dispute: $e'));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getDispute(String disputeId) async {
    try {
      final result = await _databaseService.readPath('disputes/$disputeId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        return Result.success(result.data as Map<String, dynamic>);
      }
      return Result.failure(Exception('Dispute not found'));
    } catch (e) {
      return Result.failure(Exception('Failed to get dispute: $e'));
    }
  }

  @override
  Future<Result<void>> submitEvidence(String disputeId, String userId, String evidence) async {
    try {
      final evidenceRecord = {
        'userId': userId,
        'evidence': evidence,
        'submittedAt': DateTime.now().toIso8601String(),
      };

      final result = await _databaseService.updatePath(
        'disputes/$disputeId/evidence',
        {userId: evidenceRecord},
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to submit evidence: $e'));
    }
  }

  @override
  Future<Result<void>> resolveDispute(String disputeId, String resolution, String resolvedBy) async {
    try {
      final result = await _databaseService.updatePath(
        'disputes/$disputeId',
        {
          'status': 'resolved',
          'resolution': resolution,
          'resolvedBy': resolvedBy,
          'resolvedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to resolve dispute: $e'));
    }
  }
}
