import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import '../../providers/compliance_controller.dart';

class AdminAnalyticsDashboard extends StatefulWidget {
  const AdminAnalyticsDashboard({super.key});

  @override
  State<AdminAnalyticsDashboard> createState() => _AdminAnalyticsDashboardState();
}

class _AdminAnalyticsDashboardState extends State<AdminAnalyticsDashboard> {
  final complianceController = Get.find<ComplianceController>();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAnalytics();
    });
  }

  Future<void> _refreshAnalytics() async {
    setState(() => _isRefreshing = true);
    try {
      await complianceController.loadPendingComplaints();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analytics updated'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load analytics: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Admin Analytics',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.cyan),
            onPressed: _isRefreshing ? null : _refreshAnalytics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsGrid(),
            const SizedBox(height: 24),
            _buildActivitySection(),
            const SizedBox(height: 24),
            _buildPendingCasesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMetricCardNamed(
          title: 'Pending Cases',
          value: Obx(() => Text('${complianceController.incidents.length}')),
          icon: Icons.warning,
          color: Colors.orange,
        ),
        _buildMetricCardNamed(
          title: 'Total Incidents',
          value: Obx(() => Text(complianceController.auditReport.value?.totalIncidentsLogged.toString() ?? '0')),
          icon: Icons.report,
          color: Colors.red,
        ),
        _buildMetricCardNamed(
          title: 'Complaints',
          value: Obx(() => Text(complianceController.auditReport.value?.totalComplaintsSubmitted.toString() ?? '0')),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildMetricCardNamed(
          title: 'Flagged Users',
          value: Obx(() => Text(complianceController.auditReport.value?.flaggedUsers.length.toString() ?? '0')),
          icon: Icons.assessment,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildMetricCardNamed({
    required String title,
    required dynamic value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          if (value is Widget)
            value
          else
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[900],
            border: Border.all(color: Colors.grey[700]!),
          ),
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            if (complianceController.incidents.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No recent incidents',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: complianceController.incidents.take(5).length,
              itemBuilder: (context, index) {
                final incident = complianceController.incidents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.type,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              incident.description,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        incident.status,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(incident.status),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPendingCasesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pending Moderation Cases',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(() => Text(
              '${complianceController.incidents.length} cases',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[300]!),
            color: Colors.orange[50],
          ),
          child: Obx(() {
            if (complianceController.incidents.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('No pending cases'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: complianceController.incidents.take(5).length,
              itemBuilder: (context, index) {
                final incident = complianceController.incidents[index];

                return ListTile(
                  title: Text('Case: ${incident.type}'),
                  subtitle: Text(incident.description),
                  trailing: Chip(
                    label: Text(incident.status),
                    backgroundColor: _getStatusColor(incident.status).withValues(alpha: 0.2),
                  ),
                  onTap: () {
                    // Navigate to case details
                    Get.toNamed('/incident-review', arguments: incident.incidentId);
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'pending':
        return Colors.orange;
      case 'resolved':
      case 'closed':
        return Colors.green;
      case 'appealed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
