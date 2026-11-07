import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/incident_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Holds incident state for the whole app: the live list from Firestore,
/// the active search/filter selection, the currently opened report and the
/// results of create / update / delete operations.
///
/// Data only ever comes from Firestore. A write that fails returns `false`
/// and sets [errorMessage]; nothing is faked locally. The Firestore stream
/// pushes every confirmed change back, so all screens stay in sync.
class IncidentProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  IncidentProvider({
    FirestoreService? firestoreService,
    StorageService? storageService,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _storageService = storageService ?? StorageService();

  List<IncidentModel> _incidents = [];
  List<IncidentModel> _filteredIncidents = [];
  IncidentModel? _selectedIncident;
  StreamSubscription<List<IncidentModel>>? _incidentSubscription;

  bool _isLoading = false; // a write operation is running
  bool _isFeedLoading = false; // waiting for the first snapshot
  String? _errorMessage; // last failed write
  String? _feedError; // last stream error
  bool _disposed = false;

  // Filter state
  IncidentCategory? _selectedCategory;
  IncidentStatus? _selectedStatus;
  IncidentPriority? _selectedPriority;
  String _searchQuery = '';

  // Getters
  List<IncidentModel> get incidents => _filteredIncidents;
  List<IncidentModel> get allIncidents => _incidents;
  IncidentModel? get selectedIncident => _selectedIncident;
  bool get isLoading => _isLoading;
  bool get isFeedLoading => _isFeedLoading;
  String? get errorMessage => _errorMessage;
  String? get feedError => _feedError;
  bool get isListening => _incidentSubscription != null;
  IncidentCategory? get selectedCategory => _selectedCategory;
  IncidentStatus? get selectedStatus => _selectedStatus;
  IncidentPriority? get selectedPriority => _selectedPriority;
  String get searchQuery => _searchQuery;

  /// Reports submitted by [userId], newest first.
  List<IncidentModel> incidentsReportedBy(String userId) =>
      _incidents.where((i) => i.reportedBy == userId).toList();

  // ---------------------------------------------------------------------
  // Session wiring
  // ---------------------------------------------------------------------

  /// Called by the provider proxy whenever the sign-in state changes:
  /// start listening after login, stop and clear after logout so one
  /// user's data never lingers for the next.
  void onAuthChanged({required bool isAuthenticated}) {
    if (isAuthenticated) {
      if (!isListening) initialize();
    } else if (isListening || _incidents.isNotEmpty) {
      _stopListening();
      _incidents = [];
      _filteredIncidents = [];
      _selectedIncident = null;
      _feedError = null;
      _errorMessage = null;
      _isFeedLoading = false;
      clearFilters(notify: false);
      // Deferred: this is invoked while the widget tree is building.
      scheduleMicrotask(_notify);
    }
  }

  /// (Re)starts the live Firestore subscription.
  void initialize() {
    _stopListening();
    _isFeedLoading = true;
    _feedError = null;
    _notify();

    _incidentSubscription = _firestoreService.getIncidentsStream().listen(
      (incidents) {
        _incidents = incidents;
        _isFeedLoading = false;
        _feedError = null;
        _applyFilters();
        _refreshSelectedIncident();
        _notify();
      },
      onError: (Object error) {
        _isFeedLoading = false;
        _feedError = 'Could not load incidents: $error';
        _notify();
      },
    );
  }

  void _stopListening() {
    _incidentSubscription?.cancel();
    _incidentSubscription = null;
  }

  // ---------------------------------------------------------------------
  // Create / update / delete
  // ---------------------------------------------------------------------

  /// Creates a report, uploads its photos and attaches their URLs.
  /// If an upload fails the report is rolled back so no half-created
  /// record is left behind.
  Future<bool> createIncident({
    required String title,
    required String description,
    required IncidentCategory category,
    required IncidentPriority priority,
    required String location,
    required String reportedBy,
    required String reporterName,
    bool isAnonymous = false,
    List<File>? images,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    // Anonymous reports never store the reporter's name. Only the uid is
    // kept, so staff can still follow up or deal with misuse.
    final publicName = isAnonymous ? AppConstants.anonymousName : reporterName;

    String? incidentId;
    try {
      final now = DateTime.now();
      final incident = IncidentModel(
        id: '',
        title: title,
        description: description,
        category: category,
        status: IncidentStatus.pending,
        priority: priority,
        location: location,
        imageUrls: const [],
        reportedBy: reportedBy,
        reporterName: publicName,
        isAnonymous: isAnonymous,
        createdAt: now,
        updatedAt: now,
        statusHistory: [
          StatusUpdate(
            status: IncidentStatus.pending,
            updatedBy: reportedBy,
            updatedByName: publicName,
            updatedAt: now,
            comment: 'Incident reported by $publicName',
          ),
        ],
      );

      incidentId = await _firestoreService.createIncident(incident);

      if (images != null && images.isNotEmpty) {
        final urls = await _storageService.uploadMultipleImages(
          imageFiles: images,
          incidentId: incidentId,
        );
        await _firestoreService.updateIncident(incidentId, {'imageUrls': urls});
      }

      _isLoading = false;
      _notify();
      return true;
    } catch (e) {
      if (incidentId != null) {
        await _rollbackCreate(incidentId);
      }
      _isLoading = false;
      _errorMessage = 'Failed to submit report: $e';
      _notify();
      return false;
    }
  }

  Future<void> _rollbackCreate(String incidentId) async {
    try {
      await _storageService.deleteIncidentImages(incidentId);
      await _firestoreService.deleteIncident(incidentId);
    } catch (e) {
      debugPrint('Rollback of $incidentId failed: $e');
    }
  }

  /// Staff only (enforced again by Firestore rules): change a report's status.
  Future<bool> updateStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required String updatedBy,
    required String updatedByName,
    String? comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      await _firestoreService.updateIncidentStatus(
        incidentId: incidentId,
        newStatus: newStatus,
        updatedBy: updatedBy,
        updatedByName: updatedByName,
        comment: comment,
      );
      _isLoading = false;
      _notify();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update status: $e';
      _notify();
      return false;
    }
  }

  /// Staff only (enforced by Firestore rules): change a report's priority.
  Future<bool> updatePriority({
    required String incidentId,
    required IncidentPriority priority,
  }) async {
    _errorMessage = null;
    try {
      await _firestoreService.updateIncidentPriority(
        incidentId: incidentId,
        priority: priority,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update priority: $e';
      _notify();
      return false;
    }
  }

  /// Adds or removes the user's upvote. The UI updates when Firestore
  /// confirms the change through the live stream.
  Future<bool> toggleUpvote(String incidentId, String userId) async {
    _errorMessage = null;
    try {
      await _firestoreService.toggleUpvote(
        incidentId: incidentId,
        userId: userId,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update vote: $e';
      _notify();
      return false;
    }
  }

  /// Deletes a report and its photos (owner while pending, or staff).
  /// Photos go first because the Storage rules check the report document.
  Future<bool> deleteIncident(String incidentId) async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      await _storageService.deleteIncidentImages(incidentId);
      await _firestoreService.deleteIncident(incidentId);
      if (_selectedIncident?.id == incidentId) _selectedIncident = null;
      _isLoading = false;
      _notify();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete incident: $e';
      _notify();
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // Selection, search and filters
  // ---------------------------------------------------------------------

  void selectIncident(IncidentModel incident) {
    _selectedIncident = incident;
    _notify();
  }

  void clearSelectedIncident() {
    _selectedIncident = null;
    _notify();
  }

  void setCategory(IncidentCategory? category) {
    _selectedCategory = category;
    _applyFilters();
    _notify();
  }

  void setStatus(IncidentStatus? status) {
    _selectedStatus = status;
    _applyFilters();
    _notify();
  }

  void setPriority(IncidentPriority? priority) {
    _selectedPriority = priority;
    _applyFilters();
    _notify();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    _notify();
  }

  void clearFilters({bool notify = true}) {
    _selectedCategory = null;
    _selectedStatus = null;
    _selectedPriority = null;
    _searchQuery = '';
    _applyFilters();
    if (notify) _notify();
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase();
    _filteredIncidents = _incidents.where((incident) {
      if (_selectedCategory != null && incident.category != _selectedCategory) {
        return false;
      }
      if (_selectedStatus != null && incident.status != _selectedStatus) {
        return false;
      }
      if (_selectedPriority != null && incident.priority != _selectedPriority) {
        return false;
      }
      if (query.isNotEmpty) {
        return incident.title.toLowerCase().contains(query) ||
            incident.description.toLowerCase().contains(query) ||
            incident.location.toLowerCase().contains(query) ||
            incident.reporterName.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  /// Keeps the open detail screen in step with the latest snapshot.
  void _refreshSelectedIncident() {
    final selected = _selectedIncident;
    if (selected == null) return;
    final matches = _incidents.where((i) => i.id == selected.id);
    _selectedIncident = matches.isEmpty ? null : matches.first;
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopListening();
    super.dispose();
  }
}
