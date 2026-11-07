import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/incident_model.dart';

/// Card with one progress bar per category showing its share of all reports.
class CategoryDistributionCard extends StatelessWidget {
  final List<IncidentModel> incidents;

  const CategoryDistributionCard({super.key, required this.incidents});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final category in IncidentCategory.values)
              _CategoryRow(
                category: category,
                count: incidents.where((i) => i.category == category).length,
                total: incidents.length,
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IncidentCategory category;
  final int count;
  final int total;

  const _CategoryRow({
    required this.category,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(category.iconData, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              category.displayName,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: share,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
