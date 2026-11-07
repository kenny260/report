import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme.dart';
import '../../../models/incident_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/incident_provider.dart';
import '../../../widgets/incident_card.dart';
import '../../../widgets/loading_overlay.dart';
import '../../incident/incident_detail_screen.dart';
import '../../incident/create_incident_screen.dart';

class MyReportsTab extends StatefulWidget {
  const MyReportsTab({super.key});

  @override
  State<MyReportsTab> createState() => _MyReportsTabState();
}

class _MyReportsTabState extends State<MyReportsTab> {
  String _selectedStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final incidentProvider = context.watch<IncidentProvider>();

    final user = authProvider.user;
    final allUserReports = (user == null)
        ? <IncidentModel>[]
        : incidentProvider.incidentsReportedBy(user.uid);

    final filteredReports = allUserReports.where((incident) {
      if (_selectedStatusFilter == 'open') {
        return incident.status != IncidentStatus.resolved &&
            incident.status != IncidentStatus.dismissed;
      } else if (_selectedStatusFilter == 'resolved') {
        return incident.status == IncidentStatus.resolved;
      }
      return true;
    }).toList();

    final openCount = allUserReports
        .where(
          (i) =>
              i.status != IncidentStatus.resolved &&
              i.status != IncidentStatus.dismissed,
        )
        .length;
    final resolvedCount = allUserReports
        .where((i) => i.status == IncidentStatus.resolved)
        .length;

    return Column(
      children: [
        // Summary Header Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Incident Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${allUserReports.length} Total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _statItem('Active Issues', openCount, Colors.amber[300]!),
                  const SizedBox(width: 24),
                  _statItem(
                    'Resolved',
                    resolvedCount,
                    Colors.lightGreenAccent[400]!,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filter chips row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _filterChip('all', 'All Reports (${allUserReports.length})'),
              const SizedBox(width: 8),
              _filterChip('open', 'In Progress / Open ($openCount)'),
              const SizedBox(width: 8),
              _filterChip('resolved', 'Resolved ($resolvedCount)'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Reports list
        Expanded(
          child: filteredReports.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.assignment_outlined,
                  title: 'No Reports Found',
                  subtitle: allUserReports.isEmpty
                      ? 'You have not submitted any incident reports yet. Help keep the campus safe and functional!'
                      : 'No reports match the selected tab filter.',
                  action: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateIncidentScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Submit New Report'),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredReports.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final incident = filteredReports[index];
                    return IncidentCard(
                      incident: incident,
                      showReporter: false,
                      onTap: () {
                        incidentProvider.selectIncident(incident);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                IncidentDetailScreen(incidentId: incident.id),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatusFilter = key),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primaryDark : Colors.grey[700],
      ),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
