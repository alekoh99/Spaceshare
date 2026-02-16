import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../../models/payment_model.dart';

class PaymentItemWidget extends StatelessWidget {
  final Payment payment;
  final Function()? onRetry;
  final Function()? onDispute;

  const PaymentItemWidget({super.key, 
    required this.payment,
    this.onRetry,
    this.onDispute,
  });

  Color _getStatusColor() {
    switch (payment.status) {
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'failed':
        return AppTheme.errorColor;
      case 'disputed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    return payment.status.toString().replaceFirst(payment.status[0], payment.status[0].toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      child: Padding(
        padding: EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        Formatters.formatDate(payment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(payment.amount, payment.currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (onRetry != null || onDispute != null) ...[
              SizedBox(height: AppPadding.medium),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onRetry != null)
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  if (onDispute != null)
                    TextButton.icon(
                      onPressed: onDispute,
                      icon: const Icon(Icons.flag),
                      label: const Text('Dispute'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
