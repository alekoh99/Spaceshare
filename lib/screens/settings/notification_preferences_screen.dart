import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../config/app_colors.dart';
import '../../utils/logger.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late SharedPreferences _prefs;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Notification settings
  late bool _messagesEnabled;
  late bool _matchesEnabled;
  late bool _paymentsEnabled;
  late bool _remindersEnabled;
  late String _notificationFrequency;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      setState(() {
        _messagesEnabled = _prefs.getBool('notif_messages') ?? true;
        _matchesEnabled = _prefs.getBool('notif_matches') ?? true;
        _paymentsEnabled = _prefs.getBool('notif_payments') ?? false;
        _remindersEnabled = _prefs.getBool('notif_reminders') ?? true;
        _notificationFrequency = _prefs.getString('notif_frequency') ?? 'instant';
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('NOTIFICATION', 'Failed to load settings: $e');
      Get.snackbar('Error', 'Failed to load settings');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      // Sync settings using shared preferences
      await _prefs.setBool('notif_messages', _messagesEnabled);
      await _prefs.setBool('notif_matches', _matchesEnabled);
      await _prefs.setBool('notif_payments', _paymentsEnabled);
      await _prefs.setBool('notif_reminders', _remindersEnabled);
      await _prefs.setString('notif_frequency', _notificationFrequency);
      
      AppLogger.info('NOTIFICATION', 'Settings saved successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('NOTIFICATION', 'Failed to save settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(
          backgroundColor: AppColors.darkBg,
          elevation: 0,
          title: const Text(
            'Notification Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Push Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Messages Toggle
            SwitchListTile(
              tileColor: AppColors.darkBg2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text(
                'New Messages',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Get notified about new messages',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              value: _messagesEnabled,
              activeTrackColor: AppColors.cyan,
              onChanged: (value) => setState(() {
                _messagesEnabled = value;
              }),
            ),
            const SizedBox(height: 8),
            // Matches Toggle
            SwitchListTile(
              tileColor: AppColors.darkBg2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text(
                'New Matches',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Get notified about new matches',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              value: _matchesEnabled,
              activeTrackColor: AppColors.cyan,
              onChanged: (value) => setState(() {
                _matchesEnabled = value;
              }),
            ),
            const SizedBox(height: 8),
            // Payments Toggle
            SwitchListTile(
              tileColor: AppColors.darkBg2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text(
                'Payment Updates',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Get notified about payments',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              value: _paymentsEnabled,
              activeTrackColor: AppColors.cyan,
              onChanged: (value) => setState(() {
                _paymentsEnabled = value;
              }),
            ),
            const SizedBox(height: 8),
            // Reminders Toggle
            SwitchListTile(
              tileColor: AppColors.darkBg2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text(
                'Reminders',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Get reminder notifications',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              value: _remindersEnabled,
              activeTrackColor: AppColors.cyan,
              onChanged: (value) => setState(() {
                _remindersEnabled = value;
              }),
            ),
            const SizedBox(height: 24),
            const Text(
              'Notification Frequency',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkBg2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How often would you like to receive notifications?',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: _notificationFrequency,
                      isExpanded: true,
                      dropdownColor: AppColors.darkBg2,
                      style: const TextStyle(color: AppColors.textPrimary),
                      items: const [
                        DropdownMenuItem(
                          value: 'instant',
                          child: Text('Instant'),
                        ),
                        DropdownMenuItem(
                          value: 'daily',
                          child: Text('Daily'),
                        ),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Weekly'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _notificationFrequency = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
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
    );
  }
}
