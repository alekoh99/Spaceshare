import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/message_model.dart' show Conversation, Message;
import '../services/messaging_service.dart';
import 'auth_controller.dart';

class MessagingController extends GetxController {
  late IMessagingService _messagingService;

  IMessagingService get messagingService => _messagingService;

  @override
  void onInit() {
    super.onInit();
    try {
      _messagingService = Get.find<IMessagingService>();
      authController = Get.find<AuthController>();
    } catch (e) {
      debugPrint('Failed to resolve MessagingController services: $e');
      rethrow;
    }
  }

  // State
  final conversations = RxList<Conversation>([]);
  final currentMessages = RxList<Message>([]);
  final isLoadingConversations = false.obs;
  final isLoadingMessages = false.obs;
  final isSendingMessage = false.obs;
  final error = Rx<String?>(null);
  final currentConversationId = Rx<String?>(null);
  final currentMatchId = Rx<String?>(null);
  final unreadCount = 0.obs;
  final messageController = TextEditingController();
  
  // New state for enhanced messaging
  final searchResults = RxList<Message>([]);
  final isSearching = false.obs;
  final isEditing = false.obs;
  final editingMessageId = Rx<String?>(null);
  final typingUsers = RxMap<String, bool>({});
  final userPresence = RxMap<String, String>({});
  final selectedEmojis = <String, Rx<String>>{};

  late AuthController authController;
  Stream<List<Message>>? messageStream;
  Stream<List<Conversation>>? conversationStream;

  Future<void> loadConversations({int limit = 50}) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      isLoadingConversations.value = true;
      final result = await _messagingService.getConversations(
        authController.currentUserId.value!,
      );
      
      if (result.isSuccess()) {
        final convs = (result.getOrNull() as List<dynamic>?)?.cast<Conversation>() ?? <Conversation>[];
        conversations.value = convs;
      } else {
        conversations.value = [];
      }
      
