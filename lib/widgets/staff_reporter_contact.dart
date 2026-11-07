import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';

/// Staff-only panel that loads the real name and email of whoever submitted
/// a report (including anonymous ones). Reports themselves do not store an
/// email, so peers never see it; staff look it up on demand from the
/// protected `users` collection.
class StaffReporterContact extends StatefulWidget {
  final String reporterUid;

  const StaffReporterContact({super.key, required this.reporterUid});

  @override
  State<StaffReporterContact> createState() => _StaffReporterContactState();
}

class _StaffReporterContactState extends State<StaffReporterContact> {
  late Future<UserModel?> _reporter;

  @override
  void initState() {
    super.initState();
    _reporter = context.read<AuthProvider>().lookupReporter(widget.reporterUid);
  }

  @override
  void didUpdateWidget(covariant StaffReporterContact oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reporterUid != widget.reporterUid) {
      _reporter = context.read<AuthProvider>().lookupReporter(
        widget.reporterUid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: Colors.purple[800]),
          const SizedBox(width: 10),
          Expanded(
            child: FutureBuilder<UserModel?>(
              future: _reporter,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Text(
                    'Loading reporter...',
                    style: TextStyle(fontSize: 12),
                  );
                }
                final reporter = snapshot.data;
                if (snapshot.hasError || reporter == null) {
                  return const Text(
                    'Reporter details are not available.',
                    style: TextStyle(fontSize: 12),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reporter (visible to staff only)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reporter.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      reporter.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
