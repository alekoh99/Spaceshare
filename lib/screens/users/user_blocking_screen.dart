import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/user_management_controller.dart';
import '../../config/app_colors.dart';

class UserBlockingScreen extends StatefulWidget {
  const UserBlockingScreen({super.key});

  @override
  State<UserBlockingScreen> createState() => _UserBlockingScreenState();
}

class _UserBlockingScreenState extends State<UserBlockingScreen> {
  @override
  void initState() {
    super.initState();
    // Register controller if not already registered
    if (!Get.isRegistered<UserManagementController>()) {
      Get.put(UserManagementController());
    }
    Get.find<UserManagementController>().loadBlockedUsers();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
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
                  onPressed: () => controller.loadBlockedUsers(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.isLoadingBlocked.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.blockedUsers.isEmpty) {
          return const Center(
            child: Text(
              'No blocked users',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: controller.blockedUsers.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final userId = controller.blockedUsers[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(userId),
              subtitle: const Text('Blocked user'),
              trailing: ElevatedButton(
                onPressed: () => _showUnblockDialog(context, controller, userId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                ),
                child: const Text(
                  'Unblock',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showUnblockDialog(BuildContext context, UserManagementController controller, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User?'),
        content: Text('Are you sure you want to unblock $userId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.unblockUser(userId);
              Navigator.pop(context);
            },
            child: const Text('Unblock', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
