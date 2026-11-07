import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';

/// Firebase Storage operations for incident photographs, stored under
/// `incidents/{incidentId}/{uuid}.jpg`.
class StorageService {
  // Lazy so tests can subclass without initialising Firebase.
  FirebaseStorage get _storage => FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Uploads one image and returns its download URL.
  Future<String> uploadIncidentImage({
    required File imageFile,
    required String incidentId,
  }) async {
    final ref = _storage
        .ref()
        .child(AppConstants.incidentImagesPath)
        .child(incidentId)
        .child('${_uuid.v4()}.jpg');

    final snapshot = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return snapshot.ref.getDownloadURL();
  }

  /// Uploads several images sequentially and returns their download URLs.
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String incidentId,
  }) async {
    final urls = <String>[];
    for (final file in imageFiles) {
      urls.add(
        await uploadIncidentImage(imageFile: file, incidentId: incidentId),
      );
    }
    return urls;
  }

  /// Deletes every image stored for an incident. Failures for individual
  /// files are logged and skipped so a missing file never blocks deletion
  /// of the report itself.
  Future<void> deleteIncidentImages(String incidentId) async {
    final ListResult result = await _storage
        .ref()
        .child(AppConstants.incidentImagesPath)
        .child(incidentId)
        .listAll();

    for (final ref in result.items) {
      try {
        await ref.delete();
      } on FirebaseException catch (e) {
        debugPrint('Could not delete ${ref.fullPath}: ${e.code}');
      }
    }
  }
}
