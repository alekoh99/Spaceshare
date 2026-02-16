import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../providers/matching_controller.dart';
import '../../providers/messaging_controller.dart';
import '../../widgets/app_svg_icon.dart';
import '../../services/unified_database_service.dart';

class MatchDetailScreen extends StatelessWidget {
  final Match match;

  const MatchDetailScreen({required this.match, super.key});

  @override
  Widget build(BuildContext context) {
    final matchingController = Get.find<MatchingController>();
    final messagingController = Get.find<MessagingController>();
    final dbService = Get.find<UnifiedDatabaseService>();

    return FutureBuilder<dynamic>(
      future: dbService.getProfile(match.user2Id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: AppColors.darkBg,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                color: AppColors.darkBg,
              ),
              child: const Center(
                child: Text(
                  'User not found',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
          );
        }

        final user = UserProfile.fromJson(
          snapshot.data!.data() as Map<String, dynamic>,
        );

        return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkBg2,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  matchingController.rejectMatch(match.matchId);
                  Get.back();
                },
                child: const Text(
                  'Reject',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  matchingController.acceptMatch(match.matchId);
                  
                  final currentUserId = matchingController.authController.currentUserId.value;
                  if (currentUserId != null) {
                    await messagingController.getOrCreateConversation(
                      matchId: match.matchId,
                      user1Id: currentUserId,
                      user2Id: match.user2Id,
                    );
                  }
                  Get.back();
                  Get.snackbar('Match Accepted!', 'Start chatting now!');
                },
                child: const Text(
                  'Accept',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBg,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final currentUserId = matchingController.authController.currentUserId.value;
                  if (currentUserId != null) {
                    final conversationId = await messagingController.getOrCreateConversation(
                      matchId: match.matchId,
                      user1Id: currentUserId,
                      user2Id: match.user2Id,
                    );
                    Get.toNamed('/chat', arguments: {
                      'conversationId': conversationId,
                      'otherUserId': match.user2Id,
                    });
                  }
                },
                child: AppSvgIcon.icon(Icons.message, color: AppColors.textTertiary, size: 24),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    icon: AppSvgIcon.icon(Icons.arrow_back, color: AppColors.cyan),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),

              // Profile Header with real image and data
              Container(
                width: double.infinity,
                height: 300,
                color: AppColors.darkBg2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (user.avatar != null)
                      Image.network(
                        user.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.darkBg2,
                            child: AppSvgIcon.icon(
                              Icons.person,
                              size: 100,
                              color: AppColors.textTertiary,
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: AppColors.darkBg2,
                        child: AppSvgIcon.icon(
                          Icons.person,
                          size: 100,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${match.compatibilityScore.toStringAsFixed(0)}% Match',
                          style: const TextStyle(
                            color: AppColors.darkBg,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Location
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.name}, ${user.age ?? "N/A"}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                AppSvgIcon.icon(Icons.location_on,
                                    size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  user.city ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Bio
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.bio ?? 'No bio available',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Compatibility Dimensions
                    const Text(
                      'Lifestyle Match',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildDimensionBar(
                        'Cleanliness', (match.compatibilityScore * 10).toInt()),
                    _buildDimensionBar(
                        'Noise Level', (match.compatibilityScore * 8.5).toInt()),
                    _buildDimensionBar(
                        'Social', (match.compatibilityScore * 9).toInt()),
                    _buildDimensionBar('Sleep Schedule',
                        (match.compatibilityScore * 7.5).toInt()),

                    const SizedBox(height: 32),

                    // Match Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(match.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(match.status),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
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

  Widget _buildDimensionBar(String label, dynamic value) {
    int score = 5;
    if (value is int) {
      score = value;
    } else if (value is double) {
      score = value.toInt();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$score/10',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 10,
              minHeight: 6,
              backgroundColor: AppColors.darkBg2,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.cyan;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Match Accepted';
      case 'rejected':
        return 'Match Rejected';
      default:
        return 'Pending';
    }
  }
}
