import 'package:flutter/material.dart';

import '../../models/incident_model.dart';
import '../incident_card.dart';

/// "High & Critical Priority Queue": a header with an urgent counter and the
/// list of open high/critical reports, or an all-clear message.
class UrgentQueueSection extends StatelessWidget {
  final List<IncidentModel> incidents;
  final ValueChanged<IncidentModel> onOpen;

  const UrgentQueueSection({
    super.key,
    required this.incidents,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                SizedBox(width: 6),
                Text(
                  'High & Critical Priority Queue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Text(
                '${incidents.length} Urgent',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (incidents.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.done_all, color: Colors.green[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No critical or high-priority incidents currently pending. Good work!',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final item = incidents[index];
              return IncidentCard(incident: item, onTap: () => onOpen(item));
            },
          ),
      ],
    );
  }
}
