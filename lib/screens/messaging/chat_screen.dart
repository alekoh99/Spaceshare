import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import '../../providers/messaging_controller.dart';
import '../../services/unified_database_service.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../widgets/typing_indicator_widget.dart';
import '../../widgets/message_reaction_widget.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late TextEditingController messageController;
  late ScrollController scrollController;
  final messagingController = Get.find<MessagingController>();
  final dbService = Get.find<UnifiedDatabaseService>();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    scrollController = ScrollController();
    // Defer the call to loadMessages until after the build phase completes
    // to avoid "setState() called during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messagingController.loadMessages(widget.conversationId);
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (messageController.text.trim().isEmpty) return;

    final text = messageController.text.trim();
    messageController.clear();

    messagingController.sendMessage(text);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showReactionPicker(String messageId) {
    final emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Reaction',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      messagingController.addReaction(messageId, emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.darkBg3,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessageOptions(Message message) {
    final isCurrentUser = message.senderId == messagingController.authController.currentUserId.value;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.emoji_emotions, color: AppColors.cyan),
                title: const Text(
                  'Add Reaction',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReactionPicker(message.messageId);
                },
              ),
              if (isCurrentUser) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.cyan),
                  title: const Text(
                    'Edit Message',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    messageController.text = message.text;
                    messagingController.editingMessageId.value = message.messageId;
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    messagingController.deleteMessage(message.messageId);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.cyan),
                title: const Text(
                  'Copy Text',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  // Copy to clipboard
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.darkBg,
        child: Column(
          children: [
            // Header with user info (Telegram style)
            SafeArea(
              child: FutureBuilder<dynamic>(
                future: dbService.getProfile(widget.otherUserId),
                builder: (context, snapshot) {
                  String displayName = 'User';
                  String? userAvatar;
                  
                  if (snapshot.hasData) {
                    try {
                      final result = snapshot.data;
                      if (result.isSuccess()) {
                        final user = result.getOrNull() as UserProfile?;
                        if (user != null) {
                          displayName = user.name;
                          userAvatar = user.avatar;
                        }
                      }
                    } catch (e) {
                      displayName = 'User';
                    }
                  }
                  
                  return Container(
                    color: AppColors.darkBg2,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/fontawesome-free-7.1.0-web/svgs/solid/arrow-left.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(AppColors.cyan, BlendMode.srcIn),
                          ),
                          onPressed: () => Get.back(),
                        ),
                        // User avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.darkBg3,
                            image: userAvatar != null && userAvatar.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(userAvatar),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: userAvatar == null || userAvatar.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.cyan,
                                  size: 20,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        // User name and status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Active now',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: AppColors.cyan, size: 20),
                          onPressed: () {
                            setState(() {
                              isSearching = !isSearching;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert, color: AppColors.cyan, size: 20),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Messages (Telegram style)
            Expanded(
              child: Obx(() {
                final messages = messagingController.currentMessages;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start the conversation!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(
                      scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isCurrentUser =
                        msg.senderId == messagingController.authController.currentUserId.value;
                    final nextMsg = index < messages.length - 1 ? messages[index + 1] : null;
                    final showTimestamp = nextMsg == null || 
                        _shouldShowTimestamp(msg.sentAt, nextMsg.sentAt);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        crossAxisAlignment: isCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onLongPress: () => _showMessageOptions(msg),
                            child: Align(
                              alignment: isCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                margin: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? AppColors.cyan
                                      : AppColors.darkBg3,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
                                    bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (msg.editedAt != null)
                                      Text(
                                        '(edited)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isCurrentUser
                                              ? AppColors.textPrimary.withValues(alpha: 0.6)
                                              : AppColors.cyan,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    Text(
                                      msg.text,
                                      style: TextStyle(
                                        color: isCurrentUser
                                            ? AppColors.textPrimary
                                            : AppColors.textPrimary,
                                        fontSize: 15,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Timestamp and read status
                          if (showTimestamp)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisAlignment: isCurrentUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTime(msg.sentAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (isCurrentUser) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      msg.isRead ? '✓✓' : '✓',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: msg.isRead
                                            ? AppColors.cyan
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          // Reactions
                          if (msg.reactions.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                left: isCurrentUser ? 0 : 24,
                                right: isCurrentUser ? 24 : 0,
                                top: 4,
                              ),
                              child: MessageReactionWidget(message: msg),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            // Typing indicator
            Obx(() {
              final typingUsers = messagingController.typingUsers.entries
                  .where((e) => e.value)
                  .map((e) => e.key)
                  .toList();
              if (typingUsers.isEmpty) {
                return const SizedBox.shrink();
              }
              return TypingIndicatorWidget(typingUserNames: typingUsers);
            }),
            // Message input area (Telegram style)
            Container(
              color: AppColors.darkBg,
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit indicator
                  if (messagingController.editingMessageId.value != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.darkBg2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cyan, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '↺ Editing message',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              messagingController.editingMessageId.value = null;
                              messageController.clear();
                            },
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Input field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: AppColors.darkBg2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.cyan,
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            'assets/fontawesome-free-7.1.0-web/svgs/solid/paper-plane.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              AppColors.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowTimestamp(DateTime current, DateTime next) {
    // Show timestamp if more than 5 minutes apart
    return next.difference(current).inMinutes > 5;
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (msgDate == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    }
    return '${dateTime.month}/${dateTime.day}';
  }
}

