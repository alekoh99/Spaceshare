import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/user_management_controller.dart';
import '../../config/app_colors.dart';

class UserReputationScreen extends StatefulWidget {
  final String userId;

  const UserReputationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserReputationScreen> createState() => _UserReputationScreenState();
}

class _UserReputationScreenState extends State<UserReputationScreen> {
  @override
  void initState() {
    super.initState();
    // Register controller if not already registered
    if (!Get.isRegistered<UserManagementController>()) {
      Get.put(UserManagementController());
    }
    Get.find<UserManagementController>().loadUserReputation(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Reputation'),
        elevation: 0,
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.error.value != null && controller.error.value!.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${controller.error.value}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadUserReputation(widget.userId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.isLoadingReputation.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reputation Score Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Reputation Score',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.userReputation.value.toString(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (controller.userReputation.value / 1000).clamp(0, 1).toDouble(),
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.cyan,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'of 1000 max score',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Reputation Details
              if (controller.reputationDetails.value.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reputation Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(controller.reputationDetails.value.entries)
                        .map((entry) => _buildDetailRow(entry.key, entry.value)),
                  ],
                ),

              const SizedBox(height: 32),

              // Information Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkBg2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    top: BorderSide(color: AppColors.borderColor),
                    right: BorderSide(color: AppColors.borderColor),
                    bottom: BorderSide(color: AppColors.borderColor),
                    left: BorderSide(color: AppColors.cyan, width: 3),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Reputation Works',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your reputation score is based on your interactions and behavior on the platform. Complete transactions, positive reviews, and timely responses improve your score.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatKey(key),
            style: const TextStyle(fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.cyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .trim()
        .replaceAllMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase());
  }
}
