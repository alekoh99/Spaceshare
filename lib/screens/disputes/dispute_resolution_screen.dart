import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/dispute_resolution_controller.dart';
import '../../config/app_colors.dart';

class DisputeResolutionScreen extends StatefulWidget {
  const DisputeResolutionScreen({super.key});

  @override
  State<DisputeResolutionScreen> createState() =>
      _DisputeResolutionScreenState();
}

class _DisputeResolutionScreenState extends State<DisputeResolutionScreen> {
  final _reasonController = TextEditingController();
  final _paymentIdController = TextEditingController();
  final _evidenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<DisputeResolutionController>()) {
      Get.put(DisputeResolutionController());
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _paymentIdController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DisputeResolutionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Resolution'),
        elevation: 0,
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.currentDispute.value == null ||
            controller.currentDispute.value!.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Dispute',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (controller.error.value != null &&
                    controller.error.value!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      controller.error.value!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _paymentIdController,
                  decoration: InputDecoration(
                    labelText: 'Payment ID',
                    hintText: 'Enter the payment ID for this dispute',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Explain the reason for this dispute',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isCreatingDispute.value
                        ? null
                        : () async {
                            if (_paymentIdController.text.isEmpty ||
                                _reasonController.text.isEmpty) {
                              controller.error.value =
                                  'Please fill in all fields';
                              return;
                            }

                            final disputeId =
                                await controller.createDispute(
                              paymentId: _paymentIdController.text,
                              reason: _reasonController.text,
                            );

                            if (disputeId != null) {
                              _paymentIdController.clear();
                              _reasonController.clear();
                              controller.loadDispute(disputeId);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: controller.isCreatingDispute.value
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Create Dispute',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }

        final dispute = controller.currentDispute.value!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dispute Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDisputeCard(dispute),
              const SizedBox(height: 24),
              const Text(
                'Submit Evidence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _evidenceController,
                decoration: InputDecoration(
                  labelText: 'Evidence',
                  hintText: 'Describe your evidence',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isSubmittingEvidence.value
                      ? null
                      : () async {
                          if (_evidenceController.text.isEmpty) {
                            controller.error.value =
                                'Please provide evidence';
                            return;
                          }

                          await controller.submitEvidence(
                            dispute['disputeId'],
                            _evidenceController.text,
                          );

                          if (controller.error.value == null) {
                            _evidenceController.clear();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: controller.isSubmittingEvidence.value
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Submit Evidence',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> dispute) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(dispute['status']).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (dispute['status'] as String? ?? 'Unknown')
                        .toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(dispute['status']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dispute ID',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  dispute['disputeId'] as String? ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment ID',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  dispute['paymentId'] as String? ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Reason',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              dispute['reason'] as String? ?? 'No reason provided',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
