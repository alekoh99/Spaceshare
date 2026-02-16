import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ResponseTimeIndicator extends StatelessWidget {
  final double avgResponseTimeMinutes;
  final bool showLabel;
  final TextStyle? textStyle;

  const ResponseTimeIndicator({
    required this.avgResponseTimeMinutes,
    this.showLabel = true,
    this.textStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final responseStatus = _getResponseStatus();
    final statusColor = _getStatusColor(responseStatus);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          SizedBox(width: AppPadding.small),
          Text(
            _getResponseLabel(),
            style: textStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]
      ],
    );
  }

  String _getResponseStatus() {
    if (avgResponseTimeMinutes < 5) return 'instant';
    if (avgResponseTimeMinutes < 60) return 'fast';
    if (avgResponseTimeMinutes < 1440) return 'moderate'; // 24 hours
    return 'slow';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'instant':
        return Colors.green;
      case 'fast':
        return Colors.lightGreen;
      case 'moderate':
        return Colors.orange;
      case 'slow':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getResponseLabel() {
    if (avgResponseTimeMinutes < 5) return 'Instant';
    if (avgResponseTimeMinutes < 60) {
      final mins = avgResponseTimeMinutes.toStringAsFixed(0);
      return '${mins}m';
    }
    if (avgResponseTimeMinutes < 1440) {
      final hours = (avgResponseTimeMinutes / 60).toStringAsFixed(1);
      return '${hours}h';
    }
    final days = (avgResponseTimeMinutes / 1440).toStringAsFixed(1);
    return '${days}d';
  }
}

class ResponseTimeProfileCard extends StatelessWidget {
  final String userId;
  final double avgResponseTimeMinutes;
  final double responseRate;

  const ResponseTimeProfileCard({
    required this.userId,
    required this.avgResponseTimeMinutes,
    required this.responseRate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Response Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ResponseTimeIndicator(
                  avgResponseTimeMinutes: avgResponseTimeMinutes,
                  showLabel: true,
                ),
              ],
            ),
            SizedBox(height: AppPadding.medium),
            _buildMetricRow(
              'Average Response',
              _formatResponseTime(avgResponseTimeMinutes),
              context,
            ),
            SizedBox(height: AppPadding.small),
            _buildMetricRow(
              'Response Rate',
              '${responseRate.toStringAsFixed(1)}%',
              context,
            ),
            SizedBox(height: AppPadding.medium),
            _buildReliabilityBadge(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReliabilityBadge(BuildContext context) {
    String badge;
    Color badgeColor;

    if (responseRate >= 90 && avgResponseTimeMinutes < 60) {
      badge = '⭐ Highly Responsive';
      badgeColor = Colors.green.withValues(alpha: 0.1);
    } else if (responseRate >= 70 && avgResponseTimeMinutes < 1440) {
      badge = '✓ Responsive';
      badgeColor = Colors.lightGreen.withValues(alpha: 0.1);
    } else if (responseRate >= 50) {
      badge = '~ Moderately Responsive';
      badgeColor = Colors.orange.withValues(alpha: 0.1);
    } else {
      badge = '✗ Slow to Respond';
      badgeColor = Colors.red.withValues(alpha: 0.1);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.medium,
        vertical: AppPadding.small,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        badge,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatResponseTime(double minutes) {
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '${minutes.toStringAsFixed(0)} min';
    if (minutes < 1440) {
      final hours = (minutes / 60).toStringAsFixed(1);
      return '${hours}h';
    }
    final days = (minutes / 1440).toStringAsFixed(1);
    return '$days days';
  }
}

class ResponseTimeListItem extends StatelessWidget {
  final String userName;
  final double avgResponseTimeMinutes;
  final double responseRate;
  final VoidCallback? onTap;

  const ResponseTimeListItem({
    required this.userName,
    required this.avgResponseTimeMinutes,
    required this.responseRate,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(userName),
      subtitle: Text(
        'Response Rate: ${responseRate.toStringAsFixed(0)}%',
      ),
      trailing: ResponseTimeIndicator(
        avgResponseTimeMinutes: avgResponseTimeMinutes,
        showLabel: true,
      ),
      onTap: onTap,
    );
  }
}
