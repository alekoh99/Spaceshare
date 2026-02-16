import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final settings = {
    'messages': true,
    'matches': true,
    'payments': false,
    'reminders': true,
  };
  
  String _selectedFrequency = 'instant';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('New Messages'),
              subtitle: const Text('Get notified about new messages'),
              value: settings['messages'] ?? false,
              onChanged: (value) => setState(() {
                settings['messages'] = value;
              }),
            ),
            SwitchListTile(
              title: const Text('New Matches'),
              subtitle: const Text('Get notified about new matches'),
              value: settings['matches'] ?? false,
              onChanged: (value) => setState(() {
                settings['matches'] = value;
              }),
            ),
            SwitchListTile(
              title: const Text('Payment Updates'),
              subtitle: const Text('Get notified about payments'),
              value: settings['payments'] ?? false,
              onChanged: (value) => setState(() {
                settings['payments'] = value;
              }),
            ),
            SwitchListTile(
              title: const Text('Reminders'),
              subtitle: const Text('Get reminder notifications'),
              value: settings['reminders'] ?? false,
              onChanged: (value) => setState(() {
                settings['reminders'] = value;
              }),
            ),
            const SizedBox(height: 24),
            const Text(
              'Notification Frequency',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'How often would you like to receive notifications?',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: _selectedFrequency,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: 'instant', child: Text('Instant')),
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(
                            value: 'weekly', child: Text('Weekly')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedFrequency = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
