import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/constants.dart';

class PreferenceInsightsWidget extends StatefulWidget {
  final List<String> successFactors;
  final String? riskFactor;
  final int matchCount;

  const PreferenceInsightsWidget({
    super.key,
    required this.successFactors,
    this.riskFactor,
    required this.matchCount,
  });

  @override
  State<PreferenceInsightsWidget> createState() =>
      _PreferenceInsightsWidgetState();
}

class _PreferenceInsightsWidgetState extends State<PreferenceInsightsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
            AppTheme.accentColor.withValues(alpha: 0.08),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(AppPadding.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                '🎯 ',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(width: AppPadding.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Based on your preferences, you love:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: AppPadding.small / 2),
                    Text(
                      'Updated from ${widget.matchCount} matches',
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
          
          SizedBox(height: AppPadding.large),
          
          // Success factors
          if (widget.successFactors.isNotEmpty) ...[
            Text(
              'Your Success Factors',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: AppPadding.medium),
            Wrap(
              spacing: AppPadding.small,
              runSpacing: AppPadding.small,
              children: widget.successFactors
                  .take(4)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final factor = entry.value;
                
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final delay = (index * 0.15).clamp(0, 1);
                    final progress = (_animationController.value - delay) / (1 - delay);
                    final animValue = progress.clamp(0, 1).toDouble();
                    
                    return Transform.scale(
                      scale: 0.7 + (animValue * 0.3),
                      child: Opacity(
                        opacity: animValue,
                        child: child,
                      ),
                    );
                  },
                  child: _buildFactorTag(factor),
                );
              }).toList(),
            ),
          ],
          
          // Risk factor
          if (widget.riskFactor != null && widget.riskFactor!.isNotEmpty) ...[
            SizedBox(height: AppPadding.large),
            Container(
              padding: EdgeInsets.all(AppPadding.medium),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '⚠️ ',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: AppPadding.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Potential Challenge',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          widget.riskFactor!,
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
            ),
          ],
          
          // Tip
          SizedBox(height: AppPadding.large),
          Container(
            padding: EdgeInsets.all(AppPadding.medium),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 ',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(width: AppPadding.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pro Tip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'The more you interact with matches, the better our AI learns about your preferences!',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorTag(String factor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withValues(alpha: 0.2),
            AppTheme.primaryColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '✨ ',
            style: TextStyle(fontSize: 12),
          ),
          Text(
            factor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
