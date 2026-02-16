import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/animation_utils.dart';

class MatchStatsDashboard extends StatefulWidget {
  final int totalMatches;
  final int acceptedMatches;
  final int activeConversations;
  final double profileCompletion;
  final VoidCallback? onProfileEdit;

  const MatchStatsDashboard({
    super.key,
    required this.totalMatches,
    required this.acceptedMatches,
    required this.activeConversations,
    required this.profileCompletion,
    this.onProfileEdit,
  });

  @override
  State<MatchStatsDashboard> createState() => _MatchStatsDashboardState();
}

class _MatchStatsDashboardState extends State<MatchStatsDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppPadding.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.08),
            AppTheme.accentColor.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '📊 ',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Your Stats',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppPadding.small / 2),
                  Text(
                    'Track your SpaceShare success',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FontAwesomeIcons.arrowTrendUp,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppPadding.large),
          
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppPadding.medium,
            mainAxisSpacing: AppPadding.medium,
            children: [
              _buildStatCard(
                icon: FontAwesomeIcons.heart,
                label: 'Total Matches',
                value: widget.totalMatches.toString(),
                subtitle: 'profiles matched',
                colors: [Colors.red.shade400, Colors.pink.shade600],
                index: 0,
              ),
              _buildStatCard(
                icon: FontAwesomeIcons.circleCheck,
                label: 'Accepted',
                value: widget.acceptedMatches.toString(),
                subtitle: 'mutual matches',
                colors: [Colors.green.shade400, Colors.green.shade700],
                index: 1,
              ),
              _buildStatCard(
                icon: FontAwesomeIcons.comment,
                label: 'Conversations',
                value: widget.activeConversations.toString(),
                subtitle: 'active chats',
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                index: 2,
              ),
              _buildStatCard(
                icon: FontAwesomeIcons.user,
                label: 'Profile',
                value: '${widget.profileCompletion.toStringAsFixed(0)}%',
                subtitle: 'complete',
                colors: [Colors.purple.shade400, Colors.purple.shade700],
                index: 3,
              ),
            ],
          ),
          
          SizedBox(height: AppPadding.large),
          
          // Profile completion bar (if not 100%)
          if (widget.profileCompletion < 100)
            _buildProfileCompletionPrompt()
          else
            _buildProfileCompleteMessage(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required List<Color> colors,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Stagger the animation for each card
        final delay = (index * 0.1).clamp(0, 1);
        final progress = (_animationController.value - delay) / (1 - delay);
        final value = progress.clamp(0, 1).toDouble();
        
        return Transform.scale(
          scale: 0.8 + (value * 0.2),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors[0].withValues(alpha: 0.15),
              colors[1].withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: colors[0].withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppPadding.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedCounter(
                    end: int.parse(value.replaceAll('%', '')),
                    duration: const Duration(milliseconds: 1200),
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppPadding.small / 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCompletionPrompt() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade50,
            Colors.amber.shade50,
          ],
        ),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(AppPadding.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '⚡ ',
                style: TextStyle(fontSize: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Get better matches with a complete profile',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.medium),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: widget.profileCompletion / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.orange.shade600,
              ),
            ),
          ),
          SizedBox(height: AppPadding.medium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onProfileEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                padding: EdgeInsets.symmetric(
                  vertical: AppPadding.medium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Complete Now',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompleteMessage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.green.shade100,
          ],
        ),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(AppPadding.medium),
      child: Row(
        children: [
          const Text(
            '✅ ',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(width: AppPadding.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Complete!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'You\'re all set to find great matches',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.check,
              size: 16,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
