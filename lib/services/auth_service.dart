import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/constants.dart';
import '../models/user_model.dart';
import '../utils/validators.dart';

/// Wraps every Firebase Authentication call plus the matching profile
/// document in Firestore (`users/{uid}`).
///
/// Nothing in this class falls back to local or fake data: if Firebase
/// rejects a call, the exception is propagated so the UI can show it.
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase user, if any.
  User? get currentUser => _auth.currentUser;

  /// Registers a new ALU account, sends the verification email and creates
  /// the profile document. If the profile cannot be written, the freshly
  /// created auth account is removed so no half-registered user is left.
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? studentId,
    String? department,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!Validators.isAluEmail(normalizedEmail)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message:
            'Please use your ALU email address (${AppConstants.studentDomain} or ${AppConstants.staffDomain}).',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final firebaseUser = credential.user!;

    try {
      await firebaseUser.updateDisplayName(displayName);
      await firebaseUser.sendEmailVerification();

      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: normalizedEmail,
        displayName: displayName,
        role: Validators.isStaffEmail(normalizedEmail)
            ? UserRole.staff
            : UserRole.student,
        createdAt: DateTime.now(),
        studentId: studentId,
        department: department,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toFirestore());

      return userModel;
    } catch (_) {
      await firebaseUser.delete();
      rethrow;
    }
  }

  /// Signs in with email and password and loads the Firestore profile.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!Validators.isAluEmail(normalizedEmail)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Only ALU email addresses can use this app.',
      );
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final profile = await getUserModel(credential.user!.uid);
    if (profile == null) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User profile not found. Please register again.',
      );
    }
    return profile;
  }

  /// Fetches a profile document by uid, or null if it does not exist.
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Reloads the user and force-refreshes the ID token. The refresh matters:
  /// Firestore and Storage rules read `email_verified` from the token, which
  /// would otherwise stay `false` until it expires (up to an hour).
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
  }
}
