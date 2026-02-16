const admin = require('firebase-admin');

class MessageService {
  // Lazy getter for Firebase database to avoid initialization timing issues
  static getDb() {
    if (!admin.apps.length) {
      throw new Error('Firebase not initialized. Ensure initializeFirebase() is called before using MessageService.');
    }
    return admin.database();
  }
  /**
   * Send a message
   */
  static async sendMessage(conversationId, senderId, text, attachments = []) {
    try {
      const messageId = `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const timestamp = new Date().toISOString();
      
      const message = {
        messageId,
        conversationId,
        senderId,
        text,
        type: 'text',
        status: 'sent',
        attachments,
        sentAt: timestamp,
        isRead: false,
        reactions: {},
      };
      
      // Save message
      await this.getDb().ref(`messages/${conversationId}/${messageId}`).set(message);
      
      // Update conversation last message
      await this.getDb().ref(`conversations/${conversationId}`).update({
        lastMessage: text,
        lastMessageSenderId: senderId,
        lastMessageAt: timestamp,
        updatedAt: timestamp,
      });
      
      return message;
    } catch (error) {
      throw new Error(`Failed to send message: ${error.message}`);
    }
  }

  /**
   * Get messages for a conversation
   */
  static async getMessages(conversationId, limit = 50, offset = 0) {
    try {
      const snapshot = await this.getDb().ref(`messages/${conversationId}`).once('value');
      
      if (!snapshot.exists()) {
        return { messages: [], total: 0 };
      }
      
      const messagesObj = snapshot.val();
      const messages = Object.values(messagesObj)
        .sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt))
        .slice(offset, offset + limit);
      
      return {
        messages,
        total: Object.keys(messagesObj).length,
        limit,
        offset,
      };
    } catch (error) {
      throw new Error(`Failed to fetch messages: ${error.message}`);
    }
  }

  /**
   * Edit a message
   */
  static async editMessage(conversationId, messageId, newText) {
    try {
      const snapshot = await this.getDb().ref(`messages/${conversationId}/${messageId}`).once('value');
      
      if (!snapshot.exists()) {
        throw new Error('Message not found');
      }
      
      await this.getDb().ref(`messages/${conversationId}/${messageId}`).update({
        editedText: newText,
        editedAt: new Date().toISOString(),
      });
      
      return { success: true };
    } catch (error) {
      throw new Error(`Failed to edit message: ${error.message}`);
    }
  }

  /**
   * Delete a message
   */
  static async deleteMessage(conversationId, messageId) {
    try {
      await this.getDb().ref(`messages/${conversationId}/${messageId}`).remove();
      return { success: true, messageId };
    } catch (error) {
      throw new Error(`Failed to delete message: ${error.message}`);
    }
  }

  /**
   * Search messages in a conversation
   */
  static async searchMessages(conversationId, query) {
    try {
      const snapshot = await this.getDb().ref(`messages/${conversationId}`).once('value');
      
      if (!snapshot.exists()) {
        return [];
      }
      
      const messagesObj = snapshot.val();
      const queryLower = query.toLowerCase();
      
      const results = Object.values(messagesObj).filter(
        (msg) =>
          msg.text.toLowerCase().includes(queryLower) ||
          (msg.editedText && msg.editedText.toLowerCase().includes(queryLower))
      );
      
      return results.sort((a, b) => new Date(b.sentAt) - new Date(a.sentAt));
    } catch (error) {
      throw new Error(`Failed to search messages: ${error.message}`);
    }
  }

  /**
   * Add reaction to a message
   */
  static async addReaction(conversationId, messageId, userId, emoji) {
    try {
      const snapshot = await this.getDb().ref(`messages/${conversationId}/${messageId}`).once('value');
      
      if (!snapshot.exists()) {
        throw new Error('Message not found');
      }
      
      const message = snapshot.val();
      const reactions = message.reactions || {};
      reactions[userId] = emoji;
      
      await this.getDb().ref(`messages/${conversationId}/${messageId}/reactions`).set(reactions);
      
      return { success: true, reactions };
    } catch (error) {
      throw new Error(`Failed to add reaction: ${error.message}`);
    }
  }

  /**
   * Remove reaction from a message
   */
  static async removeReaction(conversationId, messageId, userId) {
    try {
      const snapshot = await this.getDb().ref(`messages/${conversationId}/${messageId}`).once('value');
      
      if (!snapshot.exists()) {
        throw new Error('Message not found');
      }
      
      const message = snapshot.val();
      const reactions = message.reactions || {};
      delete reactions[userId];
      
      await this.getDb().ref(`messages/${conversationId}/${messageId}/reactions`).set(reactions);
      
      return { success: true, reactions };
    } catch (error) {
      throw new Error(`Failed to remove reaction: ${error.message}`);
    }
  }

  /**
   * Mark message as read
   */
  static async markMessageAsRead(conversationId, messageId) {
    try {
      await this.getDb().ref(`messages/${conversationId}/${messageId}`).update({
        isRead: true,
        readAt: new Date().toISOString(),
      });
      
      return { success: true };
    } catch (error) {
      throw new Error(`Failed to mark message as read: ${error.message}`);
    }
  }

  /**
   * Mark all messages in conversation as read
   */
  static async markConversationAsRead(conversationId) {
    try {
      const snapshot = await this.getDb().ref(`messages/${conversationId}`).once('value');
      
      if (!snapshot.exists()) {
        return { success: true };
      }
      
      const messagesObj = snapshot.val();
      const updates = {};
      const now = new Date().toISOString();
      
      Object.entries(messagesObj).forEach(([msgId, msg]) => {
        if (!msg.isRead) {
          updates[`messages/${conversationId}/${msgId}/isRead`] = true;
          updates[`messages/${conversationId}/${msgId}/readAt`] = now;
        }
      });
      
      if (Object.keys(updates).length > 0) {
        await this.getDb().ref().update(updates);
      }
      
      return { success: true };
    } catch (error) {
      throw new Error(`Failed to mark conversation as read: ${error.message}`);
    }
  }

  /**
   * Get unread message count
   */
  static async getUnreadCount(userId) {
    try {
      const conversationsSnapshot = await this.getDb().ref('conversations').once('value');
      
      if (!conversationsSnapshot.exists()) {
        return 0;
      }
      
      const conversations = conversationsSnapshot.val();
      let unreadCount = 0;
      
      for (const [convId, conv] of Object.entries(conversations)) {
        if (conv.user1Id === userId || conv.user2Id === userId) {
          const messagesSnapshot = await this.getDb().ref(`messages/${convId}`).once('value');
          
          if (messagesSnapshot.exists()) {
            const messages = messagesSnapshot.val();
            unreadCount += Object.values(messages).filter(
              (msg) => !msg.isRead && msg.senderId !== userId
            ).length;
          }
        }
      }
      
      return unreadCount;
    } catch (error) {
      throw new Error(`Failed to get unread count: ${error.message}`);
    }
  }

  /**
   * Pin a conversation
   */
  static async pinConversation(conversationId, isPinned) {
    try {
      await this.getDb().ref(`conversations/${conversationId}`).update({
        isPinned,
        updatedAt: new Date().toISOString(),
      });
      
      return { success: true };
    } catch (error) {
      throw new Error(`Failed to pin conversation: ${error.message}`);
    }
  }

  /**
   * Mute a conversation
   */
  static async muteConversation(conversationId, isMuted) {
    try {
      await this.getDb().ref(`conversations/${conversationId}`).update({
        isMuted,
        updatedAt: new Date().toISOString(),
      });
      
      return { success: true };
    } catch (error) {
      throw new Error(`Failed to mute conversation: ${error.message}`);
    }
  }

  /**
   * Get conversations for a user
   */
  static async getConversations(userId, limit = 20, offset = 0) {
    try {
      const snapshot = await this.getDb().ref('conversations').once('value');
      
      if (!snapshot.exists()) {
        return { conversations: [], total: 0 };
      }
      
      const conversationsObj = snapshot.val();
      const userConversations = Object.entries(conversationsObj)
        .filter(
          ([, conv]) =>
            conv.user1Id === userId || conv.user2Id === userId
        )
        .map(([id, conv]) => ({ ...conv, conversationId: id }))
        .sort((a, b) => new Date(b.lastMessageAt || b.createdAt) - new Date(a.lastMessageAt || a.createdAt))
        .slice(offset, offset + limit);
      
      return {
        conversations: userConversations,
        total: Object.values(conversationsObj).filter(
          (conv) => conv.user1Id === userId || conv.user2Id === userId
        ).length,
        limit,
        offset,
      };
    } catch (error) {
      throw new Error(`Failed to fetch conversations: ${error.message}`);
    }
  }

  /**
   * Get or create a conversation
   */
  static async getOrCreateConversation(matchId, user1Id, user2Id) {
    try {
      const snapshot = await this.getDb().ref('conversations').once('value');
      
      if (snapshot.exists()) {
        const conversations = snapshot.val();
        
        for (const [convId, conv] of Object.entries(conversations)) {
          if (
            (conv.user1Id === user1Id && conv.user2Id === user2Id) ||
            (conv.user1Id === user2Id && conv.user2Id === user1Id)
          ) {
            return convId;
          }
        }
      }
      
      // Create new conversation
      const conversationId = `conv_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const now = new Date().toISOString();
      
      await this.getDb().ref(`conversations/${conversationId}`).set({
        conversationId,
        matchId,
        user1Id,
        user2Id,
        createdAt: now,
        updatedAt: now,
        isPinned: false,
        isMuted: false,
        isBlocked: false,
      });
      
      return conversationId;
    } catch (error) {
      throw new Error(`Failed to get or create conversation: ${error.message}`);
    }
  }
}

module.exports = MessageService;
