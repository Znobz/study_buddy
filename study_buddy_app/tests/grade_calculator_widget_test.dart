// tests/grade_calculator_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Keep this import the same as in your project
import 'package:study_buddy/screens/class_grades_screen.dart';

void main() {
  const String testAssignmentName = 'Homework 1';
  const String testAssignmentNameEdited = 'Homework 1 (Edited)';
  const String testGrade = '90';
  const String testGradeEdited = '100';
  const String newGradeTypeName = 'Projects';
  const String editedGradeTypeName = 'Updated Type';

  Widget _wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('GRADE CALCULATOR FEATURE - Frontend Widget Tests (Real ClassGradesScreen)', () {
    // ============= GC_UI_001: BASIC RENDERING =============

    testWidgets(
      'Test ID: GC_UI_001 - ClassGradesScreen renders core widgets and summary bar',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithMaterial(const ClassGradesScreen()));

        // AppBar
        expect(find.text('Class Grades'), findsOneWidget);

        // Top grade-entry form
        expect(find.text('Type (e.g. Homework)'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Assignment Name'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Grade (%)'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Add Grade'), findsOneWidget);

        // Grade-type management entry point
        expect(find.text('Add Grade Type'), findsOneWidget);

        // Bottom summary card
        expect(find.textContaining('Current Average:'), findsOneWidget);
        expect(find.textContaining('Total Weight:'), findsOneWidget);

        print('✅ GC_UI_001: Core UI + summary card rendered.');
      },
    );

    // ============= GC_UI_002: ADDING A GRADE =============

    testWidgets(
      'Test ID: GC_UI_002 - Adding a grade shows it under a grade type',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithMaterial(const ClassGradesScreen()));

        // Fill in assignment fields
        final nameField =
            find.widgetWithText(TextField, 'Assignment Name').first;
        final gradeField =
            find.widgetWithText(TextField, 'Grade (%)').first;

        await tester.enterText(nameField, testAssignmentName);
        await tester.enterText(gradeField, testGrade);
        await tester.pump();

        // Add grade
        final addGradeButton =
        find.widgetWithText(ElevatedButton, 'Add Grade');
        await tester.tap(addGradeButton);
        await tester.pumpAndSettle();

        // Expand first grade-type card so we can see rows
        final firstExpansion = find.byType(ExpansionTile).first;
        await tester.tap(firstExpansion);
        await tester.pumpAndSettle();

        // New assignment row should be visible
        expect(find.text(testAssignmentName), findsOneWidget);
        expect(find.textContaining('$testGrade%'), findsOneWidget);

        print('✅ GC_UI_002: Added grade appears under first grade type.');
      },
    );

    // ============= GC_UI_003: DELETING A GRADE =============

    testWidgets(
      'Test ID: GC_UI_003 - Deleting the only grade removes it from the list',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithMaterial(const ClassGradesScreen()));

        // Add one grade
        final nameField =
            find.widgetWithText(TextField, 'Assignment Name').first;
        final gradeField =
            find.widgetWithText(TextField, 'Grade (%)').first;

        await tester.enterText(nameField, testAssignmentName);
        await tester.enterText(gradeField, testGrade);
        await tester.pump();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Grade'));
        await tester.pumpAndSettle();

        // Expand first grade-type card
        final firstExpansion = find.byType(ExpansionTile).first;
        await tester.tap(firstExpansion);
        await tester.pumpAndSettle();

        // Confirm row exists
        final rowFinder = find.ancestor(
          of: find.text(testAssignmentName),
          matching: find.byType(ListTile),
        );
        expect(rowFinder, findsOneWidget);

        // Tap the delete icon in that row (not the header delete)
        final rowDelete = find.descendant(
          of: rowFinder,
          matching: find.byIcon(Icons.delete),
        );
        await tester.tap(rowDelete);
        await tester.pumpAndSettle();

        // Row should be gone
        expect(find.text(testAssignmentName), findsNothing);

        // For at least one type with no grades, "No assignments yet" should show
        expect(find.text('No assignments yet'), findsWidgets);

        print('✅ GC_UI_003: Grade deletion removed the row and restored empty state.');
      },
    );

    // ============= GC_UI_004: EDITING GRADE TYPE (HEADER) =============

    testWidgets(
      'Test ID: GC_UI_004 - Edit Grade Type dialog opens and updates header',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithMaterial(const ClassGradesScreen()));

        // There should be at least one grade-type card with an edit icon
        final editTypeButton = find.byIcon(Icons.edit).first;
        expect(editTypeButton, findsOneWidget);

        await tester.tap(editTypeButton);
        await tester.pumpAndSettle();

        // Dialog content
        expect(find.text('Edit Grade Type'), findsOneWidget);
        final typeNameField =
        find.widgetWithText(TextField, 'Type Name');
        final weightField =
        find.widgetWithText(TextField, 'Weight (%)');

        expect(typeNameField, findsOneWidget);
        expect(weightField, findsOneWidget);

        // Change the name and weight
        await tester.enterText(typeNameField, editedGradeTypeName);
        await tester.enterText(weightField, '25.0');
        await tester.pump();

        // Save
        final saveButton = find.widgetWithText(TextButton, 'Save');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Dialog closed
        expect(find.text('Edit Grade Type'), findsNothing);

        // Header text should now contain the updated type name
        expect(find.textContaining('$editedGradeTypeName - Avg:'), findsOneWidget);

        print('✅ GC_UI_004: Grade type header updated via Edit Grade Type dialog.');
      },
    );

    // ============= GC_UI_005: ADDING A GRADE TYPE + SUMMARY PERSISTENCE =============

    testWidgets(
      'Test ID: GC_UI_005 - Adding a grade type via Add Grade Type card',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithMaterial(const ClassGradesScreen()));

        // Summary labels should be present before any actions
        expect(find.textContaining('Current Average:'), findsOneWidget);
        expect(find.textContaining('Total Weight:'), findsOneWidget);

        // Open "Add Grade Type" form
        final addTypeTile = find.text('Add Grade Type');
        await tester.tap(addTypeTile);
        await tester.pumpAndSettle();

        // Fill form
        final typeNameField =
        find.widgetWithText(TextField, 'Grade Type Name');
        final weightField =
        find.widgetWithText(TextField, 'Weight (%)');

        await tester.enterText(typeNameField, newGradeTypeName);
        await tester.enterText(weightField, '15');
        await tester.pump();

        // Submit
        final addButton = find.widgetWithText(ElevatedButton, 'Add');
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        // New grade-type card should exist
        expect(find.textContaining('$newGradeTypeName - Avg:'), findsOneWidget);

        // Summary labels still present after modification
        expect(find.textContaining('Current Average:'), findsOneWidget);
        expect(find.textContaining('Total Weight:'), findsOneWidget);

        print('✅ GC_UI_005: Add Grade Type flow works and summary persists.');
      },
    );

    // ============= GC_UI_006: RESPONSIVE LAYOUT =============

    testWidgets(
      'Test ID: GC_UI_006 - ClassGradesScreen responsive on small and large screens',
          (WidgetTester tester) async {
        // Small screen
        await tester.binding.setSurfaceSize(const Size(360, 640));
        await tester.pumpWidget(_wrapWithMaterial(const ClassGradesScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Class Grades'), findsOneWidget);
        expect(find.byType(TextField), findsWidgets);

        // Large screen
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpWidget(_wrapWithMaterial(const ClassGradesScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Class Grades'), findsOneWidget);
        expect(find.byType(TextField), findsWidgets);

        // Reset
        await tester.binding.setSurfaceSize(null);

        print('✅ GC_UI_006: Layout works on phone-sized and large surfaces.');
      },
    );

    // ============= GC_UI_007: RAPID ADDITIONS STABILITY =============

    testWidgets(
      'Test ID: GC_UI_007 - Rapid grade additions do not crash the screen',
          (WidgetTester tester) async {
        await tester.pumpWidget(_wrapWithMaterial(const ClassGradesScreen()));

        final nameField =
            find.widgetWithText(TextField, 'Assignment Name').first;
        final gradeField =
            find.widgetWithText(TextField, 'Grade (%)').first;
        final addGradeButton =
        find.widgetWithText(ElevatedButton, 'Add Grade');

        // Rapidly add several grades
        for (int i = 0; i < 5; i++) {
          await tester.enterText(nameField, 'HW $i');
          await tester.enterText(gradeField, '8$i');
          await tester.pump();

          await tester.tap(addGradeButton);
          await tester.pumpAndSettle();
        }

        // Expand first type to reveal assignments
        final firstExpansion = find.byType(ExpansionTile).first;
        await tester.tap(firstExpansion);
        await tester.pumpAndSettle();

        // Screen should still be alive and show HW rows
        expect(find.text('No assignments yet'), findsNothing);
        expect(find.textContaining('HW '), findsWidgets);

        print('✅ GC_UI_007: Screen remained stable under rapid grade additions.');
      },
    );
  });
}
