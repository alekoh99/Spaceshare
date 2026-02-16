import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';

class ProfilePreviewCard extends StatefulWidget {
  final Match match;
  final UserProfile? userProfile;
  final VoidCallback onViewProfile;
  final VoidCallback onChat;
  final Animation<double>? animation;

  const ProfilePreviewCard({
    super.key,
    required this.match,
    this.userProfile,
    required this.onViewProfile,
    required this.onChat,
    this.animation,
  });

  @override
  State<ProfilePreviewCard> createState() => _ProfilePreviewCardState();
}

class _ProfilePreviewCardState extends State<ProfilePreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    if (_expandController.isCompleted) {
      _expandController.reverse();
    } else {
      _expandController.forward();
    }
  }

  String _getTopCompatibilityDimension() {
    final scores = [
      ('Cleanliness', widget.match.cleanlinessScore),
      ('Sleep Schedule', widget.match.sleepScheduleScore),
      ('Social Match', widget.match.socialFrequencyScore),
      ('Noise Tolerance', widget.match.noiseToleranceScore),
      ('Financial', widget.match.financialReliabilityScore),
    ];
    
    scores.sort((a, b) => b.$2.compareTo(a.$2));
    return scores.isNotEmpty ? scores.first.$1 : 'Great Match';
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.userProfile;
    final score = widget.match.compatibilityScore.toInt();
    final topDimension = _getTopCompatibilityDimension();

    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        margin: EdgeInsets.only(bottom: AppPadding.medium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.bgLighter,
              AppTheme.bgLight,
            ],
          ),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with profile image
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  if (profile?.avatar != null)
                    CachedNetworkImage(
                      imageUrl: profile!.avatar!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.bgLighter,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildImageFallback(),
                    )
                  else
                    _buildImageFallback(),
                  
                  // Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                  
                  // Top status badges
                  Positioned(
                    top: AppPadding.medium,
                    right: AppPadding.medium,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (profile?.verified == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Compatibility score - animated progress ring
                  Positioned(
                    bottom: AppPadding.medium,
                    right: AppPadding.medium,
                    child: _buildCompatibilityBadge(score),
                  ),
                ],
              ),
            ),
            
            // Content section
            Padding(
              padding: EdgeInsets.all(AppPadding.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, age, location
                  if (profile != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.name}, ${profile.age}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: AppPadding.small / 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      profile.city,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  
                  SizedBox(height: AppPadding.medium),
                  
                  // Compatibility reason
                  Container(
                    padding: EdgeInsets.all(AppPadding.medium),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(color: AppTheme.primaryColor, width: 3),
                        top: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                        right: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                        bottom: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why you match',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        SizedBox(height: AppPadding.small),
                        Text(
                          'You both value $topDimension highly',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: AppPadding.medium),
                  
                  // Score breakdown (expandable)
                  AnimatedBuilder(
                    animation: _expandController,
                    builder: (context, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Compact view
                          _buildScoreCompact(),
                          
                          // Expanded view
                          if (_expandController.value > 0)
                            Opacity(
                              opacity: _expandController.value,
                              child: Padding(
                                padding:
                                    EdgeInsets.only(top: AppPadding.medium),
                                child: _buildScoreBreakdown(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  
                  SizedBox(height: AppPadding.medium),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onChat,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: AppPadding.medium,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: AppPadding.small),
                                const Text(
                                  'Chat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppPadding.medium),
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onViewProfile,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: AppPadding.medium,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  color: AppTheme.primaryColor,
                                  size: 18,
                                ),
                                SizedBox(width: AppPadding.small),
                                const Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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

  Widget _buildImageFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.accentColor.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        color: AppTheme.primaryColor,
        size: 80,
      ),
    );
  }

  Widget _buildCompatibilityBadge(int score) {
    final color = score >= 80
        ? Colors.green
        : score >= 65
            ? Colors.orange
            : Colors.red;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 4,
            ),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'Match',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCompact() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppPadding.small,
        horizontal: AppPadding.medium,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tap to see compatibility breakdown',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          AnimatedRotation(
            turns: _expandController.value * 0.5,
            duration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.expand_more,
              size: 20,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    final scores = [
      ('Cleanliness', widget.match.cleanlinessScore),
      ('Sleep Schedule', widget.match.sleepScheduleScore),
      ('Social Match', widget.match.socialFrequencyScore),
      ('Noise Tolerance', widget.match.noiseToleranceScore),
      ('Financial', widget.match.financialReliabilityScore),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: scores
          .map((score) => _buildScoreBar(score.$1, score.$2 / 100))
          .toList(),
    );
  }

  Widget _buildScoreBar(String label, double value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                value >= 0.7
                    ? Colors.green
                    : value >= 0.5
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
