import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import '../../models/identity_verification_model.dart';
import '../../services/identity_verification_service.dart';
import '../../providers/identity_verification_controller.dart';
import '../../widgets/verification_widgets.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  late IdentityVerificationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<IdentityVerificationController>();
    controller.loadUserVerificationStatus();
    controller.loadVerificationHistory();
    controller.loadUserTrustBadges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Identity Verification',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isProcessing.value) {
          return Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verification Status
              VerificationStatusCard(
                verificationStatus: controller.verificationStatus.value,
                onVerifyIdentity: _handleStartIdentityVerification,
                onVerifyBackground: _handleStartBackgroundCheck,
              ),
              SizedBox(height: 24),

              // Trust Badges
              if (controller.userTrustBadges.value.isNotEmpty) ...[
                Text(
                  'Your Badges',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                BadgesDisplayWidget(badges: controller.userTrustBadges.value),
                SizedBox(height: 24),
              ],

              // Verification History
              if (controller.verificationHistory.isNotEmpty) ...[
                Text(
                  'Verification History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: controller.verificationHistory.length,
                  itemBuilder: (context, index) {
                    final session = controller.verificationHistory[index];
                    return _buildVerificationHistoryItem(session);
                  },
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVerificationHistoryItem(IdentityVerificationSession session) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getSessionTypeLabel(session.verificationMethod),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                _buildStatusBadge(session.status),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Created: ${_formatDateTime(session.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (session.completedAt != null)
              Text(
                'Completed: ${_formatDateTime(session.completedAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            if (session.failureReason != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Reason: ${session.failureReason}',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'failed':
        statusColor = Colors.red;
        break;
      case 'processing':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _handleStartIdentityVerification() async {
    await controller.startStripeIdentityVerification();
    // In production, would open Stripe Identity verification UI here
  }

  Future<void> _handleStartBackgroundCheck() async {
    Get.dialog(
      Dialog(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Background Check Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Text(
                'We will check your:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              _buildChecklistItem('Criminal history (7 years)'),
              _buildChecklistItem('Eviction history (10 years)'),
              _buildChecklistItem('Sex offender registry'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  _showBackgroundCheckForm();
                },
                style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
                child: Text('Start Background Check'),
              ),
              SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(50)),
                child: Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
          SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _showBackgroundCheckForm() async {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();

    Get.dialog(
      Dialog(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Background Check Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (firstNameController.text.isEmpty ||
                      lastNameController.text.isEmpty ||
                      emailController.text.isEmpty) {
                    Get.snackbar('Error', 'Please fill all fields');
                    return;
                  }

                  await controller.startBackgroundCheck(
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    email: emailController.text,
                  );

                  Get.back();
                },
                style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSessionTypeLabel(String type) {
    switch (type) {
      case 'stripe_identity':
        return 'Identity Verification';
      case 'background_check':
        return 'Background Check';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
