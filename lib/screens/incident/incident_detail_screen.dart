import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/theme.dart';
import '../../models/incident_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/staff_reporter_contact.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/status_timeline.dart';
import 'staff_action_bar.dart';

class IncidentDetailScreen extends StatelessWidget {
  final String incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  Widget build(BuildContext context) {
    final incidentProvider = context.watch<IncidentProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Find the latest incident state from provider
    final incident = incidentProvider.allIncidents.firstWhere(
      (i) => i.id == incidentId,
      orElse: () =>
          incidentProvider.selectedIncident ??
          IncidentModel(
            id: incidentId,
            title: 'Incident Report',
            description: '',
            category: IncidentCategory.other,
            status: IncidentStatus.pending,
            priority: IncidentPriority.medium,
            location: '',
            imageUrls: [],
            reportedBy: '',
            reporterName: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            statusHistory: [],
          ),
    );

    final currentUser = authProvider.user;
    final isStaff = currentUser?.isStaff ?? false;
    final isOwner = currentUser?.uid == incident.reportedBy;
    final hasUpvoted =
        currentUser != null && incident.upvotedBy.contains(currentUser.uid);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          // Matches the Firestore rule: staff can always delete; the
          // reporter only while the report is still pending.
          if (isStaff || (isOwner && incident.status == IncidentStatus.pending))
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Incident',
              onPressed: () => _confirmDelete(context, incidentProvider),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Category & Status Header Banner
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          incident.category.iconData,
                          size: 24,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.category.displayName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              timeago.format(incident.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: incident.status, large: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    incident.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      PriorityBadge(priority: incident.priority),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          incident.location,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Image Gallery (Firebase Storage)
            if (incident.imageUrls.isNotEmpty) ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attached Photographs',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: incident.imageUrls.length,
                        itemBuilder: (context, index) {
                          final url = incident.imageUrls[index];
                          return GestureDetector(
                            onTap: () => _openFullScreenImage(context, url),
                            child: Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  placeholder: (context, _) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, _, error) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Detailed Description Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(18),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Incident Description',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    incident.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Reporter info and Me-Too/Upvote Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue[100],
                            child: incident.isAnonymous
                                ? const Icon(
                                    Icons.visibility_off,
                                    size: 16,
                                    color: AppTheme.primaryColor,
                                  )
                                : Text(
                                    incident.reporterName.isNotEmpty
                                        ? incident.reporterName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                incident.reporterName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (incident.isAnonymous && isOwner)
                                Text(
                                  'Only staff can see this is you',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      // Upvote / "Me Too" button
                      ElevatedButton.icon(
                        onPressed: currentUser == null
                            ? null
                            : () {
                                incidentProvider.toggleUpvote(
                                  incident.id,
                                  currentUser.uid,
                                );
                              },
                        icon: Icon(
                          hasUpvoted
                              ? Icons.thumb_up
                              : Icons.thumb_up_alt_outlined,
                          size: 16,
                        ),
                        label: Text(
                          '${incident.upvoteCount} Affected',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasUpvoted
                              ? AppTheme.primaryColor
                              : Colors.grey[100],
                          foregroundColor: hasUpvoted
                              ? Colors.white
                              : Colors.grey[800],
                          elevation: hasUpvoted ? 1 : 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Real identity of the reporter: staff only
                  if (isStaff) ...[
                    const SizedBox(height: 12),
                    StaffReporterContact(reporterUid: incident.reportedBy),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Resolution timeline (status history)
            StatusTimeline(history: incident.statusHistory),
          ],
        ),
      ),

      // Staff-only action bar (role-based access control)
      bottomSheet: isStaff ? StaffActionBar(incident: incident) : null,
    );
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, IncidentProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Incident Report'),
        content: const Text(
          'Are you sure you want to permanently delete this incident report and its attached photographs?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await provider.deleteIncident(incidentId);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incident report deleted.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        provider.errorMessage ?? 'Failed to delete incident',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
