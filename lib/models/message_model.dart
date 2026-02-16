
/// Message Model - Pre and post-match messaging
class Message {
  final String messageId;
  final String senderId;
  final String recipientId;
  final String matchId; // Reference to the match
  final String text;
  final DateTime sentAt;
  final DateTime? readAt;
  final bool isRead;
  
  // Message metadata
  final String type; // 'text', 'image', 'system'
  final String? imageUrl; // If type is 'image'
  final String? systemMessage; // If type is 'system' (e.g., "Match accepted")
  
  // New features
  final String? editedText; // Original text if edited
  final DateTime? editedAt; // When message was last edited
  final Map<String, String> reactions; // userId: emoji reactions
  final String? quotedMessageId; // ID of quoted message
  final String? quotedMessageText; // Text of quoted message
  final String status; // 'sending', 'sent', 'delivered', 'read', 'failed'
  final int? expiresIn; // milliseconds until auto-delete
  final bool isDeleted; // flag for deleted messages

  Message({
    required this.messageId,
    required this.senderId,
    required this.recipientId,
    required this.matchId,
    required this.text,
    required this.sentAt,
    this.readAt,
    this.isRead = false,
    this.type = 'text',
    this.imageUrl,
    this.systemMessage,
    this.editedText,
    this.editedAt,
    this.reactions = const {},
    this.quotedMessageId,
    this.quotedMessageText,
    this.status = 'sent',
    this.expiresIn,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'recipientId': recipientId,
      'matchId': matchId,
      'text': text,
      'sentAt': sentAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'imageUrl': imageUrl,
      'systemMessage': systemMessage,
      'editedText': editedText,
      'editedAt': editedAt?.toIso8601String(),
      'reactions': reactions,
      'quotedMessageId': quotedMessageId,
      'quotedMessageText': quotedMessageText,
      'status': status,
      'expiresIn': expiresIn,
      'isDeleted': isDeleted,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      matchId: json['matchId'] as String,
      text: json['text'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      readAt:
          json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      isRead: json['isRead'] as bool? ?? false,
      type: json['type'] as String? ?? 'text',
      imageUrl: json['imageUrl'] as String?,
      systemMessage: json['systemMessage'] as String?,
      editedText: json['editedText'] as String?,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt'] as String) : null,
      reactions: Map<String, String>.from(json['reactions'] ?? {}),
      quotedMessageId: json['quotedMessageId'] as String?,
      quotedMessageText: json['quotedMessageText'] as String?,
      status: json['status'] as String? ?? 'sent',
      expiresIn: json['expiresIn'] as int?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Message copyWith({
    DateTime? readAt,
    bool? isRead,
    String? editedText,
    DateTime? editedAt,
    Map<String, String>? reactions,
    String? status,
    bool? isDeleted,
  }) {
    return Message(
      messageId: messageId,
      senderId: senderId,
      recipientId: recipientId,
      matchId: matchId,
      text: text,
      sentAt: sentAt,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
      type: type,
      imageUrl: imageUrl,
      systemMessage: systemMessage,
      editedText: editedText ?? this.editedText,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? this.reactions,
      quotedMessageId: quotedMessageId,
      quotedMessageText: quotedMessageText,
      status: status ?? this.status,
      expiresIn: expiresIn,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Chat Conversation Model - Summary of a conversation between two users
class Conversation {
  final String conversationId;
  final String user1Id;
  final String user2Id;
  final String matchId;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final DateTime? updatedAt;
  final int unreadCount;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final bool isRead;
  final bool isPinned;
  final bool isMuted;
  final bool isBlocked;

  Conversation({
    required this.conversationId,
    required this.user1Id,
    required this.user2Id,
    required this.matchId,
    required this.createdAt,
    this.lastMessageAt,
    this.updatedAt,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageSenderId,
    this.isRead = false,
    this.isPinned = false,
    this.isMuted = false,
    this.isBlocked = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'matchId': matchId,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'unreadCount': unreadCount,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'isRead': isRead,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'isBlocked': isBlocked,
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'] as String,
      user1Id: json['user1Id'] as String,
      user2Id: json['user2Id'] as String,
      matchId: json['matchId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessage: json['lastMessage'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
    );
  }

  Conversation copyWith({
    DateTime? lastMessageAt,
    DateTime? updatedAt,
    int? unreadCount,
    String? lastMessage,
    String? lastMessageSenderId,
    bool? isRead,
    bool? isPinned,
    bool? isMuted,
    bool? isBlocked,
  }) {
    return Conversation(
      conversationId: conversationId,
      user1Id: user1Id,
      user2Id: user2Id,
      matchId: matchId,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      isRead: isRead ?? this.isRead,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
