const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');
const { responseFormatter } = require('../middleware/responseFormatter');
const MessageService = require('../services/MessageService');

router.use(responseFormatter);

/**
 * GET /api/messaging/conversations
 * Get all conversations for current user
 */
router.get('/conversations', verifyToken, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;
    const userId = req.user.uid;

    const result = await MessageService.getConversations(userId, parseInt(limit), parseInt(offset));
    
    res.success(result, 'Conversations fetched successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * GET /api/messaging/conversation/:conversationId
 * Get specific conversation details
 */
router.get('/conversation/:conversationId', verifyToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.uid;

    if (!conversationId) {
      return res.failure('Conversation ID is required', 400);
    }

    const admin = require('firebase-admin');
    const db = admin.database();
    const snapshot = await db.ref(`conversations/${conversationId}`).once('value');
    
    if (!snapshot.exists()) {
      return res.failure('Conversation not found', 404);
    }
    
    const conversation = snapshot.val();
    
    // Verify user is part of this conversation
    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      return res.failure('Unauthorized', 403);
    }
    
    res.success(conversation, 'Conversation fetched successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * GET /api/messaging/messages/:conversationId
 * Get paginated messages in a conversation
 */
router.get('/messages/:conversationId', verifyToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    const userId = req.user.uid;

    if (!conversationId) {
      return res.failure('Conversation ID is required', 400);
    }

    const result = await MessageService.getMessages(
      conversationId,
      parseInt(limit),
      parseInt(offset)
    );
    
    res.success(result, 'Messages fetched successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * POST /api/messaging/send
 * Send a message
 */
router.post('/send', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { conversationId, text, attachments = [] } = req.body;

    if (!conversationId || !text) {
      return res.failure('Conversation ID and message text are required', 400);
    }

    const message = await MessageService.sendMessage(conversationId, userId, text, attachments);
    
    res.success(message, 'Message sent successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * POST /api/messaging/conversation
 * Create a new conversation
 */
router.post('/conversation', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { matchId, participantId } = req.body;

    if (!participantId) {
      return res.failure('Participant ID is required', 400);
    }

    const conversationId = await MessageService.getOrCreateConversation(
      matchId || `match_${Date.now()}`,
      userId,
      participantId
    );
    
    res.success({ conversationId }, 'Conversation created successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * DELETE /api/messaging/conversation/:conversationId
 * Delete a conversation
 */
router.delete('/conversation/:conversationId', verifyToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.uid;

    if (!conversationId) {
      return res.failure('Conversation ID is required', 400);
    }

    const admin = require('firebase-admin');
    const db = admin.database();
    
    // Verify ownership
    const snapshot = await db.ref(`conversations/${conversationId}`).once('value');
    if (!snapshot.exists()) {
      return res.failure('Conversation not found', 404);
    }
    
    const conversation = snapshot.val();
    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      return res.failure('Unauthorized', 403);
    }

    await db.ref(`conversations/${conversationId}`).remove();
    
    res.success({ conversationId, deleted: true }, 'Conversation deleted successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * PUT /api/messaging/messages/:messageId
 * Edit a message
 */
router.put('/messages/:messageId', verifyToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const { conversationId, text } = req.body;
    const userId = req.user.uid;

    if (!messageId || !text || !conversationId) {
      return res.failure('Message ID, text, and conversation ID are required', 400);
    }

    await MessageService.editMessage(conversationId, messageId, text);
    
    res.success({ messageId, text, editedAt: new Date().toISOString() }, 'Message edited successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * DELETE /api/messaging/messages/:messageId
 * Delete a message
 */
router.delete('/messages/:messageId', verifyToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const { conversationId } = req.body;
    const userId = req.user.uid;

    if (!messageId || !conversationId) {
      return res.failure('Message ID and conversation ID are required', 400);
    }

    await MessageService.deleteMessage(conversationId, messageId);
    
    res.success({ messageId, deleted: true }, 'Message deleted successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * POST /api/messaging/messages/:messageId/reactions
 * Add reaction to a message
 */
router.post('/messages/:messageId/reactions', verifyToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const { conversationId, emoji } = req.body;
    const userId = req.user.uid;

    if (!messageId || !conversationId || !emoji) {
      return res.failure('Message ID, conversation ID, and emoji are required', 400);
    }

    const result = await MessageService.addReaction(conversationId, messageId, userId, emoji);
    
    res.success(result, 'Reaction added successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * DELETE /api/messaging/messages/:messageId/reactions
 * Remove reaction from a message
 */
router.delete('/messages/:messageId/reactions', verifyToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const { conversationId } = req.body;
    const userId = req.user.uid;

    if (!messageId || !conversationId) {
      return res.failure('Message ID and conversation ID are required', 400);
    }

    const result = await MessageService.removeReaction(conversationId, messageId, userId);
    
    res.success(result, 'Reaction removed successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * GET /api/messaging/search/:conversationId
 * Search messages
 */
router.get('/search/:conversationId', verifyToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { q } = req.query;
    const userId = req.user.uid;

    if (!conversationId || !q) {
      return res.failure('Conversation ID and search query are required', 400);
    }

    const results = await MessageService.searchMessages(conversationId, q);
    
    res.success({ results, count: results.length }, 'Search completed successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * PUT /api/messaging/messages/:messageId/read
 * Mark message as read
 */
router.put('/messages/:messageId/read', verifyToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const { conversationId } = req.body;

    if (!messageId || !conversationId) {
      return res.failure('Message ID and conversation ID are required', 400);
    }

    await MessageService.markMessageAsRead(conversationId, messageId);
    
    res.success({ messageId, isRead: true }, 'Message marked as read');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * PUT /api/messaging/conversations/:conversationId/read
 * Mark all messages in conversation as read
 */
router.put('/conversations/:conversationId/read', verifyToken, async (req, res) => {
  try {
    const { conversationId } = req.params;

    if (!conversationId) {
      return res.failure('Conversation ID is required', 400);
    }

    await MessageService.markConversationAsRead(conversationId);
    
    res.success({ conversationId, allRead: true }, 'Conversation marked as read');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * GET /api/messaging/unread-count
 * Get unread message count
 */
router.get('/unread-count', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;

    const unreadCount = await MessageService.getUnreadCount(userId);
    
    res.success({ unreadCount }, 'Unread count fetched successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * PUT /api/messaging/conversations/:conversationId/pin
 * Pin a conversation
 */
router.put('/conversations/:conversationId/pin', verifyToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { isPinned } = req.body;

    if (conversationId === undefined || isPinned === undefined) {
      return res.failure('Conversation ID and pin status are required', 400);
    }

    await MessageService.pinConversation(conversationId, isPinned);
    
    res.success({ conversationId, isPinned }, 'Conversation pinned successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * PUT /api/messaging/conversations/:conversationId/mute
 * Mute a conversation
 */
router.put('/conversations/:conversationId/mute', verifyToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { isMuted } = req.body;

    if (conversationId === undefined || isMuted === undefined) {
      return res.failure('Conversation ID and mute status are required', 400);
    }

    await MessageService.muteConversation(conversationId, isMuted);
    
    res.success({ conversationId, isMuted }, 'Conversation muted successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * POST /api/messaging/typing
 * Send typing indicator
 */
router.post('/typing', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { conversationId, isTyping } = req.body;

    if (!conversationId || isTyping === undefined) {
      return res.failure('Conversation ID and typing status are required', 400);
    }

    const admin = require('firebase-admin');
    const db = admin.database();
    
    if (isTyping) {
      await db.ref(`typing/${conversationId}/${userId}`).set({
        userId,
        isTyping: true,
        timestamp: new Date().toISOString(),
      });
    } else {
      await db.ref(`typing/${conversationId}/${userId}`).remove();
    }
    
    res.success({ conversationId, userId, isTyping }, 'Typing status updated');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * POST /api/messaging/presence
 * Update user presence
 */
router.post('/presence', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { status } = req.body; // 'online', 'away', 'offline'

    if (!status) {
      return res.failure('Status is required', 400);
    }

    const admin = require('firebase-admin');
    const db = admin.database();
    
    await db.ref(`presence/${userId}`).set({
      userId,
      status,
      lastSeen: new Date().toISOString(),
    });
    
    res.success({ userId, status }, 'Presence updated');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * POST /api/messaging/block/:userId
 * Block a user
 */
router.post('/block/:userId', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { userId: blockedUserId } = req.params;

    if (!blockedUserId) {
      return res.failure('User ID is required', 400);
    }

    const admin = require('firebase-admin');
    const db = admin.database();
    
    await db.ref(`blocked_users/${userId}/${blockedUserId}`).set({
      blockedUserId,
      blockedAt: new Date().toISOString(),
    });
    
    res.success({ blockedUserId, blocked: true }, 'User blocked successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * DELETE /api/messaging/block/:userId
 * Unblock a user
 */
router.delete('/block/:userId', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { userId: blockedUserId } = req.params;

    if (!blockedUserId) {
      return res.failure('User ID is required', 400);
    }

    const admin = require('firebase-admin');
    const db = admin.database();
    
    await db.ref(`blocked_users/${userId}/${blockedUserId}`).remove();
    
    res.success({ blockedUserId, blocked: false }, 'User unblocked successfully');
  } catch (error) {
    res.failure(error.message, 500);
  }
});

module.exports = router;

/**
 * DELETE /api/messaging/messages/:messageId
 * Delete a message
 */
router.delete('/messages/:messageId', verifyToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.uid;

    if (!messageId) {
      return res.failure('Message ID is required', 400);
    }

    // TODO: Integrate with MessagingService
    res.success(
      {
        messageId,
        deleted: true,
      },
      'Message deleted successfully'
    );
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * POST /api/messaging/typing
 * Send typing indicator
 */
router.post('/typing', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    const { conversationId, isTyping } = req.body;

    if (!conversationId) {
      return res.failure('Conversation ID is required', 400);
    }

    // TODO: Integrate with TypingIndicatorService
    res.success(
      {
        conversationId,
        userId,
        isTyping,
      },
      'Typing status updated'
    );
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * POST /api/messaging/upload-attachment
 * Upload message attachment
 */
router.post('/upload-attachment', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;
    // TODO: Handle file upload with proper validation
    
    res.success(
      {
        attachmentId: '',
        url: '',
        type: 'image',
        size: 0,
      },
      'Attachment uploaded successfully'
    );
  } catch (error) {
    res.failure(error.message, 500);
  }
});

/**
 * GET /api/messaging/unread-count
 * Get unread message count
 */
router.get('/unread-count', verifyToken, async (req, res) => {
  try {
    const userId = req.user.uid;

    // TODO: Integrate with MessagingService
    res.success(
      {
        unreadCount: 0,
      },
      'Unread count fetched successfully'
    );
  } catch (error) {
    res.failure(error.message, 500);
  }
});

module.exports = router;
