import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IConversationArchivalService {
  Future<Result<void>> archiveConversation(String conversationId);
  Future<Result<void>> unarchiveConversation(String conversationId);
  Future<Result<List<Map<String, dynamic>>>> getArchivedConversations(String userId);
  Future<Result<void>> deleteArchivedConversation(String conversationId);
}

class ConversationArchivalService implements IConversationArchivalService {
  late final UnifiedDatabaseService _databaseService;

  ConversationArchivalService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize ConversationArchivalService: $e');
    }
  }

  @override
  Future<Result<void>> archiveConversation(String conversationId) async {
    try {
      final result = await _databaseService.updatePath(
        'conversations/$conversationId',
        {
          'isArchived': true,
          'archivedAt': DateTime.now().toIso8601String(),
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to archive conversation: $e'));
    }
  }

  @override
  Future<Result<void>> unarchiveConversation(String conversationId) async {
    try {
      final result = await _databaseService.updatePath(
        'conversations/$conversationId',
        {
          'isArchived': false,
          'archivedAt': null,
        },
      );
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to unarchive conversation: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getArchivedConversations(String userId) async {
    try {
      final result = await _databaseService.readPath('userConversations/$userId');
      
      if (result.isSuccess() && result.data is Map<String, dynamic>) {
        final data = result.data as Map<String, dynamic>;
        final archived = data.values
            .whereType<Map<String, dynamic>>()
            .where((conv) => conv['isArchived'] == true)
            .toList();
        return Result.success(archived);
      }

      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Failed to get archived conversations: $e'));
    }
  }

  @override
  Future<Result<void>> deleteArchivedConversation(String conversationId) async {
    try {
      final result = await _databaseService.deletePath('conversations/$conversationId');
      return result;
    } catch (e) {
      return Result.failure(Exception('Failed to delete archived conversation: $e'));
    }
  }
}
