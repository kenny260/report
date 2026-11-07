import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporter/models/incident_model.dart';
import 'package:campus_incident_reporter/providers/incident_provider.dart';
import 'package:campus_incident_reporter/services/firestore_service.dart';
import 'package:campus_incident_reporter/services/storage_service.dart';

/// In-memory stand-in for FirestoreService. Subclassing is safe because the
/// real service resolves FirebaseFirestore lazily and these overrides never
/// touch it.
class FakeFirestoreService extends FirestoreService {
  final StreamController<List<IncidentModel>> controller =
      StreamController<List<IncidentModel>>.broadcast();
  bool failWrites = false;
  final List<String> deleted = [];
  IncidentModel? lastCreated;

  @override
  Stream<List<IncidentModel>> getIncidentsStream() => controller.stream;

  @override
  Future<String> createIncident(IncidentModel incident) async {
    if (failWrites) throw Exception('permission-denied');
    lastCreated = incident;
    return 'new-id';
  }

  @override
  Future<void> updateIncident(String id, Map<String, dynamic> data) async {}

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required String updatedBy,
    required String updatedByName,
    String? comment,
  }) async {
    if (failWrites) throw Exception('permission-denied');
  }

  @override
  Future<void> deleteIncident(String incidentId) async {
    deleted.add(incidentId);
  }
}

class FakeStorageService extends StorageService {
  bool failUploads = false;

  @override
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String incidentId,
  }) async {
    if (failUploads) throw Exception('upload failed');
    return ['https://example.test/photo.jpg'];
  }

  @override
  Future<void> deleteIncidentImages(String incidentId) async {}
}

IncidentModel incident(
  String id, {
  String title = 'Broken tap',
  String location = 'Library',
  IncidentCategory category = IncidentCategory.brokenFacility,
  IncidentStatus status = IncidentStatus.pending,
  String reportedBy = 'u1',
}) {
  final now = DateTime(2026, 1, 1);
  return IncidentModel(
    id: id,
    title: title,
    description: 'A description long enough to be valid',
    category: category,
    status: status,
    priority: IncidentPriority.medium,
    location: location,
    imageUrls: const [],
    reportedBy: reportedBy,
    reporterName: 'Jane',
    createdAt: now,
    updatedAt: now,
    statusHistory: const [],
  );
}

void main() {
  late FakeFirestoreService firestore;
  late FakeStorageService storage;
  late IncidentProvider provider;

  setUp(() {
    firestore = FakeFirestoreService();
    storage = FakeStorageService();
    provider = IncidentProvider(
      firestoreService: firestore,
      storageService: storage,
    );
  });

  tearDown(() => provider.dispose());

  Future<void> push(List<IncidentModel> items) async {
    firestore.controller.add(items);
    await Future<void>.delayed(Duration.zero);
  }

  test('shows loading until the first snapshot, then the incidents', () async {
    provider.initialize();
    expect(provider.isFeedLoading, isTrue);

    await push([incident('a'), incident('b')]);

    expect(provider.isFeedLoading, isFalse);
    expect(provider.allIncidents.length, 2);
  });

  test('search matches title, location and description', () async {
    provider.initialize();
    await push([
      incident('a', title: 'Leaking pipe', location: 'Cafeteria'),
      incident('b', title: 'Broken chair', location: 'Library'),
    ]);

    provider.setSearchQuery('cafeteria');
    expect(provider.incidents.map((i) => i.id), ['a']);

    provider.setSearchQuery('chair');
    expect(provider.incidents.map((i) => i.id), ['b']);

    provider.clearFilters();
    expect(provider.incidents.length, 2);
  });

  test('category and status filters combine', () async {
    provider.initialize();
    await push([
      incident('a', category: IncidentCategory.safety),
      incident(
        'b',
        category: IncidentCategory.safety,
        status: IncidentStatus.resolved,
      ),
      incident('c', category: IncidentCategory.sanitation),
    ]);

    provider.setCategory(IncidentCategory.safety);
    expect(provider.incidents.length, 2);

    provider.setStatus(IncidentStatus.resolved);
    expect(provider.incidents.map((i) => i.id), ['b']);
  });

  test(
    'a new snapshot (e.g. staff status change) updates the open report',
    () async {
      provider.initialize();
      await push([incident('a')]);
      provider.selectIncident(provider.allIncidents.first);

      await push([incident('a', status: IncidentStatus.resolved)]);

      expect(provider.selectedIncident?.status, IncidentStatus.resolved);
    },
  );

  test('a failed status update returns false and reports the error', () async {
    provider.initialize();
    await push([incident('a')]);
    firestore.failWrites = true;

    final ok = await provider.updateStatus(
      incidentId: 'a',
      newStatus: IncidentStatus.resolved,
      updatedBy: 's1',
      updatedByName: 'Staff',
    );

    expect(ok, isFalse);
    expect(provider.errorMessage, contains('Failed to update status'));
    expect(provider.allIncidents.first.status, IncidentStatus.pending);
  });

  test('a failed photo upload rolls the new report back', () async {
    storage.failUploads = true;

    final ok = await provider.createIncident(
      title: 'Broken tap',
      description: 'The tap in the washroom is leaking badly',
      category: IncidentCategory.brokenFacility,
      priority: IncidentPriority.medium,
      location: 'Library',
      reportedBy: 'u1',
      reporterName: 'Jane',
      images: [File('photo.jpg')],
    );

    expect(ok, isFalse);
    expect(firestore.deleted, ['new-id']);
    expect(provider.errorMessage, isNotNull);
  });

  test('anonymous reports store no name, named reports keep it', () async {
    Future<void> submit({required bool anonymous}) => provider.createIncident(
      title: 'Broken tap',
      description: 'The tap in the washroom is leaking badly',
      category: IncidentCategory.brokenFacility,
      priority: IncidentPriority.medium,
      location: 'Library',
      reportedBy: 'u1',
      reporterName: 'Jane Doe',
      isAnonymous: anonymous,
    );

    await submit(anonymous: true);
    expect(firestore.lastCreated!.isAnonymous, isTrue);
    expect(firestore.lastCreated!.reporterName, 'Anonymous');
    expect(
      firestore.lastCreated!.statusHistory.first.updatedByName,
      'Anonymous',
    );
    expect(firestore.lastCreated!.reportedBy, 'u1'); // staff can still trace

    await submit(anonymous: false);
    expect(firestore.lastCreated!.isAnonymous, isFalse);
    expect(firestore.lastCreated!.reporterName, 'Jane Doe');
  });

  test('a report document never contains an email', () {
    final data = incident('a').toFirestore();
    expect(data.containsKey('reporterEmail'), isFalse);
    expect(data['isAnonymous'], isFalse);
  });

  test('signing out clears data and filters', () async {
    provider.initialize();
    await push([incident('a')]);
    provider.setSearchQuery('tap');

    provider.onAuthChanged(isAuthenticated: false);

    expect(provider.allIncidents, isEmpty);
    expect(provider.searchQuery, isEmpty);
    expect(provider.isListening, isFalse);
  });

  test('incidentsReportedBy returns only that user\'s reports', () async {
    provider.initialize();
    await push([
      incident('a', reportedBy: 'u1'),
      incident('b', reportedBy: 'u2'),
    ]);

    expect(provider.incidentsReportedBy('u1').map((i) => i.id), ['a']);
  });
}
