import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IEvidenceUploadService {
  Future<Result<String>> uploadEvidence(String disputeId, String userId, List<int> fileData, String fileName);
  Future<Result<List<Map<String, dynamic>>>> getDisputeEvidence(String disputeId);
  Future<Result<void>> deleteEvidence(String evidenceId);
}

class EvidenceUploadService implements IEvidenceUploadService {
  late final UnifiedDatabaseService _databaseService;

  EvidenceUploadService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize EvidenceUploadService: $e');
    }
  }

  @override
  Future<Result<String>> uploadEvidence(String disputeId, String userId, List<int> fileData, String fileName) async {
    try {
      final evidenceId = 'evidence_${DateTime.now().millisecondsSinceEpoch}';
      
      final evidenceData = {
        'evidenceId': evidenceId,
        'disputeId': disputeId,
        'userId': userId,
        'fileName': fileName,
        'fileSize': fileData.length,
        'uploadedAt': DateTime.now().toIso8601String(),
        'verified': false,
        'hash': _generateHash(fileData),
      };

      final result = await _databaseService.createPath(
        'evidence/$evidenceId',
        evidenceData,
      );

      if (result.isSuccess()) {
        // Also add to dispute's evidence list
        await _databaseService.updatePath(
          'disputes/$disputeId/evidence',
          {evidenceId: evidenceData},
        );
        return Result.success(evidenceId);
      } else {
        return Result.failure(result.exception ?? Exception('Failed to upload evidence'));
      }
    } catch (e) {
      return Result.failure(Exception('Failed to upload evidence: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getDisputeEvidence(String disputeId) async {
    try {
      final result = await _databaseService.readPath('disputes/$disputeId/evidence');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final evidence = data.values
            .whereType<Map<String, dynamic>>()
            .toList();
        return Result.success(evidence);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get dispute evidence: $e'));
    }
  }

  @override
  Future<Result<void>> deleteEvidence(String evidenceId) async {
    try {
      final result = await _databaseService.deletePath('evidence/$evidenceId');
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to delete evidence: $e'));
    }
  }

  String _generateHash(List<int> fileData) {
    // Simple hash generation based on file data
    int hash = 0;
    for (int byte in fileData) {
      hash = ((hash << 5) - hash) + byte;
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs().toString();
  }
}
