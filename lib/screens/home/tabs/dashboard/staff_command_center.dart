import 'package:flutter/material.dart';

import '../../../../config/theme.dart';
import '../../../../models/incident_model.dart';
import '../../../../models/user_model.dart';
import '../../../../widgets/dashboard/category_distribution_card.dart';
import '../../../../widgets/dashboard/metric_tile.dart';
import '../../../../widgets/dashboard/section_title.dart';
import '../../../../widgets/dashboard/staff_header_card.dart';
import '../../../../widgets/dashboard/urgent_queue_section.dart';

/// Dashboard shown to staff: status counts, urgent queue and category mix.
class StaffCommandCenter extends StatelessWidget {
  final UserModel? user;
  final List<IncidentModel> incidents;
  final ValueChanged<IncidentModel> onOpenIncident;

  const StaffCommandCenter({
    super.key,
    required this.user,
    required this.incidents,
    required this.onOpenIncident,
  });

  int _count(IncidentStatus status) =>
      incidents.where((i) => i.status == status).length;

  @override
  Widget build(BuildContext context) {
    final urgent = incidents
        .where(
          (i) =>
              (i.priority == IncidentPriority.critical ||
                  i.priority == IncidentPriority.high) &&
              i.status != IncidentStatus.resolved &&
              i.status != IncidentStatus.dismissed,
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffHeaderCard(
            name: user?.displayName ?? 'Staff',
            department: user?.department ?? 'Operations',
          ),
          const SizedBox(height: 20),
          const SectionTitle('Resolution Pipeline'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: [
              MetricTile(
                title: 'Pending Triage',
                count: _count(IncidentStatus.pending),
                color: AppTheme.pendingColor,
                icon: Icons.hourglass_top_outlined,
              ),
              MetricTile(
                title: 'Under Review',
                count: _count(IncidentStatus.underReview),
                color: AppTheme.underReviewColor,
                icon: Icons.rate_review_outlined,
              ),
              MetricTile(
                title: 'In Progress',
                count: _count(IncidentStatus.inProgress),
                color: AppTheme.inProgressColor,
                icon: Icons.construction_outlined,
              ),
              MetricTile(
                title: 'Resolved',
                count: _count(IncidentStatus.resolved),
                color: AppTheme.resolvedColor,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 24),
          UrgentQueueSection(incidents: urgent, onOpen: onOpenIncident),
          const SizedBox(height: 24),
          const SectionTitle('Reports by Category'),
          const SizedBox(height: 12),
          CategoryDistributionCard(incidents: incidents),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
