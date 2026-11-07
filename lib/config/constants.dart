/// Application-wide constants
class AppConstants {
  // App info
  static const String appName = 'CampusReport';
  static const String appTagline = 'Report. Track. Resolve.';
  static const String appVersion = '1.0.0';

  // ALU email domains
  static const String studentDomain = '@alustudent.com';
  static const String staffDomain = '@alueducation.com';

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String incidentsCollection = 'incidents';

  // Storage paths
  static const String incidentImagesPath = 'incidents';

  // Shown instead of the reporter's name on anonymous reports
  static const String anonymousName = 'Anonymous';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 1000;
  static const int maxImagesPerIncident = 5;

  // Campus locations
  static const List<String> campusLocations = [
    'Main Building - Ground Floor',
    'Main Building - 1st Floor',
    'Main Building - 2nd Floor',
    'Library',
    'Student Center',
    'Cafeteria',
    'Computer Lab A',
    'Computer Lab B',
    'Lecture Hall 1',
    'Lecture Hall 2',
    'Dormitory Block A',
    'Dormitory Block B',
    'Dormitory Block C',
    'Sports Complex',
    'Parking Area',
    'Garden / Outdoor Area',
    'Washrooms - Main Building',
    'Washrooms - Student Center',
    'Admin Office',
    'Faculty Offices',
    'Other',
  ];
}
