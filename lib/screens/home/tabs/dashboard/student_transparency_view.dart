import 'package:flutter/material.dart';

import '../../../../models/incident_model.dart';
import '../../../../widgets/dashboard/campus_pulse_card.dart';
import '../../../../widgets/dashboard/hotline_card.dart';
import '../../../../widgets/dashboard/section_title.dart';
import '../../../../widgets/dashboard/staff_access_note.dart';

/// Read-only view for students: how many reports are resolved, who to
/// contact, and why staff tools are not available.
class StudentTransparencyView extends StatelessWidget {
  final List<IncidentModel> incidents;

  const StudentTransparencyView({super.key, required this.incidents});

  @override
  Widget build(BuildContext context) {
    final resolved = incidents
        .where((i) => i.status == IncidentStatus.resolved)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CampusPulseCard(resolved: resolved, total: incidents.length),
          const SizedBox(height: 20),
          const SectionTitle('Emergency & Facilities Hotlines'),
          const SizedBox(height: 10),
          // NOTE: replace these example contacts with the real ALU numbers.
          const HotlineCard(
            title: 'Campus Security & Safety',
            contact: '+250 788 123 456 (24/7)',
            icon: Icons.shield_outlined,
            color: Colors.red,
          ),
          const HotlineCard(
            title: 'Facilities & Maintenance Desk',
            contact: 'facilities@alueducation.com / Ext 204',
            icon: Icons.plumbing_outlined,
            color: Colors.blue,
          ),
          const HotlineCard(
            title: 'IT Helpdesk & Campus WiFi',
            contact: 'ithelpdesk@alueducation.com',
            icon: Icons.wifi_outlined,
            color: Colors.teal,
          ),
          const SizedBox(height: 20),
          const StaffAccessNote(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
