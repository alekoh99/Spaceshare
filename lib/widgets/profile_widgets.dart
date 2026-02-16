import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'common_widgets.dart';

/// Public profile card showing user info with verification badges
class PublicProfileCard extends StatefulWidget {
  final String userId;
  final String userName;
  final int compatibilityScore;
  final Map<String, dynamic> verificationStatus;
  final List<Map<String, dynamic>> trustBadges;

  const PublicProfileCard({
    super.key,
    required this.userId,
    required this.userName,
    required this.compatibilityScore,
    required this.verificationStatus,
    required this.trustBadges,
  });

  @override
  State<PublicProfileCard> createState() => _PublicProfileCardState();
}

class _PublicProfileCardState extends State<PublicProfileCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(AppPadding.medium),
      child: Padding(
        padding: EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header with avatar
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    widget.userName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: AppPadding.large),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: ${widget.userId.substring(0, 12)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppPadding.large),

            // Compatibility Score
            Container(
              padding: EdgeInsets.all(AppPadding.medium),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Compatibility',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.compatibilityScore}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppPadding.large),

            // Trust Badges
            if (widget.trustBadges.isNotEmpty) ...[
              TrustBadgesWidget(
                badges: widget.trustBadges,
                showExpiryDate: true,
              ),
              SizedBox(height: AppPadding.large),
            ],

            // Verification Status Summary
            _buildVerificationSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSummary(BuildContext context) {
    final isIdentityVerified =
        widget.verificationStatus['isIdentityVerified'] as bool? ?? false;
    final backgroundStatus =
        widget.verificationStatus['backgroundCheckStatus'] as String?;
    final trustScore = widget.verificationStatus['trustScore'] as int? ?? 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trust Score',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: trustScore / 100,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              trustScore >= 75
                  ? Colors.green
                  : trustScore >= 50
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '$trustScore/100',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),
        _buildVerificationRow(
          'Identity Verified',
          isIdentityVerified,
          Icons.verified_user,
        ),
        SizedBox(height: 8),
        _buildVerificationRow(
          'Background Checked',
          backgroundStatus == 'approved',
          Icons.security,
        ),
      ],
    );
  }

  Widget _buildVerificationRow(
    String label,
    bool isVerified,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isVerified ? Colors.green : Colors.grey[400],
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isVerified ? Colors.green : Colors.grey[600],
            fontWeight: isVerified ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Spacer(),
        Text(
          isVerified ? '✓' : '○',
          style: TextStyle(
            color: isVerified ? Colors.green : Colors.grey[400],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

/// User verification display widget for profile screens
class VerificationDisplayWidget extends StatelessWidget {
  final bool isIdentityVerified;
  final String? backgroundCheckStatus;
  final List<Map<String, dynamic>> trustBadges;
  final VoidCallback? onVerifyTap;

  const VerificationDisplayWidget({
    super.key,
    required this.isIdentityVerified,
    this.backgroundCheckStatus,
    required this.trustBadges,
    this.onVerifyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.large),
          child: Text(
            'Verification Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(height: AppPadding.medium),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVerificationItem(
                'Identity',
                isIdentityVerified,
                'Government ID verified',
                Icons.verified_user,
                Colors.blue,
              ),
              SizedBox(height: 12),
              _buildVerificationItem(
                'Background Check',
                backgroundCheckStatus == 'approved',
                backgroundCheckStatus == 'approved'
                    ? 'Background check passed'
                    : backgroundCheckStatus == null
                        ? 'Not yet checked'
                        : 'Background check pending',
                Icons.security,
                Colors.green,
              ),
            ],
          ),
        ),
        if (trustBadges.isNotEmpty) ...[
          SizedBox(height: AppPadding.large),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppPadding.large),
            child: TrustBadgesWidget(
              badges: trustBadges,
              showExpiryDate: true,
            ),
          ),
        ],
        if (!isIdentityVerified && onVerifyTap != null) ...[
          SizedBox(height: AppPadding.large),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppPadding.large),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onVerifyTap,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppPadding.medium),
                ),
                child: Text('Get Verified'),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationItem(
    String title,
    bool isVerified,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        border: Border.all(
          color: isVerified ? color : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isVerified ? color.withValues(alpha: 0.05) : Colors.transparent,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isVerified ? color : Colors.grey[400],
            size: 24,
          ),
          SizedBox(width: AppPadding.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isVerified)
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            )
          else
            Icon(
              Icons.pending,
              color: Colors.grey[400],
              size: 20,
            ),
        ],
      ),
    );
  }
}
