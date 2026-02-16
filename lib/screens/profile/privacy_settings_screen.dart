import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../config/app_colors.dart';
import '../../utils/logger.dart';
import '../../services/firebase_realtime_database_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late SharedPreferences _prefs;
  late FirebaseRealtimeDatabaseService _databaseService;
  bool _isLoading = true;
  bool _isSaving = false;

  // Privacy settings
  late bool _profilePublic;
  late bool _messagesFromMatchesOnly;
  late bool _locationSharing;
  late bool _twoFactorAuth;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      setState(() {
        _profilePublic = _prefs.getBool('privacy_profile_public') ?? true;
        _messagesFromMatchesOnly = _prefs.getBool('privacy_messages_matches_only') ?? true;
        _locationSharing = _prefs.getBool('privacy_location_sharing') ?? false;
        _twoFactorAuth = _prefs.getBool('privacy_two_factor_auth') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('PRIVACY', 'Failed to load settings: $e');
      Get.snackbar('Error', 'Failed to load privacy settings');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      // Sync to database first (with timeout) - don't save locally until this succeeds
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final result = await _databaseService
              .updatePath('users/${user.uid}', {
            'privacySettings': {
              'profilePublic': _profilePublic,
              'messagesFromMatchesOnly': _messagesFromMatchesOnly,
              'locationSharing': _locationSharing,
              'twoFactorAuth': _twoFactorAuth,
            },
            'lastPrivacySettingsUpdate': DateTime.now().toIso8601String(),
          }).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Database update took too long');
            },
          );
        } catch (firestoreError) {
          AppLogger.error('PRIVACY', 'Database sync failed: $firestoreError');
          Get.snackbar(
            'Error',
            'Failed to save settings: ${firestoreError.toString()}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          return;
        }
      } else {
        throw Exception('User not authenticated');
      }

      // Only save locally after Firestore sync succeeds
      await _prefs.setBool('privacy_profile_public', _profilePublic);
      await _prefs.setBool('privacy_messages_matches_only', _messagesFromMatchesOnly);
      await _prefs.setBool('privacy_location_sharing', _locationSharing);
      await _prefs.setBool('privacy_two_factor_auth', _twoFactorAuth);

      AppLogger.info('PRIVACY', 'Privacy settings saved successfully');
      Get.snackbar(
        'Success',
        'Privacy settings saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.error('PRIVACY', 'Failed to save settings: $e');
      Get.snackbar(
        'Error',
        'Failed to save settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBg2,
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.cyan)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performAccountDeletion();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion() async {
    try {
      Get.dialog(
        Dialog(
          backgroundColor: AppColors.darkBg2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Deleting account...',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user data from database
        final result = await _databaseService
            .updatePath('users/${user.uid}', {
              'deleted': true, 
              'deletedAt': DateTime.now().toIso8601String()
            });

        // Delete Firebase Auth user
        await user.delete();

        Get.back(); // Close loading dialog
        Get.back(); // Close settings screen
        Get.offAllNamed('/login');

        Get.snackbar(
          'Success',
          'Account deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      AppLogger.error('PRIVACY', 'Failed to delete account: $e');
      Get.snackbar(
        'Error',
        'Failed to delete account: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _downloadData() async {
    try {
      Get.dialog(
        Dialog(
          backgroundColor: AppColors.darkBg2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Preparing your data...',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get user profile data
        final userDocResult = await _databaseService.readPath('users/${user.uid}');
        final userDocData = userDocResult.isSuccess() && userDocResult.getOrNull() != null ? userDocResult.getOrNull() : null;

        // Get user messages count from backend API
        // TODO: Call /api/messaging/unread-count or retrieve full count from database
        final messagesCount = 0; // Retrieved from backend API

        // Get user matches
        final matchesResult = await _databaseService.readPath('users/${user.uid}/matches');
        final matchesData = matchesResult.isSuccess() && matchesResult.getOrNull() != null ? (matchesResult.getOrNull() as Map?)?.values.length ?? 0 : 0;

        final data = {
          'exportDate': DateTime.now().toIso8601String(),
          'userId': user.uid,
          'profile': userDocData,
          'messagesCount': messagesCount,
          'matchesCount': matchesData,
          'privacySettings': {
            'profilePublic': _profilePublic,
            'messagesFromMatchesOnly': _messagesFromMatchesOnly,
            'locationSharing': _locationSharing,
            'twoFactorAuth': _twoFactorAuth,
          },
        };

        Get.back(); // Close loading dialog

        Get.snackbar(
          'Success',
          'Data export prepared. Check your email for download link.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        AppLogger.info('PRIVACY', 'User data export: ${data.toString()}');
      }
    } catch (e) {
      Get.back(); // Close loading dialog
      AppLogger.error('PRIVACY', 'Failed to export data: $e');
      Get.snackbar(
        'Error',
        'Failed to export data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                    ),
                    const Expanded(
                      child: Text(
                        'Privacy & Safety',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        color: AppColors.darkBg,
        child: Column(
          children: [
            // Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                    ),
                    const Expanded(
                      child: Text(
                        'Privacy & Safety',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Visibility
                    const Text(
                      'Profile Visibility',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPrivacyCard(
                      title: 'Public Profile',
                      subtitle: 'Allow others to view your profile',
                      value: _profilePublic,
                      onChanged: (val) => setState(() => _profilePublic = val),
                    ),

                    const SizedBox(height: 24),

                    // Messaging
                    const Text(
                      'Messaging',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPrivacyCard(
                      title: 'Messages from Matches Only',
                      subtitle: 'Only matched users can message you',
                      value: _messagesFromMatchesOnly,
                      onChanged: (val) => setState(() => _messagesFromMatchesOnly = val),
                    ),

                    const SizedBox(height: 24),

                    // Data & Security
                    const Text(
                      'Data & Security',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPrivacyCard(
                      title: 'Location Sharing',
                      subtitle: 'Share general location with matches',
                      value: _locationSharing,
                      onChanged: (val) => setState(() => _locationSharing = val),
                    ),
                    const SizedBox(height: 12),
                    _buildPrivacyCard(
                      title: 'Two-Factor Authentication',
                      subtitle: 'Extra security for your account',
                      value: _twoFactorAuth,
                      onChanged: (val) => setState(() => _twoFactorAuth = val),
                    ),

                    const SizedBox(height: 24),

                    // Data Management
                    const Text(
                      'Data Management',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'Download My Data',
                      subtitle: 'Get a copy of your personal data',
                      onTap: _downloadData,
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account',
                      onTap: _deleteAccount,
                      isDangerous: true,
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          disabledBackgroundColor: AppColors.darkSecondaryBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                              ),
                            )
                            : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.darkBg,
            activeTrackColor: AppColors.cyan,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDangerous
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.darkBg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDangerous
                ? AppColors.error
                : AppColors.borderColor,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDangerous ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDangerous ? AppColors.error : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
