import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/incident_model.dart';

class StatusUpdateDialog extends StatefulWidget {
  final IncidentModel incident;
  final Function(
    IncidentStatus newStatus,
    IncidentPriority? newPriority,
    String? comment,
  )
  onConfirm;

  const StatusUpdateDialog({
    super.key,
    required this.incident,
    required this.onConfirm,
  });

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  late IncidentStatus _selectedStatus;
  late IncidentPriority _selectedPriority;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.incident.status;
    _selectedPriority = widget.incident.priority;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit_note, color: AppTheme.primaryColor),
          SizedBox(width: 8),
          Text('Update Incident Status'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Progress Stage:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<IncidentStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(),
              ),
              items: IncidentStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.getStatusColor(status.name),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStatus = val);
              },
            ),

            const SizedBox(height: 16),

            const Text(
              'Adjust Priority:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<IncidentPriority>(
              initialValue: _selectedPriority,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(),
              ),
              items: IncidentPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 16,
                        color: AppTheme.getPriorityColor(priority.name),
                      ),
                      const SizedBox(width: 8),
                      Text(priority.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedPriority = val);
              },
            ),

            const SizedBox(height: 16),

            const Text(
              'Resolution Note / Staff Comment:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Electrician dispatched to inspect wire. Expected fix by 4 PM.',
                border: OutlineInputBorder(),
                hintStyle: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onConfirm(
              _selectedStatus,
              _selectedPriority != widget.incident.priority
                  ? _selectedPriority
                  : null,
              _commentController.text.trim().isNotEmpty
                  ? _commentController.text.trim()
                  : null,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Update'),
        ),
      ],
    );
  }
}
