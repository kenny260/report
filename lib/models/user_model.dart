import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the campus incident reporting system.
/// Users can be either students (who submit reports) or staff (who manage them).
enum UserRole { student, staff }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final String? photoUrl;
  final String? studentId;
  final String? department;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.photoUrl,
    this.studentId,
    this.department,
  });

  /// Creates a UserModel from a Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] == 'staff' ? UserRole.staff : UserRole.student,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'],
      studentId: data['studentId'],
      department: data['department'],
    );
  }

  /// Converts UserModel to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role == UserRole.staff ? 'staff' : 'student',
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'studentId': studentId,
      'department': department,
    };
  }

  /// Creates a copy with modified fields.
  UserModel copyWith({
    String? displayName,
    UserRole? role,
    String? photoUrl,
    String? studentId,
    String? department,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
    );
  }

  bool get isStaff => role == UserRole.staff;
  bool get isStudent => role == UserRole.student;
}
