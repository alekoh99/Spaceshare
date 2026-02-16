import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class AdminIncidentReviewScreen extends StatefulWidget {
  const AdminIncidentReviewScreen({super.key});

  @override
  State<AdminIncidentReviewScreen> createState() =>
      _AdminIncidentReviewScreenState();
}

class _AdminIncidentReviewScreenState extends State<AdminIncidentReviewScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  void _approveIncident(String incidentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Incident $incidentId approved'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _rejectIncident(String incidentId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Incident $incidentId rejected'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  final incidents = [
    {
      'id': 'INC001',
      'user': 'User123',
      'reason': 'Inappropriate behavior',
      'status': 'Pending'
    },
    {
      'id': 'INC002',
      'user': 'User456',
      'reason': 'Policy violation',
      'status': 'Under Review'
    },
    {
      'id': 'INC003',
      'user': 'User789',
      'reason': 'Fake profile',
      'status': 'Resolved'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Incident Review',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All Incidents'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncidentsTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }

  Widget _buildIncidentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: incidents.map((incident) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(incident['status']),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      incident['status'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident['id'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          incident['reason'] ?? '',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('User:',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(incident['user'] ?? ''),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Status:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: incident['status'],
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'Pending', child: Text('Pending')),
                          DropdownMenuItem(
                              value: 'Under Review',
                              child: Text('Under Review')),
                          DropdownMenuItem(
                              value: 'Resolved', child: Text('Resolved')),
                        ],
                        onChanged: (val) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      const Text('Resolution Notes:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add notes...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _rejectIncident(incident['id'] as String),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[500]),
                              child: const Text(
                                'Reject',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approveIncident(incident['id'] as String),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600]),
                              child: const Text(
                                'Approve',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Incident Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Incidents: 3',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Pending: 1',
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Under Review: 1',
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Resolved: 1',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Under Review':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
