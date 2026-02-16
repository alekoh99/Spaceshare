import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../providers/identity_verification_controller.dart';
import './verification_widgets.dart';

class UserProfileBadgesSection extends StatelessWidget {
  final String userId;

  const UserProfileBadgesSection({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IdentityVerificationController>();

    return Obx(() {
      final badges = controller.userTrustBadges;
      final trustScore = controller.trustScore;

      if (badges.isEmpty && trustScore < 60) {
        return SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trust & Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTrustScoreColor(trustScore),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Score: $trustScore',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (badges.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges
                    .map((badge) => TrustBadgeWidget(badge: badge))
                    .toList(),
              ),
            ),
        ],
      );
    });
  }

  Color _getTrustScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class VerificationProgressIndicator extends StatelessWidget {
  const VerificationProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IdentityVerificationController>();

    return Obx(() {
      final progress = controller.getVerificationCompletionPercentage();
      final isFullyVerified = controller.isFullyVerified;

      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Verification Progress',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                ),
              ],
            ),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            if (isFullyVerified)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Fully Verified',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
