import 'package:get/get.dart';
import '../models/message_model.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IMessagingService {
  // New interface methods that match controller expectations
  Future<Result> sendMessage(
    String conversationId,
    String senderId,
    String content, {
    String? imageUrl,
  });

  Future<Result> getMessages(String conversationId, {int limit = 50, int offset = 0});
  Future<Stream<List<Message>>?> getMessageStream(String conversationId);
  Future<Result> getConversations(String userId);
  Future<Stream<List<Conversation>>?> getConversationsStream(String userId);
  Future<Result> markConversationAsRead(String conversationId);
  Future<Result> markMessageAsRead(String conversationId, String messageId);
  Future<Result> deleteMessage(String conversationId, String messageId);
  Future<Result> getOrCreateConversation(String matchId, String user1Id, String user2Id);
  
  // New methods for enhanced messaging
  Future<Result> editMessage(String conversationId, String messageId, String newText);
  Future<Result> searchMessages(String conversationId, String query);
  Future<Result> addReaction(String conversationId, String messageId, String userId, String emoji);
  Future<Result> removeReaction(String conversationId, String messageId, String userId);
  Future<Result> pinConversation(String conversationId, bool isPinned);
  Future<Result> muteConversation(String conversationId, bool isMuted);
  Future<Result> blockUser(String userId, bool isBlocked);
  Future<Result> setUserPresence(String userId, String status);
  Future<Result> setTypingIndicator(String conversationId, bool isTyping);

  // Legacy methods for compatibility
  Future<Result> getConversationMessages(String conversationId);
  Future<Result> markMessagesAsRead(String conversationId, String userId);
}

