import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories for campus incidents
enum IncidentCategory {
  brokenFacility,
  waterShortage,
  electricityOutage,
  damagedFurniture,
  sanitation,
  safety,
  network,
  other,
}

/// Status progression for incidents
enum IncidentStatus { pending, underReview, inProgress, resolved, dismissed }

/// Priority levels for incidents
enum IncidentPriority { low, medium, high, critical }

/// Represents a status change in the incident's history
class StatusUpdate {
  final IncidentStatus status;
  final String updatedBy;
  final String updatedByName;
  final DateTime updatedAt;
  final String? comment;

  const StatusUpdate({
    required this.status,
    required this.updatedBy,
    required this.updatedByName,
    required this.updatedAt,
    this.comment,
  });

  factory StatusUpdate.fromMap(Map<String, dynamic> map) {
    return StatusUpdate(
      status: IncidentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => IncidentStatus.pending,
      ),
      updatedBy: map['updatedBy'] ?? '',
      updatedByName: map['updatedByName'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      comment: map['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'comment': comment,
    };
  }
}

/// Main incident model for campus reports
class IncidentModel {
  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final IncidentStatus status;
  final IncidentPriority priority;
  final String location;
  final List<String> imageUrls;
  final String reportedBy;
  final String reporterName; // 'Anonymous' when isAnonymous is true
  final bool isAnonymous;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusUpdate> statusHistory;
  final int upvoteCount;
  final List<String> upvotedBy;

  const IncidentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.location,
    required this.imageUrls,
    required this.reportedBy,
    required this.reporterName,
    this.isAnonymous = false,
    this.assignedTo,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    required this.statusHistory,
    this.upvoteCount = 0,
    this.upvotedBy = const [],
  });

  factory IncidentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IncidentModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: IncidentCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => IncidentCategory.other,
      ),
      status: IncidentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => IncidentStatus.pending,
      ),
      priority: IncidentPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => IncidentPriority.medium,
      ),
      location: data['location'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      reportedBy: data['reportedBy'] ?? '',
      reporterName: data['reporterName'] ?? '',
      isAnonymous: data['isAnonymous'] ?? false,
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statusHistory:
          (data['statusHistory'] as List<dynamic>?)
              ?.map((e) => StatusUpdate.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      upvoteCount: data['upvoteCount'] ?? 0,
      upvotedBy: List<String>.from(data['upvotedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'status': status.name,
      'priority': priority.name,
      'location': location,
      'imageUrls': imageUrls,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'isAnonymous': isAnonymous,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      'upvoteCount': upvoteCount,
      'upvotedBy': upvotedBy,
    };
  }

  IncidentModel copyWith({
    String? title,
    String? description,
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String? location,
    List<String>? imageUrls,
    String? assignedTo,
    String? assignedToName,
    DateTime? updatedAt,
    List<StatusUpdate>? statusHistory,
    int? upvoteCount,
    List<String>? upvotedBy,
  }) {
    return IncidentModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      imageUrls: imageUrls ?? this.imageUrls,
      reportedBy: reportedBy,
      reporterName: reporterName,
      isAnonymous: isAnonymous,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      upvotedBy: upvotedBy ?? this.upvotedBy,
    );
  }
}

// Extension for display-friendly names
extension IncidentCategoryExtension on IncidentCategory {
  String get displayName {
    switch (this) {
      case IncidentCategory.brokenFacility:
        return 'Broken Facility';
      case IncidentCategory.waterShortage:
        return 'Water Shortage';
      case IncidentCategory.electricityOutage:
        return 'Electricity Outage';
      case IncidentCategory.damagedFurniture:
        return 'Damaged Furniture';
      case IncidentCategory.sanitation:
        return 'Sanitation';
      case IncidentCategory.safety:
        return 'Safety Concern';
      case IncidentCategory.network:
        return 'Network/Internet';
      case IncidentCategory.other:
        return 'Other';
    }
  }

  IconData get iconData {
    switch (this) {
      case IncidentCategory.brokenFacility:
        return Icons.build_outlined;
      case IncidentCategory.waterShortage:
        return Icons.water_drop_outlined;
      case IncidentCategory.electricityOutage:
        return Icons.bolt_outlined;
      case IncidentCategory.damagedFurniture:
        return Icons.chair_outlined;
      case IncidentCategory.sanitation:
        return Icons.cleaning_services_outlined;
      case IncidentCategory.safety:
        return Icons.warning_amber_outlined;
      case IncidentCategory.network:
        return Icons.wifi_outlined;
      case IncidentCategory.other:
        return Icons.assignment_outlined;
    }
  }
}

extension IncidentStatusExtension on IncidentStatus {
  String get displayName {
    switch (this) {
      case IncidentStatus.pending:
        return 'Pending';
      case IncidentStatus.underReview:
        return 'Under Review';
      case IncidentStatus.inProgress:
        return 'In Progress';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.dismissed:
        return 'Dismissed';
    }
  }
}

extension IncidentPriorityExtension on IncidentPriority {
  String get displayName {
    switch (this) {
      case IncidentPriority.low:
        return 'Low';
      case IncidentPriority.medium:
        return 'Medium';
      case IncidentPriority.high:
        return 'High';
      case IncidentPriority.critical:
        return 'Critical';
    }
  }
}