      // Subscribe to real-time updates
      final streamResult = await _messagingService.getConversationsStream(
        authController.currentUserId.value!,
      );
      conversationStream = streamResult;
      
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingConversations.value = false;
    }
  }

  Future<void> selectConversation(String matchId) async {
    try {
      if (authController.currentUserId.value == null) {
        error.value = 'User not authenticated';
        return;
      }

      currentMatchId.value = matchId;
      isLoadingMessages.value = true;
      
      final result = await _messagingService.getMessages(matchId, limit: 50);
      if (result.isSuccess()) {
        final msgs = (result.getOrNull() as List<dynamic>?)?.cast<Message>() ?? <Message>[];
        currentMessages.value = msgs;
      } else {
        currentMessages.value = [];
      }

      // Subscribe to real-time message updates
      final streamResult = await _messagingService.getMessageStream(matchId);
      messageStream = streamResult;

      // Mark conversation as read
      await _messagingService.markConversationAsRead(matchId);

      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> sendMessage(String text) async {
    try {
      if (currentMatchId.value == null) {
        error.value = 'No conversation selected';
        return;
      }

      isSendingMessage.value = true;
      error.value = null;

      await _messagingService.sendMessage(
        currentMatchId.value!,
        authController.currentUserId.value!,
        text,
      );

      messageController.clear();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> loadMoreMessages() async {
    try {
      if (currentMatchId.value == null) return;

      final result = await _messagingService.getMessages(
        currentMatchId.value!,
        limit: 50,
        offset: currentMessages.length,
      );
      
      if (result.isSuccess()) {
        final msgs = (result.getOrNull() as List<dynamic>?)?.cast<Message>() ?? <Message>[];
        currentMessages.addAll(msgs);
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      if (currentMatchId.value == null) {
        error.value = 'No conversation selected';
        return;
      }

      await _messagingService.deleteMessage(
        currentMatchId.value!,
        messageId,
      );

      currentMessages.removeWhere((m) => m.messageId == messageId);
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> subscribeToMessages(String matchId) async {
    try {
      final stream = await _messagingService.getMessageStream(matchId);
      if (stream != null) {
        messageStream = stream;
        messageStream!.listen((messages) {
          currentMessages.value = messages;
        });
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  void unsubscribeFromMessages() {
    messageStream = null;
  }

  Stream<List<Message>>? getMessagesStream(String conversationId) {
    currentConversationId.value = conversationId;
    // This would require making the service method synchronous or handling differently
    // For now, return null as a placeholder
    return null;
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      isLoadingMessages.value = true;
      final result = await _messagingService.getMessages(conversationId);
      if (result.isSuccess()) {
        final messages = (result.getOrNull() as List<dynamic>?)?.cast<Message>() ?? <Message>[];
        currentMessages.value = messages;
      } else {
        currentMessages.value = [];
      }
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<void> sendMessageWithConversationId(
    String conversationId,
    String text,
  ) async {
    try {
      isSendingMessage.value = true;
      await _messagingService.sendMessage(
        conversationId,
        authController.currentUserId.value ?? '',
        text,
      );
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> sendImageMessage(
    String conversationId,
    String imagePath,
  ) async {
    try {
      isSendingMessage.value = true;
      await _messagingService.sendMessage(
        conversationId,
        authController.currentUserId.value ?? '',
        '',
        imageUrl: imagePath,
      );
      error.value = null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      if (currentMatchId.value == null) {
        error.value = 'No conversation selected';
        return;
      }
      await _messagingService.markMessageAsRead(currentMatchId.value!, messageId);
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<String> getOrCreateConversation({
    required String matchId,
    required String user1Id,
    required String user2Id,
  }) async {
    try {
      if (authController.currentUserId.value == null) {
        throw Exception('User not authenticated');
      }

      // Use the messaging service to get or create conversation
      final result = await _messagingService.getOrCreateConversation(
        matchId,
        user1Id,
        user2Id,
      );
      
      if (result.isSuccess()) {
        final conversationId = result.getOrNull() as String?;
        return conversationId ?? '';
      }

      return '';
    } catch (e) {
      error.value = 'Failed to create conversation: $e';
      rethrow;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      // Note: deleteConversation is not available in MessagingService
      // Using deleteOldMessages as alternative or removing conversation from list
      conversations.removeWhere((c) => c.conversationId == conversationId);
    } catch (e) {
      error.value = e.toString();
    }
  }

  void clearCurrentMessages() {
    currentMessages.clear();
    currentConversationId.value = null;
  }

  // New methods for enhanced messaging
  
  Future<void> editMessage(String messageId, String newText) async {
    try {
      if (currentMatchId.value == null) {
        error.value = 'No conversation selected';
        return;
      }
      
      isEditing.value = true;
      final result = await _messagingService.editMessage(
        currentMatchId.value!,
        messageId,
        newText,
      );
      
      if (result.isSuccess()) {
        // Update message in local list
        final msgIndex = currentMessages.indexWhere((m) => m.messageId == messageId);
        if (msgIndex != -1) {
          final msg = currentMessages[msgIndex];
          currentMessages[msgIndex] = msg.copyWith(
            editedText: newText,
            editedAt: DateTime.now(),
          );
        }
        editingMessageId.value = null;
      } else {
        error.value = 'Failed to edit message';
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isEditing.value = false;
    }
  }

  Future<void> searchMessages(String query) async {
    try {
      if (currentMatchId.value == null) {
        error.value = 'No conversation selected';
        return;
      }
      
      isSearching.value = true;
      final result = await _messagingService.searchMessages(currentMatchId.value!, query);
      
      if (result.isSuccess()) {
        final msgs = (result.getOrNull() as List<dynamic>?)?.cast<Message>() ?? <Message>[];
        searchResults.value = msgs;
      } else {
        searchResults.clear();
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearch() {
    searchResults.clear();
    isSearching.value = false;
  }

  Future<void> addReaction(String messageId, String emoji) async {
    try {
      if (currentMatchId.value == null) {
        error.value = 'No conversation selected';
        return;
      }
      
      final userId = authController.currentUserId.value ?? '';
      final result = await _messagingService.addReaction(
        currentMatchId.value!,
        messageId,
        userId,
        emoji,
      );
      
      if (result.isSuccess()) {
        final msgIndex = currentMessages.indexWhere((m) => m.messageId == messageId);
        if (msgIndex != -1) {
          final msg = currentMessages[msgIndex];
          final newReactions = Map<String, String>.from(msg.reactions);
          newReactions[userId] = emoji;
          currentMessages[msgIndex] = msg.copyWith(reactions: newReactions);
        }
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> removeReaction(String messageId) async {
    try {
      if (currentMatchId.value == null) {
        error.value = 'No conversation selected';
        return;
      }
      
      final userId = authController.currentUserId.value ?? '';
      final result = await _messagingService.removeReaction(
        currentMatchId.value!,
        messageId,
        userId,
      );
      
      if (result.isSuccess()) {
        final msgIndex = currentMessages.indexWhere((m) => m.messageId == messageId);
        if (msgIndex != -1) {
          final msg = currentMessages[msgIndex];
          final newReactions = Map<String, String>.from(msg.reactions);
          newReactions.remove(userId);
          currentMessages[msgIndex] = msg.copyWith(reactions: newReactions);
        }
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> pinConversation(String conversationId) async {
    try {
      final idx = conversations.indexWhere((c) => c.conversationId == conversationId);
      final isPinned = idx != -1 ? !conversations[idx].isPinned : false;
      
      final result = await _messagingService.pinConversation(conversationId, !isPinned);
      
      if (result.isSuccess() && idx != -1) {
        final conv = conversations[idx];
        conversations[idx] = conv.copyWith(isPinned: !isPinned);
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> muteConversation(String conversationId) async {
    try {
      final idx = conversations.indexWhere((c) => c.conversationId == conversationId);
      final isMuted = idx != -1 ? !conversations[idx].isMuted : false;
      
      final result = await _messagingService.muteConversation(conversationId, !isMuted);
      
      if (result.isSuccess() && idx != -1) {
        final conv = conversations[idx];
        conversations[idx] = conv.copyWith(isMuted: !isMuted);
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> setTypingIndicator(bool isTyping) async {
    try {
      if (currentMatchId.value == null) return;
      
      await _messagingService.setTypingIndicator(currentMatchId.value!, isTyping);
    } catch (e) {
      debugPrint('Typing indicator error: $e');
    }
  }

  Future<void> setUserPresence(String status) async {
    try {
      final userId = authController.currentUserId.value;
      if (userId == null) return;
      
      final result = await _messagingService.setUserPresence(userId, status);
      if (result.isSuccess()) {
        userPresence[userId] = status;
      }
    } catch (e) {
      debugPrint('Presence error: $e');
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    conversations.clear();
    currentMessages.clear();
    searchResults.clear();
    messageStream = null;
    conversationStream = null;
    unsubscribeFromMessages();
    super.onClose();
  }
}
