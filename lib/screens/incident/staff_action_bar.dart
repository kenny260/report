import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import 'status_update_dialog.dart';

/// Bottom bar on the detail screen with the staff-only "Update Status"
/// button. The detail screen only builds it for staff, and the Firestore
/// rules reject the writes for anyone else.
class StaffActionBar extends StatelessWidget {
  final IncidentModel incident;

  const StaffActionBar({super.key, required this.incident});

  void _openUpdateDialog(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final incidents = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) return;

    showDialog(
      context: context,
      builder: (_) => StatusUpdateDialog(
        incident: incident,
        onConfirm: (newStatus, newPriority, comment) async {
          var ok = true;
          if (newPriority != null) {
            ok = await incidents.updatePriority(
              incidentId: incident.id,
              priority: newPriority,
            );
          }
          if (ok) {
            ok = await incidents.updateStatus(
              incidentId: incident.id,
              newStatus: newStatus,
              updatedBy: user.uid,
              updatedByName: user.displayName,
              comment: comment,
            );
          }
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? 'Report updated.'
                    : incidents.errorMessage ?? 'Update failed.',
              ),
              backgroundColor: ok ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openUpdateDialog(context),
            icon: const Icon(Icons.security_update_good),
            label: const Text('Update Status / Notes (Staff)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
