import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_reporter/models/user_model.dart';
import 'package:campus_incident_reporter/models/incident_model.dart';
import 'package:campus_incident_reporter/widgets/status_badge.dart';
import 'package:campus_incident_reporter/widgets/category_chip.dart';

void main() {
  group('UserModel Role & Domain Validation Tests', () {
    test('Student user model initializes with student role', () {
      final user = UserModel(
        uid: 'user123',
        email: 'john.doe@alustudent.com',
        displayName: 'John Doe',
        role: UserRole.student,
        createdAt: DateTime.now(),
        studentId: 'ALU-2024-001',
      );

      expect(user.isStudent, isTrue);
      expect(user.isStaff, isFalse);
      expect(user.role, equals(UserRole.student));
    });

    test('Staff user model initializes with staff role and department', () {
      final staff = UserModel(
        uid: 'staff456',
        email: 'admin.ops@alueducation.com',
        displayName: 'Admin Ops',
        role: UserRole.staff,
        createdAt: DateTime.now(),
        department: 'Facilities Management',
      );

      expect(staff.isStaff, isTrue);
      expect(staff.isStudent, isFalse);
      expect(staff.department, equals('Facilities Management'));
    });
  });

  group('Incident Model & Category Tests', () {
    test('Incident categories provide appropriate display names and icons', () {
      expect(IncidentCategory.brokenFacility.displayName, 'Broken Facility');
      expect(IncidentCategory.waterShortage.displayName, 'Water Shortage');
      expect(
        IncidentCategory.electricityOutage.displayName,
        'Electricity Outage',
      );
      expect(IncidentCategory.sanitation.displayName, 'Sanitation');
      expect(IncidentCategory.safety.displayName, 'Safety Concern');

      expect(IncidentCategory.brokenFacility.iconData, Icons.build_outlined);
      expect(
        IncidentCategory.waterShortage.iconData,
        Icons.water_drop_outlined,
      );
      expect(IncidentCategory.electricityOutage.iconData, Icons.bolt_outlined);
    });

    test('Incident statuses have appropriate display names', () {
      expect(IncidentStatus.pending.displayName, 'Pending');
      expect(IncidentStatus.underReview.displayName, 'Under Review');
      expect(IncidentStatus.inProgress.displayName, 'In Progress');
      expect(IncidentStatus.resolved.displayName, 'Resolved');
      expect(IncidentStatus.dismissed.displayName, 'Dismissed');
    });
  });

  group('Widget Tests', () {
    testWidgets('StatusBadge renders correct status text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusBadge(status: IncidentStatus.inProgress)),
        ),
      );

      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('CategoryChip renders category icon and display name', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: IncidentCategory.waterShortage,
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Water Shortage'), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

      await tester.tap(find.byType(CategoryChip));
      expect(tapped, isTrue);
    });
  });
}
