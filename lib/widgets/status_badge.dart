import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/incident_model.dart';

/// Reusable badge widget for displaying incident status.
/// Color-coded for quick visual identification.
class StatusBadge extends StatelessWidget {
  final IncidentStatus status;
  final bool large;

  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(status.name);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 10 : 8,
            height: large ? 10 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: large ? 8 : 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: large ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge for displaying priority level
class PriorityBadge extends StatelessWidget {
  final IncidentPriority priority;
  final bool large;

  const PriorityBadge({super.key, required this.priority, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getPriorityColor(priority.name);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriorityIcon(), size: large ? 16 : 12, color: color),
          SizedBox(width: large ? 6 : 4),
          Text(
            priority.displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: large ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPriorityIcon() {
    switch (priority) {
      case IncidentPriority.low:
        return Icons.arrow_downward;
      case IncidentPriority.medium:
        return Icons.remove;
      case IncidentPriority.high:
        return Icons.arrow_upward;
      case IncidentPriority.critical:
        return Icons.priority_high;
    }
  }
}
