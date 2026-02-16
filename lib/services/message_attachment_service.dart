import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IMessageAttachmentService {
  Future<Result<String>> uploadAttachment(String messageId, List<int> fileData, String fileName);
  Future<Result<List<Map<String, dynamic>>>> getMessageAttachments(String messageId);
  Future<Result<void>> deleteAttachment(String attachmentId);
}

class MessageAttachmentService implements IMessageAttachmentService {
  late final UnifiedDatabaseService _databaseService;

  MessageAttachmentService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize MessageAttachmentService: $e');
    }
  }

  @override
  Future<Result<String>> uploadAttachment(String messageId, List<int> fileData, String fileName) async {
    try {
      final attachmentId = 'attachment_${DateTime.now().millisecondsSinceEpoch}';
      
      final attachmentData = {
        'attachmentId': attachmentId,
        'messageId': messageId,
        'fileName': fileName,
        'fileSize': fileData.length,
        'uploadedAt': DateTime.now().toIso8601String(),
        'mimeType': _getMimeType(fileName),
      };

      final result = await _databaseService.createPath(
        'attachments/$attachmentId',
        attachmentData,
      );

      if (result.isSuccess()) {
        await _databaseService.updatePath(
          'messages/$messageId/attachments',
          {attachmentId: attachmentData},
        );
        return Result.success(attachmentId);
      } else {
        return Result.failure(result.exception ?? Exception('Failed to upload attachment'));
      }
    } catch (e) {
      return Result.failure(Exception('Failed to upload attachment: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getMessageAttachments(String messageId) async {
    try {
      final result = await _databaseService.readPath('messages/$messageId/attachments');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final attachments = data.values
            .whereType<Map<String, dynamic>>()
            .toList();
        return Result.success(attachments);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get message attachments: $e'));
    }
  }

  @override
  Future<Result<void>> deleteAttachment(String attachmentId) async {
    try {
      final result = await _databaseService.deletePath('attachments/$attachmentId');
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to delete attachment: $e'));
    }
  }

  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    const mimeTypes = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }
}
