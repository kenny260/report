import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Authentication state enumeration
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  emailNotVerified,
}

/// Holds the signed-in user, their role and the authentication state.
///
/// The state is driven by Firebase's `authStateChanges` stream, so a
/// restored session, a sign-out from another place and a fresh login all
/// follow the same path. All results come from Firebase; there are no
/// local fallbacks.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  /// True while `register` runs, so the auth listener does not race it
  /// (the account exists in Auth a moment before its profile document).
  bool _registering = false;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get isStaff => _user?.isStaff ?? false;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (_registering) return;

      if (firebaseUser == null) {
        _user = null;
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      try {
        _user = await _authService.getUserModel(firebaseUser.uid);
        if (_user == null) {
          _state = AuthState.unauthenticated;
        } else if (!firebaseUser.emailVerified) {
          _state = AuthState.emailNotVerified;
        } else {
          _state = AuthState.authenticated;
        }
      } catch (e) {
        _user = null;
        _state = AuthState.error;
        _errorMessage = _getReadableError(e);
      }
      notifyListeners();
    });
  }

  /// Registers a new ALU account. Returns true when the account was created
  /// and the verification email was sent.
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    String? studentId,
    String? department,
  }) async {
    _registering = true;
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        studentId: studentId,
        department: department,
      );
      _state = AuthState.emailNotVerified;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _state = AuthState.error;
      _errorMessage = _getReadableError(e);
      notifyListeners();
      return false;
    } finally {
      _registering = false;
    }
  }

  /// Signs in. The user only reaches [AuthState.authenticated] once the
  /// email address has been verified.
  Future<bool> signIn({required String email, required String password}) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      await _authService.reloadUser();
      _state = _authService.isEmailVerified
          ? AuthState.authenticated
          : AuthState.emailNotVerified;
      notifyListeners();
      return true;
    } catch (e) {
      _user = null;
      _state = AuthState.error;
      _errorMessage = _getReadableError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _state = AuthState.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _getReadableError(e);
    }
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      _errorMessage = null;
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = _getReadableError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerification() async {
    try {
      await _authService.resendVerificationEmail();
      return true;
    } catch (e) {
      _errorMessage = _getReadableError(e);
      notifyListeners();
      return false;
    }
  }

  /// Reloads the Firebase user and promotes the session to authenticated
  /// if the email has now been verified.
  Future<bool> checkEmailVerified() async {
    try {
      await _authService.reloadUser();
    } catch (e) {
      _errorMessage = _getReadableError(e);
      notifyListeners();
      return false;
    }
    if (_authService.isEmailVerified) {
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Staff only: loads a reporter's profile (name and email) so staff can
  /// follow up on a report. Students get `null`, and the Firestore rules
  /// refuse the read as well.
  Future<UserModel?> lookupReporter(String uid) async {
    if (!isStaff) return null;
    return _authService.getUserModel(uid);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getReadableError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'user-not-found':
          return error.message ?? 'No account found with this email address.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        case 'permission-denied':
          return 'You do not have permission to do that.';
        default:
          return error.message ?? 'An error occurred. Please try again.';
      }
    }
    return error.toString();
  }
}