class MessagingService extends GetxService implements IMessagingService {
  late final UnifiedDatabaseService _databaseService;

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize MessagingService: $e');
    }
  }

  @override
  Future<Result> sendMessage(
    String conversationId,
    String senderId,
    String content, {
    String? imageUrl,
  }) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get conversation to find matchId and other users
      final convResult = await _databaseService.readPath('conversations/$conversationId');
      if (!convResult.isSuccess() || convResult.data == null) {
        return Result.failure(Exception('Conversation not found'));
      }
      
      final convData = Map<String, dynamic>.from(convResult.data!);
      final matchId = convData['matchId'] ?? conversationId;
      
      final message = Message(
        messageId: messageId,
        senderId: senderId,
        recipientId: convData['user2Id'] ?? '',
        matchId: matchId,
        text: content,
        sentAt: DateTime.now(),
        isRead: false,
      );

      final result = await _databaseService.createPath(
        'messages/$conversationId/$messageId',
        message.toJson(),
      );
      
      if (result.isSuccess()) {
        // Update conversation lastMessage
        await _databaseService.updatePath(
          'conversations/$conversationId',
          {
            'lastMessage': content,
            'lastMessageSenderId': senderId,
            'lastMessageAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
        return Result.success(messageId);
      } else {
        return Result.failure(result.exception ?? Exception('Failed to send message'));
      }
    } catch (e) {
      return Result.failure(Exception('Error sending message: $e'));
    }
  }

  @override
  Future<Result> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    try {
      final result = await _databaseService.readPath('messages/$conversationId');
      
      if (result.isSuccess() && result.data != null) {
        final messagesData = Map<String, dynamic>.from(result.data!);
        final messages = <Message>[];
        
        messagesData.forEach((key, value) {
          final msgData = Map<String, dynamic>.from(value as Map);
          messages.add(Message.fromJson(msgData));
        });
        
        // Sort by sentAt descending
        messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        
        // Apply limit and offset
        final paginatedMessages = messages.skip(offset).take(limit).toList();
        return Result.success(paginatedMessages);
      }
      
      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Error fetching messages: $e'));
    }
  }

  @override
  Future<Stream<List<Message>>?> getMessageStream(String conversationId) async {
    try {
      // Return a stream - in a real implementation this would be a listener
      // For now, return null to indicate not implemented
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Result> getConversations(String userId) async {
    try {
      final result = await _databaseService.readPath('conversations');
      
      if (result.isSuccess() && result.data != null) {
        final conversationsData = Map<String, dynamic>.from(result.data!);
        final conversations = <Conversation>[];
        
        conversationsData.forEach((key, value) {
          final convData = Map<String, dynamic>.from(value as Map);
          if (convData['user1Id'] == userId || convData['user2Id'] == userId) {
            conversations.add(Conversation(
              conversationId: convData['conversationId'] ?? key,
              user1Id: convData['user1Id'] ?? '',
              user2Id: convData['user2Id'] ?? '',
              matchId: convData['matchId'] ?? '',
              lastMessage: convData['lastMessage'],
              lastMessageSenderId: convData['lastMessageSenderId'],
              lastMessageAt: convData['lastMessageAt'],
              createdAt: convData['createdAt'],
              updatedAt: convData['updatedAt'],
            ));
          }
        });
        
        return Result.success(conversations);
      }
      
      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Error fetching conversations: $e'));
    }
  }

  @override
  Future<Stream<List<Conversation>>?> getConversationsStream(String userId) async {
    try {
      // Return a stream - in a real implementation this would be a listener
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Result> markConversationAsRead(String conversationId) async {
    try {
      final messagesResult = await getMessages(conversationId);
      if (messagesResult is Success<List<Message>>) {
        final messages = messagesResult.getOrNull() as List<dynamic>? ?? [];
        for (final msg in messages) {
          if (msg is Message) {
            await _databaseService.updatePath(
              'messages/$conversationId/${msg.messageId}',
              {'isRead': true, 'readAt': DateTime.now().toIso8601String()},
            );
          }
        }
        return Result.success(null);
      }
      return Result.failure(Exception('Failed to mark conversation as read'));
    } catch (e) {
      return Result.failure(Exception('Error marking conversation as read: $e'));
    }
  }

  @override
  Future<Result> getConversationMessages(String conversationId) async {
    try {
      final result = await _databaseService.readPath('messages/$conversationId');
      
      if (result.isSuccess() && result.data != null) {
        final messagesData = Map<String, dynamic>.from(result.data!);
        final messages = <Message>[];
        
        messagesData.forEach((key, value) {
          final msgData = Map<String, dynamic>.from(value as Map);
          messages.add(Message.fromJson(msgData));
        });
        
        // Sort by sentAt descending
        messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        return Result.success(messages);
      }
      
      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Error fetching messages: $e'));
    }
  }

  @override
  Future<Result> markMessagesAsRead(String conversationId, String userId) async {
    try {
      final messagesResult = await getConversationMessages(conversationId);
      if (messagesResult.isSuccess()) {
        for (final msg in messagesResult.data ?? []) {
          if (msg.senderId != userId && !msg.isRead) {
            // Update message read status in database
            await _databaseService.updatePath(
              'messages/$conversationId/${msg.messageId}',
              {'isRead': true, 'readAt': DateTime.now().toIso8601String()},
            );
          }
        }
        return Result.success(null);
      }
      return Result.failure(messagesResult.exception ?? Exception('Failed to mark messages as read'));
    } catch (e) {
      return Result.failure(Exception('Error marking messages as read: $e'));
    }
  }

  @override
  Future<Result> deleteMessage(String conversationId, String messageId) async {
    try {
      await _databaseService.deletePath('messages/$conversationId/$messageId');
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error deleting message: $e'));
    }
  }

  @override
  Future<Result> markMessageAsRead(String conversationId, String messageId) async {
    try {
      await _databaseService.updatePath(
        'messages/$conversationId/$messageId',
        {'isRead': true, 'readAt': DateTime.now().toIso8601String()},
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error marking message as read: $e'));
    }
  }

  @override
  Future<Result> getOrCreateConversation(String matchId, String user1Id, String user2Id) async {
    try {
      final conversationsResult = await _databaseService.readPath('conversations');
      
      if (conversationsResult.isSuccess() && conversationsResult.data != null) {
        final conversations = Map<String, dynamic>.from(conversationsResult.data!);
        
        // Look for existing conversation
        for (final entry in conversations.entries) {
          final conv = Map<String, dynamic>.from(entry.value as Map);
          if ((conv['user1Id'] == user1Id && conv['user2Id'] == user2Id) ||
              (conv['user1Id'] == user2Id && conv['user2Id'] == user1Id)) {
            return Result.success(entry.key);
          }
        }
      }
      
      // Create new conversation
      final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
      final result = await _databaseService.createPath('conversations/$conversationId', {
        'conversationId': conversationId,
        'matchId': matchId,
        'user1Id': user1Id,
        'user2Id': user2Id,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      if (result.isSuccess()) {
        return Result.success(conversationId);
      }
      return Result.failure(result.exception ?? Exception('Failed to create conversation'));
    } catch (e) {
      return Result.failure(Exception('Error getting or creating conversation: $e'));
    }
  }

  @override
  Future<Result> editMessage(String conversationId, String messageId, String newText) async {
    try {
      // Get the original message
      final msgResult = await _databaseService.readPath('messages/$conversationId/$messageId');
      if (!msgResult.isSuccess() || msgResult.data == null) {
        return Result.failure(Exception('Message not found'));
      }
      
      // Update the message
      await _databaseService.updatePath(
        'messages/$conversationId/$messageId',
        {
          'editedText': newText,
          'editedAt': DateTime.now().toIso8601String(),
        },
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error editing message: $e'));
    }
  }

  @override
  Future<Result> searchMessages(String conversationId, String query) async {
    try {
      final result = await _databaseService.readPath('messages/$conversationId');
      
      if (result.isSuccess() && result.data != null) {
        final messagesData = Map<String, dynamic>.from(result.data!);
        final messages = <Message>[];
        final queryLower = query.toLowerCase();
        
        messagesData.forEach((key, value) {
          final msgData = Map<String, dynamic>.from(value as Map);
          final message = Message.fromJson(msgData);
          
          // Search in text and edited text
          if (message.text.toLowerCase().contains(queryLower) ||
              (message.editedText?.toLowerCase().contains(queryLower) ?? false)) {
            messages.add(message);
          }
        });
        
        // Sort by sentAt descending
        messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
        return Result.success(messages);
      }
      
      return Result.success([]);
    } catch (e) {
      return Result.failure(Exception('Error searching messages: $e'));
    }
  }

  @override
  Future<Result> addReaction(String conversationId, String messageId, String userId, String emoji) async {
    try {
      final msgResult = await _databaseService.readPath('messages/$conversationId/$messageId');
      if (!msgResult.isSuccess() || msgResult.data == null) {
        return Result.failure(Exception('Message not found'));
      }
      
      final msgData = Map<String, dynamic>.from(msgResult.data!);
      final reactions = Map<String, String>.from(msgData['reactions'] ?? {});
      reactions[userId] = emoji;
      
      await _databaseService.updatePath(
        'messages/$conversationId/$messageId',
        {'reactions': reactions},
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error adding reaction: $e'));
    }
  }

  @override
  Future<Result> removeReaction(String conversationId, String messageId, String userId) async {
    try {
      final msgResult = await _databaseService.readPath('messages/$conversationId/$messageId');
      if (!msgResult.isSuccess() || msgResult.data == null) {
        return Result.failure(Exception('Message not found'));
      }
      
      final msgData = Map<String, dynamic>.from(msgResult.data!);
      final reactions = Map<String, String>.from(msgData['reactions'] ?? {});
      reactions.remove(userId);
      
      await _databaseService.updatePath(
        'messages/$conversationId/$messageId',
        {'reactions': reactions},
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error removing reaction: $e'));
    }
  }

  @override
  Future<Result> pinConversation(String conversationId, bool isPinned) async {
    try {
      await _databaseService.updatePath(
        'conversations/$conversationId',
        {'isPinned': isPinned, 'updatedAt': DateTime.now().toIso8601String()},
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error pinning conversation: $e'));
    }
  }

  @override
  Future<Result> muteConversation(String conversationId, bool isMuted) async {
    try {
      await _databaseService.updatePath(
        'conversations/$conversationId',
        {'isMuted': isMuted, 'updatedAt': DateTime.now().toIso8601String()},
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error muting conversation: $e'));
    }
  }

  @override
  Future<Result> blockUser(String userId, bool isBlocked) async {
    try {
      await _databaseService.updatePath(
        'users/$userId/settings',
        {'isBlocked': isBlocked, 'blockedAt': DateTime.now().toIso8601String()},
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error blocking user: $e'));
    }
  }

  @override
  Future<Result> setUserPresence(String userId, String status) async {
    try {
      await _databaseService.updatePath(
        'presence/$userId',
        {
          'status': status,
          'lastSeen': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error setting presence: $e'));
    }
  }

  @override
  Future<Result> setTypingIndicator(String conversationId, bool isTyping) async {
    try {
      // This would be implemented with real-time database listeners
      // For now, just log the typing status
      if (isTyping) {
        // Can add to a temporary typing indicators collection
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Error setting typing indicator: $e'));
    }
  }
}
