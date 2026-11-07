import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/constants.dart';
import '../models/incident_model.dart';

/// All Firestore access for incident reports. This is the only layer that
/// knows about collection names and document shapes; providers call it and
/// never touch Firestore directly.
class FirestoreService {
  // Resolved lazily so the class can be subclassed in unit tests without a
  // Firebase app being initialised.
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _incidentsRef =>
      _firestore.collection(AppConstants.incidentsCollection);

  /// Creates a report and returns the generated document id.
  Future<String> createIncident(IncidentModel incident) async {
    final docRef = await _incidentsRef.add(incident.toFirestore());
    return docRef.id;
  }

  /// Live stream of all reports, newest first.
  Stream<List<IncidentModel>> getIncidentsStream() {
    return _incidentsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(IncidentModel.fromFirestore).toList(),
        );
  }

  /// Staff: changes the status and appends an entry to the status history.
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required String updatedBy,
    required String updatedByName,
    String? comment,
  }) async {
    final statusUpdate = StatusUpdate(
      status: newStatus,
      updatedBy: updatedBy,
      updatedByName: updatedByName,
      updatedAt: DateTime.now(),
      comment: comment,
    );

    await _incidentsRef.doc(incidentId).update({
      'status': newStatus.name,
      'updatedAt': Timestamp.now(),
      'statusHistory': FieldValue.arrayUnion([statusUpdate.toMap()]),
    });
  }

  /// Staff: changes the priority.
  Future<void> updateIncidentPriority({
    required String incidentId,
    required IncidentPriority priority,
  }) async {
    await _incidentsRef.doc(incidentId).update({
      'priority': priority.name,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Adds or removes the user's upvote atomically. A transaction keeps the
  /// counter and the voter list consistent if two users vote at once.
  Future<void> toggleUpvote({
    required String incidentId,
    required String userId,
  }) async {
    final ref = _incidentsRef.doc(incidentId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) return;

      final upvotedBy = List<String>.from(data['upvotedBy'] ?? const []);
      if (upvotedBy.contains(userId)) {
        upvotedBy.remove(userId);
      } else {
        upvotedBy.add(userId);
      }
      transaction.update(ref, {
        'upvotedBy': upvotedBy,
        'upvoteCount': upvotedBy.length,
      });
    });
  }

  /// Deletes a report (owner while pending, or staff).
  Future<void> deleteIncident(String incidentId) async {
    await _incidentsRef.doc(incidentId).delete();
  }

  /// Partial update, e.g. attaching image URLs after upload.
  Future<void> updateIncident(
    String incidentId,
    Map<String, dynamic> data,
  ) async {
    await _incidentsRef.doc(incidentId).update({
      ...data,
      'updatedAt': Timestamp.now(),
    });
  }
}
