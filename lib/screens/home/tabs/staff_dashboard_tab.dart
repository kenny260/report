import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/incident_provider.dart';
import '../../incident/incident_detail_screen.dart';
import 'dashboard/staff_command_center.dart';
import 'dashboard/student_transparency_view.dart';

/// Dashboard tab. Staff get the command center; students get a read-only
/// transparency view. (The Firestore rules enforce the same split.)
class StaffDashboardTab extends StatelessWidget {
  const StaffDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final incidentProvider = context.watch<IncidentProvider>();
    final incidents = incidentProvider.allIncidents;

    if (!authProvider.isStaff) {
      return StudentTransparencyView(incidents: incidents);
    }

    return StaffCommandCenter(
      user: authProvider.user,
      incidents: incidents,
      onOpenIncident: (incident) {
        incidentProvider.selectIncident(incident);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => IncidentDetailScreen(incidentId: incident.id),
          ),
        );
      },
    );
  }
}
