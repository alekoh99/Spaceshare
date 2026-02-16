import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/constants.dart';

class TrustBadge {
  final String badgeId;
  final String name;
  final String description;
  final String iconAsset;
  final Color color;
  final int verificationLevel; // 1-5

  TrustBadge({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.color,
    required this.verificationLevel,
  });
}

class TrustBadgeWidget extends StatelessWidget {
  final String badgeName;
  final Color badgeColor;
  final String? tooltipText;
  final double size;

  const TrustBadgeWidget({
    required this.badgeName,
    required this.badgeColor,
    this.tooltipText,
    this.size = 24.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        border: Border.all(color: badgeColor, width: 1.5),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Icon(
          _getBadgeIcon(badgeName),
          color: badgeColor,
          size: size * 0.6,
        ),
      ),
    );

    if (tooltipText != null) {
      return Tooltip(
        message: tooltipText,
        child: badge,
      );
    }

    return badge;
  }

  IconData _getBadgeIcon(String badgeName) {
    switch (badgeName) {
      case 'identity_verified':
        return FontAwesomeIcons.userShield;
      case 'payment_reliable':
        return FontAwesomeIcons.creditCard;
      case 'responsive':
        return FontAwesomeIcons.comments;
      case 'background_checked':
        return FontAwesomeIcons.shieldHalved;
      case 'premium_member':
        return FontAwesomeIcons.star;
      default:
        return FontAwesomeIcons.shield;
    }
  }
}

class TrustBadgesRow extends StatelessWidget {
  final List<String> badgeIds;
  final double spacing;
  final bool horizontal;

  const TrustBadgesRow({
    required this.badgeIds,
    this.spacing = 8.0,
    this.horizontal = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (badgeIds.isEmpty) {
      return SizedBox.shrink();
    }

    final badges = badgeIds
        .map((id) => TrustBadgeWidget(
          badgeName: id,
          badgeColor: _getBadgeColor(id),
          tooltipText: _getBadgeLabel(id),
          size: 28.0,
        ))
        .toList();

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < badges.length; i++) ...[
            badges[i],
            if (i < badges.length - 1) SizedBox(width: spacing),
          ]
        ],
      );
    } else {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: badges,
      );
    }
  }

  Color _getBadgeColor(String badgeId) {
    switch (badgeId) {
      case 'identity_verified':
        return Colors.blue;
      case 'payment_reliable':
        return Colors.green;
      case 'responsive':
        return Colors.purple;
      case 'background_checked':
        return Colors.orange;
      case 'premium_member':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getBadgeLabel(String badgeId) {
    switch (badgeId) {
      case 'identity_verified':
        return 'Identity Verified';
      case 'payment_reliable':
        return 'Reliable Payer';
      case 'responsive':
        return 'Responsive';
      case 'background_checked':
        return 'Background Checked';
      case 'premium_member':
        return 'Premium Member';
      default:
        return 'Verified';
    }
  }
}

class TrustScoreDisplay extends StatelessWidget {
  final int trustScore;
  final bool showPercentage;
  final TextStyle? textStyle;

  const TrustScoreDisplay({
    required this.trustScore,
    this.showPercentage = true,
    this.textStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final score = trustScore.clamp(0, 100);
    final color = _getScoreColor(score);
    final label = _getScoreLabel(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              showPercentage ? '$score%' : score.toString(),
              style: textStyle ??
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        SizedBox(height: AppPadding.small),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.amber;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }
}

class TrustProfileSummary extends StatelessWidget {
  final int trustScore;
  final List<String> badges;
  final double? responseTimeMinutes;
  final int? matchCount;

  const TrustProfileSummary({
    required this.trustScore,
    required this.badges,
    this.responseTimeMinutes,
    this.matchCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TrustScoreDisplay(trustScore: trustScore),
                ),
                SizedBox(width: AppPadding.large),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trust Profile',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppPadding.medium),
                      if (badges.isNotEmpty) ...[
                        Text(
                          'Verified Badges',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        SizedBox(height: AppPadding.small),
                        TrustBadgesRow(
                          badgeIds: badges,
                          horizontal: false,
                          spacing: 6.0,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (responseTimeMinutes != null || matchCount != null) ...[
              SizedBox(height: AppPadding.large),
              Divider(),
              SizedBox(height: AppPadding.medium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (responseTimeMinutes != null)
                    Column(
                      children: [
                        Text(
                          _formatResponseTime(responseTimeMinutes!),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Avg Response',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  if (matchCount != null)
                    Column(
                      children: [
                        Text(
                          matchCount.toString(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Successful Matches',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatResponseTime(double minutes) {
    if (minutes < 1) return '< 1m';
    if (minutes < 60) return '${minutes.toStringAsFixed(0)}m';
    if (minutes < 1440) {
      return '${(minutes / 60).toStringAsFixed(1)}h';
    }
    return '${(minutes / 1440).toStringAsFixed(1)}d';
  }
}
