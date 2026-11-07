import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporter/utils/validators.dart';

void main() {
  group('ALU email validation', () {
    test('accepts student and staff domains, ignoring case and spaces', () {
      expect(Validators.aluEmail('jane@alustudent.com'), isNull);
      expect(Validators.aluEmail(' Ops@AluEducation.com '), isNull);
    });

    test('rejects other domains and empty input', () {
      expect(Validators.aluEmail('jane@gmail.com'), isNotNull);
      expect(Validators.aluEmail('jane@alustudent.com.evil.io'), isNotNull);
      expect(Validators.aluEmail(''), isNotNull);
      expect(Validators.aluEmail(null), isNotNull);
    });

    test('detects the staff domain only for staff addresses', () {
      expect(Validators.isStaffEmail('ops@alueducation.com'), isTrue);
      expect(Validators.isStaffEmail('jane@alustudent.com'), isFalse);
    });
  });

  group('Password validation', () {
    test('requires the minimum length', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
      expect(Validators.password(''), isNotNull);
    });
  });

  group('Incident form validation', () {
    test('title must be 5-100 characters', () {
      expect(Validators.incidentTitle('Hi'), isNotNull);
      expect(Validators.incidentTitle('Broken tap'), isNull);
      expect(Validators.incidentTitle('x' * 101), isNotNull);
    });

    test('description must be 15-1000 characters', () {
      expect(Validators.incidentDescription('too short'), isNotNull);
      expect(
        Validators.incidentDescription('The tap in the washroom leaks'),
        isNull,
      );
      expect(Validators.incidentDescription('x' * 1001), isNotNull);
    });
  });
}
