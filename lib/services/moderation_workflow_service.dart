import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IModerationWorkflowService {
  Future<Result<void>> submitForReview(String contentId, String contentType, String reason);
  Future<Result<void>> approveContent(String contentId, String approvedBy);
  Future<Result<void>> rejectContent(String contentId, String reason, String rejectedBy);
  Future<Result<List<Map<String, dynamic>>>> getPendingReview();
}

class ModerationWorkflowService implements IModerationWorkflowService {
  late final UnifiedDatabaseService _databaseService;

  ModerationWorkflowService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize ModerationWorkflowService: $e');
    }
  }

  @override
  Future<Result<void>> submitForReview(String contentId, String contentType, String reason) async {
    try {
      final reviewId = 'review_${DateTime.now().millisecondsSinceEpoch}';
      
      final reviewData = {
        'reviewId': reviewId,
        'contentId': contentId,
        'contentType': contentType,
        'reason': reason,
        'status': 'pending',
        'submittedAt': DateTime.now().toIso8601String(),
        'reviewedAt': null,
        'decision': null,
      };

      final result = await _databaseService.createPath(
        'moderationReviews/$reviewId',
        reviewData,
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to submit for review: $e'));
    }
  }

  @override
  Future<Result<void>> approveContent(String contentId, String approvedBy) async {
    try {
      final result = await _databaseService.updatePath(
        'content/$contentId',
        {
          'status': 'approved',
          'approvedBy': approvedBy,
          'approvedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to approve content: $e'));
    }
  }

  @override
  Future<Result<void>> rejectContent(String contentId, String reason, String rejectedBy) async {
    try {
      final result = await _databaseService.updatePath(
        'content/$contentId',
        {
          'status': 'rejected',
          'rejectionReason': reason,
          'rejectedBy': rejectedBy,
          'rejectedAt': DateTime.now().toIso8601String(),
        },
      );

      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to reject content: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getPendingReview() async {
    try {
      final result = await _databaseService.readPath('moderationReviews');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final pending = data.values
            .whereType<Map<String, dynamic>>()
            .where((review) => review['status'] == 'pending')
            .toList();
        return Result.success(pending);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get pending reviews: $e'));
    }
  }
}
