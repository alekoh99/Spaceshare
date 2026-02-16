import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/logger.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late TextEditingController _subjectController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        Get.snackbar('Error', 'Could not launch URL');
      }
    } catch (e) {
      AppLogger.error('SupportScreen', 'Error launching URL', e);
      Get.snackbar('Error', 'Failed to open link');
    }
  }

  Future<void> _sendSupportEmail() async {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields');
      return;
    }

    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@spaceshare.app',
        queryParameters: {
          'subject': _subjectController.text,
          'body': _messageController.text,
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        _subjectController.clear();
        _messageController.clear();
        Get.snackbar(
          'Success',
          'Opening your email app...',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Error', 'Could not open email app');
      }
    } catch (e) {
      AppLogger.error('SupportScreen', 'Error sending email', e);
      Get.snackbar('Error', 'Failed to send email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0.5,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            _buildSectionTitle(context, 'Frequently Asked Questions'),
            SizedBox(height: AppPadding.medium),
            _buildFAQItem(
              title: 'How do I edit my profile?',
              answer:
                  'Go to your Profile tab and tap the Edit button. You can update your photo, bio, location, and budget preferences.',
            ),
            SizedBox(height: AppPadding.small),
            _buildFAQItem(
              title: 'How does matching work?',
              answer:
                  'SpaceShare uses compatibility algorithms based on your preferences, lifestyle, and budget to match you with compatible roommates.',
            ),
            SizedBox(height: AppPadding.small),
            _buildFAQItem(
              title: 'How is payment handled?',
              answer:
                  'All payments are handled securely through Stripe. We use escrow to protect both landlords and renters.',
            ),
            SizedBox(height: AppPadding.small),
            _buildFAQItem(
              title: 'What verification is required?',
              answer:
                  'We require phone verification, background checks, and identity verification for safety and trust.',
            ),
            SizedBox(height: AppPadding.small),
            _buildFAQItem(
              title: 'Can I block or report a user?',
              answer:
                  'Yes! Go to Privacy & Safety settings to block users or report inappropriate behavior.',
            ),
            SizedBox(height: AppPadding.extraLarge),

            // Contact Us Section
            _buildSectionTitle(context, 'Contact Us'),
            const SizedBox(height: 16),
            _buildContactOption(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@spaceshare.app',
              onTap: () => _launchUrl('mailto:support@spaceshare.app'),
            ),
            SizedBox(height: AppPadding.small),
            _buildContactOption(
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+1 (555) 123-4567',
              onTap: () => _launchUrl('tel:+15551234567'),
            ),
            SizedBox(height: AppPadding.small),
            _buildContactOption(
              icon: Icons.language,
              title: 'Visit Website',
              subtitle: 'www.spaceshare.app',
              onTap: () => _launchUrl('https://www.spaceshare.app'),
            ),
            SizedBox(height: AppPadding.small),
            _buildContactOption(
              icon: Icons.chat_outlined,
              title: 'Live Chat',
              subtitle: 'Available Mon-Fri 9am-5pm EST',
              onTap: () {
                Get.snackbar(
                  'Live Chat',
                  'Connecting you with an agent...',
                  backgroundColor: AppColors.cyan,
                  colorText: Colors.white,
                );
              },
            ),
            SizedBox(height: AppPadding.extraLarge),

            // Send Message Section
            _buildSectionTitle(context, 'Send us a Message'),
            SizedBox(height: AppPadding.medium),
            TextFormField(
              controller: _subjectController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Subject',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: 'What is this about?',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                prefixIcon: const Icon(Icons.subject, color: AppColors.cyan),
                filled: true,
                fillColor: AppColors.darkBg2,
              ),
            ),
            SizedBox(height: AppPadding.large),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                hintText: 'Tell us how we can help...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                prefixIcon: const Icon(Icons.message, color: AppColors.cyan),
                filled: true,
                fillColor: AppColors.darkBg2,
              ),
            ),
            SizedBox(height: AppPadding.large),
            ElevatedButton(
              onPressed: _sendSupportEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Send Message',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: AppPadding.extraLarge),

            // Additional Resources
            _buildSectionTitle(context, 'Resources'),
            SizedBox(height: AppPadding.medium),
            _buildResourceLink(
              icon: Icons.security,
              title: 'Privacy Policy',
              onTap: () => _launchUrl('https://spaceshare.app/privacy'),
            ),
            SizedBox(height: AppPadding.small),
            _buildResourceLink(
              icon: Icons.description,
              title: 'Terms of Service',
              onTap: () => _launchUrl('https://spaceshare.app/terms'),
            ),
            SizedBox(height: AppPadding.small),
            _buildResourceLink(
              icon: Icons.info_outlined,
              title: 'About SpaceShare',
              onTap: () => _launchUrl('https://spaceshare.app/about'),
            ),
            SizedBox(height: AppPadding.small),
            _buildResourceLink(
              icon: Icons.bug_report_outlined,
              title: 'Report a Bug',
              onTap: () {
                _subjectController.text = '[BUG REPORT] ';
                _messageController.text = 'Please describe the issue...';
              },
            ),
            SizedBox(height: AppPadding.extraLarge),

            // App Version
            Center(
              child: Text(
                'SpaceShare v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            SizedBox(height: AppPadding.large),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
    );
  }

  Widget _buildFAQItem({required String title, required String answer}) {
    return Card(
      color: AppColors.darkBg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              answer,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.darkBg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.cyan, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
      ),
    );
  }

  Widget _buildResourceLink({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.darkBg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.cyan),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
      ),
    );
  }
}
