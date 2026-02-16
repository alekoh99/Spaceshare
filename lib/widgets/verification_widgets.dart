import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/identity_verification_model.dart';
import '../services/identity_verification_service.dart';
import '../providers/identity_verification_controller.dart';

class TrustBadgeWidget extends StatelessWidget {
  final TrustBadge badge;

  const TrustBadgeWidget({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IdentityVerificationController>();
    final badgeInfo = controller.getTrustBadgeInfo(badge.type);

    return Tooltip(
      message: badgeInfo['label'] ?? 'Verified',
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getBadgeColor(badge.type),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconData(badgeInfo['icon'] ?? '✓'),
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              badgeInfo['label'] ?? 'Verified',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(String badgeType) {
    switch (badgeType) {
      case 'identity_verified':
        return Colors.blue;
      case 'background_checked':
        return Colors.green;
      case 'on_time_payments':
        return Colors.orange;
      case 'responsive_user':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconData(String icon) {
    switch (icon) {
      case '✓':
        return FontAwesomeIcons.circleCheck;
      case '🏢':
        return FontAwesomeIcons.userShield;
      case '💳':
        return FontAwesomeIcons.creditCard;
      case '📱':
        return FontAwesomeIcons.comments;
      default:
        return FontAwesomeIcons.shield;
    }
  }
}

class VerificationStatusCard extends StatelessWidget {
  final Map<String, dynamic> verificationStatus;
  final VoidCallback onVerifyIdentity;
  final VoidCallback onVerifyBackground;

  const VerificationStatusCard({super.key, 
    required this.verificationStatus,
    required this.onVerifyIdentity,
    required this.onVerifyBackground,
  });

  @override
  Widget build(BuildContext context) {
    final isIdentityVerified =
        verificationStatus['isIdentityVerified'] as bool? ?? false;
    final backgroundStatus =
        verificationStatus['backgroundCheckStatus'] as String?;
    final trustScore = verificationStatus['trustScore'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trust Score',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTrustScoreColor(trustScore),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$trustScore/100',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildVerificationItem(
              title: 'Identity Verification',
              isVerified: isIdentityVerified,
              onTap: onVerifyIdentity,
            ),
            SizedBox(height: 12),
            _buildVerificationItem(
              title: 'Background Check',
              isVerified: backgroundStatus == 'approved',
              status: backgroundStatus,
              onTap: onVerifyBackground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationItem({
    required String title,
    required bool isVerified,
    String? status,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isVerified ? Colors.green.withValues(alpha: 0.3) : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                if (status != null)
                  Text(
                    'Status: $status',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          if (isVerified)
            Icon(FontAwesomeIcons.circleCheck, color: Colors.green, size: 24)
          else
            ElevatedButton(
              onPressed: onTap,
              child: Text('Verify'),
            ),
        ],
      ),
    );
  }

  Color _getTrustScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class BadgesDisplayWidget extends StatelessWidget {
  final List<TrustBadge> badges;

  const BadgesDisplayWidget({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges.map((badge) => TrustBadgeWidget(badge: badge)).toList(),
    );
  }
}
