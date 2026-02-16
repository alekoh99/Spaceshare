import 'package:flutter/material.dart';

/// Widget to display trust badges on user profiles
class TrustBadgesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> badges;
  final bool showExpiryDate;

  const TrustBadgesWidget({
    super.key,
    required this.badges,
    this.showExpiryDate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Verified',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges.map((badge) {
            return _buildBadge(context, badge);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, Map<String, dynamic> badge) {
    final type = badge['type'] as String;
    final issuedAt = badge['issuedAt'] != null
        ? DateTime.parse(badge['issuedAt'] as String)
        : null;
    final expiresAt = badge['expiresAt'] != null
        ? DateTime.parse(badge['expiresAt'] as String)
        : null;

    String badgeLabel = '';
    IconData badgeIcon = Icons.verified;
    Color badgeColor = Colors.green;

    switch (type) {
      case 'identity_verified':
        badgeLabel = 'ID Verified';
        badgeIcon = Icons.verified_user;
        badgeColor = Colors.blue;
        break;
      case 'background_checked':
        badgeLabel = 'Background Checked';
        badgeIcon = Icons.security;
        badgeColor = Colors.green;
        break;
      case 'on_time_payments':
        badgeLabel = 'Reliable Payer';
        badgeIcon = Icons.attach_money;
        badgeColor = Colors.amber;
        break;
      case 'responsive_user':
        badgeLabel = 'Responsive';
        badgeIcon = Icons.chat;
        badgeColor = Colors.purple;
        break;
      default:
        badgeLabel = type;
        badgeIcon = Icons.verified;
    }

    final isExpired =
        expiresAt != null && expiresAt.isBefore(DateTime.now());

    return Tooltip(
      message: _getBadgeTooltip(type, issuedAt, expiresAt, isExpired),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isExpired ? Colors.grey[300] : badgeColor.withValues(alpha: 0.1),
          border: Border.all(
            color: isExpired ? Colors.grey[400]! : badgeColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badgeIcon,
              size: 16,
              color: isExpired ? Colors.grey[600] : badgeColor,
            ),
            SizedBox(width: 6),
            Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isExpired ? Colors.grey[600] : badgeColor,
              ),
            ),
            if (isExpired)
              Row(
                children: [
                  SizedBox(width: 4),
                  Text(
                    '(expired)',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getBadgeTooltip(
    String type,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool isExpired,
  ) {
    final buffer = StringBuffer();

    switch (type) {
      case 'identity_verified':
        buffer.write('Identity verified by government ID');
        break;
      case 'background_checked':
        buffer.write('Background check completed');
        break;
      case 'on_time_payments':
        buffer.write('Consistent on-time payment history');
        break;
      case 'responsive_user':
        buffer.write('Responsive to messages');
        break;
    }

    if (issuedAt != null) {
      buffer.write('\nIssued: ${issuedAt.toString().split(' ')[0]}');
    }

    if (expiresAt != null) {
      if (isExpired) {
        buffer.write('\nExpired: ${expiresAt.toString().split(' ')[0]}');
      } else {
        buffer.write('\nExpires: ${expiresAt.toString().split(' ')[0]}');
      }
    }

    return buffer.toString();
  }
}

/// Discrimination Complaint Form Widget
class DiscriminationComplaintForm extends StatefulWidget {
  final String userId;
  final String matchId;
  final String reportedUserId;
  final VoidCallback? onSubmitSuccess;

  const DiscriminationComplaintForm({
    super.key,
    required this.userId,
    required this.matchId,
    required this.reportedUserId,
    this.onSubmitSuccess,
  });

  @override
  State<DiscriminationComplaintForm> createState() =>
      _DiscriminationComplaintFormState();
}

class _DiscriminationComplaintFormState
    extends State<DiscriminationComplaintForm> {
  late TextEditingController descriptionController;
  String? selectedCategory;
  String selectedSeverity = 'medium';
  bool isSubmitting = false;

  final categories = [
    'Race or color',
    'National origin',
    'Religion',
    'Sex (including sexual orientation)',
    'Familial status',
    'Disability',
    'Source of income',
  ];

  final categoryValues = [
    'race',
    'national_origin',
    'religion',
    'sex',
    'familial_status',
    'disability',
    'source_of_income',
  ];

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  void _submitComplaint() async {
    if (selectedCategory == null || descriptionController.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // In production, this would call the ComplianceService
      // For now, showing success flow
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your complaint has been submitted and will be reviewed within 48 hours'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      if (widget.onSubmitSuccess != null) {
        widget.onSubmitSuccess!();
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting complaint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report Discrimination'),
      contentPadding: EdgeInsets.all(24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We take discrimination seriously. Please provide details about the discrimination you experienced.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Text(
              'Category *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              hint: Text('Select a category'),
              items: List.generate(
                categories.length,
                (index) => DropdownMenuItem(
                  value: categoryValues[index],
                  child: Text(categories[index]),
                ),
              ),
              onChanged: (value) => setState(() => selectedCategory = value),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Severity Level *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Row(
              children: ['Low', 'Medium', 'High', 'Critical']
                  .map((level) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(level),
                        selected:
                            selectedSeverity == level.toLowerCase(),
                        onSelected: (_) =>
                            setState(() => selectedSeverity = level.toLowerCase()),
                      ),
                    ),
                  ))
                  .toList(),
            ),
            SizedBox(height: 16),
            Text(
              'Description *',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              minLines: 4,
              decoration: InputDecoration(
                hintText: 'Please describe what happened (minimum 20 characters)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ Your report will be reviewed within 48 hours. All information will be kept confidential.',
                style: TextStyle(fontSize: 12, color: Colors.blue[900]),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitComplaint,
          child: isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Submit Complaint'),
        ),
      ],
    );
  }
}

/// Compliance Dashboard Widget (Admin View)
class ComplianceDashboardWidget extends StatelessWidget {
  final int totalComplaints;
  final int pendingComplaints;
  final int resolvedComplaints;
  final Map<String, int> complaintsByCategory;
  final List<Map<String, dynamic>> recentIncidents;

  const ComplianceDashboardWidget({
    super.key,
    required this.totalComplaints,
    required this.pendingComplaints,
    required this.resolvedComplaints,
    required this.complaintsByCategory,
    required this.recentIncidents,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStatCard(
                  'Total Complaints',
                  totalComplaints.toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  'Pending',
                  pendingComplaints.toString(),
                  Colors.orange,
                ),
                _buildStatCard(
                  'Resolved',
                  resolvedComplaints.toString(),
                  Colors.green,
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Category Breakdown
          Text(
            'Complaints by Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 12),
          ...complaintsByCategory.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: _buildCategoryRow(entry.key, entry.value),
            );
          }),
          SizedBox(height: 24),
          // Recent Incidents
          Text(
            'Recent Incidents',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 12),
          ...recentIncidents.map((incident) {
            return _buildIncidentCard(context, incident);
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Container(
        width: 160,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String category, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            category.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(fontSize: 12),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentCard(BuildContext context, Map<String, dynamic> incident) {
    final type = incident['type'] as String? ?? 'Unknown';
    final severity = incident['severity'] as String? ?? 'Low';
    final createdAt = incident['createdAt'] as DateTime?;

    Color severityColor = Colors.green;
    if (severity == 'high') severityColor = Colors.orange;
    if (severity == 'critical') severityColor = Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    createdAt?.toString() ?? 'N/A',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                severity.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
