import '../config/constants.dart';

/// Pure validation helpers shared by the forms and the services.
/// Every form validator returns `null` when the value is valid, or an
/// error message, so they can be passed straight to `TextFormField`.
class Validators {
  Validators._();

  static bool isStudentEmail(String email) =>
      email.trim().toLowerCase().endsWith(AppConstants.studentDomain);

  static bool isStaffEmail(String email) =>
      email.trim().toLowerCase().endsWith(AppConstants.staffDomain);

  static bool isAluEmail(String email) =>
      isStudentEmail(email) || isStaffEmail(email);

  static String? aluEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your ALU email';
    }
    if (!isAluEmail(value)) {
      return 'Must be an ${AppConstants.studentDomain} or ${AppConstants.staffDomain} address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  static String? incidentTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please provide a clear title';
    if (text.length < 5) return 'Title should be at least 5 characters';
    if (text.length > AppConstants.maxTitleLength) {
      return 'Title must be at most ${AppConstants.maxTitleLength} characters';
    }
    return null;
  }

  static String? incidentDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please describe the incident in detail';
    if (text.length < 15) {
      return 'Please provide more details (at least 15 characters)';
    }
    if (text.length > AppConstants.maxDescriptionLength) {
      return 'Description must be at most ${AppConstants.maxDescriptionLength} characters';
    }
    return null;
  }
}
