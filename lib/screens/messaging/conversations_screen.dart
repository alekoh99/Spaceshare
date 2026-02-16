import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/app_svg_icon.dart';
import 'package:get/get.dart';
import '../../providers/messaging_controller.dart';
import '../../services/unified_database_service.dart';
import '../../models/user_model.dart';
import '../../widgets/bottom_navigation_bar_widget.dart';
import '../../config/app_colors.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final messagingController = Get.find<MessagingController>();
  final dbService = Get.find<UnifiedDatabaseService>();
  int _currentNavIndex = 1; // Chat is index 1

  @override
  void initState() {
    super.initState();
    // Defer the call to loadConversations until after the build phase completes
    // to avoid "setState() called during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messagingController.loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.darkBg,
        child: Column(
          children: [
            // Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Obx(() {
                if (messagingController.isLoadingConversations.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                    ),
                  );
                }

                if (messagingController.conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppSvgIcon.icon(Icons.mail_outline, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        const Text(
                          'No conversations yet',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => messagingController.loadConversations(),
                  backgroundColor: AppColors.cyan,
                  color: AppColors.darkBg,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: messagingController.conversations.length,
                    itemBuilder: (context, index) {
                      final conv = messagingController.conversations[index];
                      return _buildConversationTile(conv);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: (index) {
          setState(() => _currentNavIndex = index);
        },
      ),
    );
  }

  Widget _buildConversationTile(dynamic conv) {
    return FutureBuilder<dynamic>(
      future: dbService.getProfile(conv.user2Id),
      builder: (context, snapshot) {
        String userName = 'User';
        String? userAvatar;
        
        if (snapshot.hasData) {
          try {
            final result = snapshot.data;
            if (result.isSuccess()) {
              final user = result.getOrNull() as UserProfile?;
              if (user != null) {
                userName = user.name;
                userAvatar = user.avatar;
              }
            }
          } catch (e) {
            userName = 'User';
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkBg2,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => Get.toNamed('/chat', arguments: {
              'conversationId': conv.conversationId,
              'otherUserId': conv.user2Id,
            }),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: userAvatar != null
                          ? DecorationImage(
                              image: NetworkImage(userAvatar),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: userAvatar == null
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.cyan,
                                AppColors.cyanLight,
                              ],
                            )
                          : null,
                    ),
                    child: userAvatar == null
                        ? Center(
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.cyan,
                              ),
                            ),
                            Text(
                              _formatTime(conv.updatedAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conv.lastMessage ?? 'No messages yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight:
                                      !conv.isRead ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (!conv.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cyan,
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
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dateTime.month}/${dateTime.day}';
  }
}
