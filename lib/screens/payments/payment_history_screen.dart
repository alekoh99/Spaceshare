import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/payment_controller.dart';
import '../../config/app_colors.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final paymentController = Get.find<PaymentController>();
  final selectedFilter = 'all'.obs;

  @override
  void initState() {
    super.initState();
    paymentController.loadPaymentHistory();
  }

  void _showDisputeDialog(String paymentId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'File Dispute',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.darkBg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe the issue...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            fillColor: AppColors.darkBg,
            filled: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.cyan),
            ),
          ),
          TextButton(
            onPressed: () {
              paymentController.fileDispute(
                paymentId: paymentId,
                reason: reasonController.text,
              );
              Get.back();
            },
            child: const Text(
              'File',
              style: TextStyle(color: AppColors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Payment History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(
              () => Wrap(
                spacing: 8,
                children: ['All', 'Pending', 'Completed', 'Failed']
                    .map((status) => ChoiceChip(
                          label: Text(status),
                          selected: selectedFilter.value == status.toLowerCase(),
                          onSelected: (selected) {
                            selectedFilter.value = status.toLowerCase();
                          },
                          backgroundColor: AppColors.darkBg2,
                          selectedColor: AppColors.cyan,
                          labelStyle: TextStyle(
                            color:
                                selectedFilter.value == status.toLowerCase()
                                    ? AppColors.darkBg
                                    : AppColors.textPrimary,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (paymentController.isLoadingPayments.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                );
              }

              final allPayments = paymentController.payments;
              final filtered = selectedFilter.value == 'all'
                  ? allPayments
                  : allPayments
                      .where((p) =>
                          p.status.toString().toLowerCase() ==
                          selectedFilter.value)
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'No ${selectedFilter.value} payments',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final payment = filtered[index];
                  final isCompleted = payment.status.toString() == 'completed';
                  final isFailed = payment.status.toString() == 'failed';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${payment.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? Colors.green[100]
                                      : isFailed
                                          ? Colors.red[100]
                                          : Colors.orange[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  payment.status.toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isCompleted
                                        ? Colors.green[700]
                                        : isFailed
                                            ? Colors.red[700]
                                            : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            payment.description ?? 'Payment',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            payment.createdAt.toString().split(' ')[0],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (isCompleted || isFailed)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  if (isFailed)
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange[500],
                                        ),
                                        onPressed: () {
                                          Get.toNamed('/payment-split',
                                              arguments: {
                                                'paymentId': payment.paymentId,
                                              });
                                        },
                                        child: const Text('Retry',
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ),
                                  if (isCompleted) ...[
                                    if (isFailed) const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _showDisputeDialog(payment.paymentId),
                                        child: const Text('Dispute'),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
