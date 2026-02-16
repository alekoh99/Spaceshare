import 'package:flutter/material.dart';
import '../../widgets/app_svg_icon.dart';
import 'package:get/get.dart';
import '../../providers/payment_controller.dart';
import '../../config/app_colors.dart';

class PaymentSplitScreen extends StatefulWidget {
  final String? paymentId;

  const PaymentSplitScreen({super.key, this.paymentId});

  @override
  State<PaymentSplitScreen> createState() => _PaymentSplitScreenState();
}

class _PaymentSplitScreenState extends State<PaymentSplitScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final selectedSplitType = 'equal'.obs;
  final paymentController = Get.find<PaymentController>();

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    if (!formKey.currentState!.validate()) return;

    final amount = double.tryParse(amountController.text) ?? 0;
    final description = descriptionController.text;
    
    // Use current payment being edited or create a new one
    final matchId = Get.arguments?['matchId'] as String? ?? 'temp_match';
    final recipientId = Get.arguments?['recipientId'] as String? ?? '';
    final currentMonth = DateTime.now().month.toString();
    
    paymentController.createPaymentSplit(
      matchId: matchId,
      recipientId: recipientId,
      totalAmount: amount,
      userAmount: amount / 2, // Equal split
      type: selectedSplitType.value,
      month: currentMonth,
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (paymentController.error.value == null) {
        Get.offNamedUntil('/payments', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBg,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEF4444), // Red
              const Color(0xFFFF6B6B), // Coral
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: AppSvgIcon.icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Split Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Enter Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Amount required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g., November rent, utilities...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Split Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Column(
                      children: [
                        _buildRadioTile('equal', 'Split Equally', '50% each'),
                        _buildRadioTile('custom', 'Custom Split', 'Specify amounts'),
                        _buildRadioTile('occupancy', 'By Occupancy', 'Based on room'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSummary(),
                  const SizedBox(height: 24),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: paymentController.isProcessing.value
                            ? null
                            : _submitPayment,
                        child: paymentController.isProcessing.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Color(0xFFEF4444)),
                                ),
                              )
                            : const Text(
                                'Confirm Payment',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => paymentController.error.value != null
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              paymentController.error.value!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioTile(String value, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: selectedSplitType.value == value
              ? Colors.green[500]!
              : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RadioListTile<String>(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600]),
        ),
        value: value,
        groupValue: selectedSplitType.value,
        activeColor: Colors.green[500],
        onChanged: (val) {
          if (val != null) selectedSplitType.value = val;
        },
      ),
    );
  }

  Widget _buildSummary() {
    final amount = double.tryParse(amountController.text) ?? 0;
    final yourAmount = selectedSplitType.value == 'equal' ? amount / 2 : amount * 0.6;
    final theirAmount = selectedSplitType.value == 'equal' ? amount / 2 : amount * 0.4;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Total', '\$${amount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _summaryRow('You Pay', '\$${yourAmount.toStringAsFixed(2)}', color: Colors.red[200]),
          const SizedBox(height: 12),
          _summaryRow('They Pay', '\$${theirAmount.toStringAsFixed(2)}', color: Colors.green[200]),
          const Divider(height: 20, color: Colors.white30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Total',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '\$${yourAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String amount, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
