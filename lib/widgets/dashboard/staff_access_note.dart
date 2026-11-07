import 'package:flutter/material.dart';

/// Explains to students why the staff tools are not available to them.
class StaffAccessNote extends StatelessWidget {
  const StaffAccessNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.purple[800], size: 18),
              const SizedBox(width: 8),
              Text(
                'Staff Role Verification Note',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You are signed in with a student account. Only verified staff '
            'accounts (@alueducation.com) can update incident status, change '
            'priority and manage resolution records. This is enforced by the '
            'database security rules, not just by this screen.',
            style: TextStyle(fontSize: 12, color: Colors.purple[900]),
          ),
        ],
      ),
    );
  }
}
