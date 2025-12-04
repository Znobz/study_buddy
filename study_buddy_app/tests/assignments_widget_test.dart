/**
 * ASSIGNMENTS FEATURE - FRONTEND WIDGET TEST SCRIPT (REAL IMPLEMENTATION)
 * Study Buddy App - Sprint 5 Widget Tests
 *
 * Purpose: Discover UI/UX bugs and mismatches against the real Assignments module.
 *
 * This version is based on the actual code:
 * - backend/src/controllers/assignmentController.js
 * - backend/src/routes/assignmentRoutes.js
 * - lib/services/api_service.dart
 * - lib/screens/assignment_screen.dart
 *
 * Key real behaviors reflected here:
 * - "Assignments" screen with grouped list by priority (High/Medium/Low).
 * - Add FAB opens a real AlertDialog-based "New Assignment" form.
 * - Priority values: low/medium/high (backend enums, UI labels Low/Medium/High).
 * - Status values: pending/in_progress/completed (UI labels Not Started/In Progress/Completed).
 * - Due date required, formatted as yyyy-MM-dd and sent to backend.
 * - Optional file attachment support.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Adjust this import to your actual package name if necessary.
import 'package:study_buddy/screens/assignments_screen.dart';

void main() {
  // ==================== TEST DATA SETUP ====================

  const String testTitle = 'Math Homework';
  const String testDescription =
      'Complete exercises 1-10 from chapter 5 (real UI test)';
  const String longTitle =
      'Very long assignment title that might cause UI layout issues and overflow in the cards and dialogs';
  const String longDescription =
      'This is a very long description that might cause UI issues. '
      'This is a very long description that might cause UI issues. '
      'This is a very long description that might cause UI issues. '
      'This is a very long description that might cause UI issues. ';
  const String emptyString = '';
  const String specialCharsTitle = '📚 Assignment #1: "Test" & Review (50%)';

  // ==================== HELPER FUNCTIONS ====================

  /// Pump the real AssignmentsScreen inside a MaterialApp.
  Future<void> pumpAssignmentsScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AssignmentsScreen(),
    ));
    // First frame (may still be loading assignments from API)
    await tester.pump();
  }

  /// Pump AssignmentsScreen and then inject fake assignments directly into its state.
  ///
  /// This avoids depending on a live backend but still drives the *real* list UI
  /// and grouping logic.
  Future<void> pumpScreenWithFakeAssignments(WidgetTester tester) async {
    await pumpAssignmentsScreen(tester);

    // Access the private state via dynamic so we can seed assignments.
    final state = tester.state(find.byType(AssignmentsScreen)) as dynamic;

    state.setState(() {
      state.isLoading = false;
      state.assignments = [
        {
          'assignment_id': 1,
          'course_id': 1,
          'user_id': 1,
          'title': 'High Priority Assignment',
          'description': 'Realistic seeded assignment - high priority',
          'due_date': '2024-12-20',
          'priority': 'high',
          'status': 'pending',
          'file_path': 'assignments/test_high.pdf',
          'file_name': 'test_high.pdf',
        },
        {
          'assignment_id': 2,
          'course_id': 1,
          'user_id': 1,
          'title': 'Medium Priority Assignment',
          'description': 'Seeded medium priority assignment',
          'due_date': '2024-12-22',
          'priority': 'medium',
          'status': 'in_progress',
          'file_path': '',
          'file_name': null,
        },
        {
          'assignment_id': 3,
          'course_id': 1,
          'user_id': 1,
          'title': 'Low Priority Assignment',
          'description': 'Seeded low priority assignment',
          'due_date': '2024-12-25',
          'priority': 'low',
          'status': 'completed',
          'file_path': 'assignments/test_low.pdf',
          'file_name': 'test_low.pdf',
        },
      ];
    });

    await tester.pump();
  }

  /// Open the real "New Assignment" dialog via the + FAB on the Assignments screen.
  Future<void> openNewAssignmentDialog(WidgetTester tester) async {
    await pumpAssignmentsScreen(tester);

    // There are multiple FABs; the main add FAB has the plus icon.
    final addFab = find.byIcon(Icons.add);
    expect(addFab, findsOneWidget);

    await tester.tap(addFab);
    await tester.pumpAndSettle();

    // The real dialog title is "New Assignment".
    expect(find.text('New Assignment'), findsOneWidget);
  }

  group('ASSIGNMENTS FEATURE - Frontend Widget Tests', () {
    // ==================== ASSIGNMENTS SCREEN TESTS ====================

    testWidgets('Test ID: ASSIGN_UI_001 - Assignments screen renders correctly',
            (WidgetTester tester) async {
          await pumpAssignmentsScreen(tester);

          // Verify AppBar and key FABs exist regardless of backend state.
          expect(find.text('Assignments'), findsOneWidget);

          // Main add FAB (+)
          expect(find.byIcon(Icons.add), findsOneWidget);

          // Notification-related FABs (these have specific icons/colors/tooltips).
          expect(find.byIcon(Icons.flash_on), findsOneWidget); // Test Notifications
          expect(find.byIcon(Icons.notifications_active), findsOneWidget);
          expect(find.byIcon(Icons.bug_report), findsOneWidget);

          // At this moment body may still be loading; we only assert top-level UI.
          print('✅ ASSIGN_UI_001: Assignments screen initialization test passed');
        });

    testWidgets('Test ID: ASSIGN_UI_002 - Add assignment button functionality',
            (WidgetTester tester) async {
          await pumpAssignmentsScreen(tester);

          final addFab = find.byIcon(Icons.add);
          expect(addFab, findsOneWidget);

          await tester.tap(addFab);
          await tester.pumpAndSettle();

          // BUG CHECK: The real implementation should show the New Assignment dialog.
          expect(find.text('New Assignment'), findsOneWidget);
          expect(find.text('Title'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);

          print('✅ ASSIGN_UI_002: Add assignment button opens real dialog');
        });

    testWidgets('Test ID: ASSIGN_UI_003 - Assignment list display',
            (WidgetTester tester) async {
          await pumpScreenWithFakeAssignments(tester);

          // Real UI groups assignments by priority into sections with headers.
          expect(find.text('High Priority'), findsOneWidget);
          expect(find.text('Medium Priority'), findsOneWidget);
          expect(find.text('Low Priority'), findsOneWidget);

          // Each seeded assignment should appear with its title.
          expect(find.text('High Priority Assignment'), findsOneWidget);
          expect(find.text('Medium Priority Assignment'), findsOneWidget);
          expect(find.text('Low Priority Assignment'), findsOneWidget);

          // "Due: yyyy-MM-dd" formatting is enforced in _buildAssignmentCard.
          expect(find.textContaining('Due:'), findsWidgets);

          print('✅ ASSIGN_UI_003: Assignment list grouped display test passed');
        });

    testWidgets('Test ID: ASSIGN_UI_004 - Delete assignment functionality',
            (WidgetTester tester) async {
          await pumpScreenWithFakeAssignments(tester);

          // Open popup menu on the first card.
          final moreMenu = find.byIcon(Icons.more_vert).first;
          expect(moreMenu, findsOneWidget);

          await tester.tap(moreMenu);
          await tester.pumpAndSettle();

          final deleteItem = find.text('Delete');
          expect(deleteItem, findsOneWidget);

          await tester.tap(deleteItem);
          await tester.pump();

          // BUG CHECK (documented, not asserted):
          // - No confirmation dialog is shown before deletion.
          // - UI relies on backend + reload to remove the item.
          // These are potential UX issues to highlight in your test report.

          print('✅ ASSIGN_UI_004: Delete assignment menu path exercised');
        });

    // ==================== NEW ASSIGNMENT DIALOG TESTS ====================

    testWidgets('Test ID: ASSIGN_UI_005 - New assignment dialog renders correctly',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          // Real form fields and labels.
          expect(find.text('Title'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);
          expect(find.text('Priority'), findsOneWidget);
          expect(find.text('Status'), findsOneWidget);

          // Default priority/status values are medium & pending (Not Started).
          expect(find.text('Medium'), findsOneWidget);
          expect(find.text('Not Started'), findsOneWidget);

          // Date row and attachment UI.
          expect(find.text('No date selected'), findsOneWidget);
          expect(find.byIcon(Icons.calendar_today), findsOneWidget);
          expect(find.text('Attachment (optional)'), findsOneWidget);
          expect(find.text('Add attachment'), findsOneWidget);

          // Actions
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Save'), findsOneWidget);

          print('✅ ASSIGN_UI_005: New assignment dialog initialization test passed');
        });

    testWidgets('Test ID: ASSIGN_UI_006 - Title field functionality',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          final titleField = find.widgetWithText(TextField, 'Title');
          expect(titleField, findsOneWidget);

          await tester.enterText(titleField, testTitle);
          await tester.pump();

          // BUG CHECK: Title text should echo correctly in the field.
          expect(find.text(testTitle), findsOneWidget);

          print('✅ ASSIGN_UI_006: Title field accepts input correctly');
        });

    testWidgets('Test ID: ASSIGN_UI_007 - Title field validation',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          final titleField = find.widgetWithText(TextField, 'Title');
          expect(titleField, findsOneWidget);

          // Case 1: Empty title + missing date should trigger validation SnackBar.
          await tester.enterText(titleField, emptyString);
          await tester.tap(find.text('Save'));
          await tester.pump(); // show SnackBar

          expect(find.text('Please fill all fields'), findsOneWidget);

          // Case 2: Very long title should still be accepted into the field.
          await tester.enterText(titleField, longTitle);
          await tester.pump();

          expect(find.textContaining('Very long assignment title'), findsOneWidget);

          // NOTE for report:
          // The message "Please fill all fields" is slightly misleading because
          // Description and Attachment are actually optional in the backend.

          print('✅ ASSIGN_UI_007: Title field validation and long-text handling checked');
        });

    testWidgets('Test ID: ASSIGN_UI_008 - Description field functionality',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          final descField = find.widgetWithText(TextField, 'Description');
          expect(descField, findsOneWidget);

          // Enter and verify description text is accepted and rendered.
          await tester.enterText(descField, testDescription);
          await tester.pump();

          expect(find.text(testDescription), findsOneWidget);

          print('✅ ASSIGN_UI_008: Description field basic functionality test passed');
        });

    testWidgets('Test ID: ASSIGN_UI_009 - Description field with long text',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          final descField = find.widgetWithText(TextField, 'Description');
          await tester.enterText(descField, longDescription);
          await tester.pump();

          // We do not assert visual overflow in tests, but we check that the field
          // still exists and holds the text without crashing.
          expect(find.byType(TextField), findsAtLeastNWidgets(2));

          print('✅ ASSIGN_UI_009: Long description handling exercised');
        });

    testWidgets('Test ID: ASSIGN_UI_010 - Priority dropdown functionality',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          // Priority dropdown is the first DropdownButtonFormField.
          final priorityDropdown =
              find.byType(DropdownButtonFormField<String>).first;
          expect(priorityDropdown, findsOneWidget);

          // Default selected label should be "Medium".
          expect(find.text('Medium'), findsWidgets);

          await tester.tap(priorityDropdown);
          await tester.pumpAndSettle();

          // BUG CHECK: All three priority labels should be available.
          expect(find.text('Low'), findsWidgets);
          expect(find.text('High'), findsWidgets);

          // Select High priority and ensure label updates.
          await tester.tap(find.text('High').last);
          await tester.pumpAndSettle();

          expect(find.text('High'), findsWidgets);

          print('✅ ASSIGN_UI_010: Priority dropdown options and selection verified');
        });

    testWidgets('Test ID: ASSIGN_UI_011 - Status dropdown functionality',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          // Status dropdown is the second DropdownButtonFormField<String>.
          final statusDropdown =
          find.byType(DropdownButtonFormField<String>).at(1);
          expect(statusDropdown, findsOneWidget);

          // Default label "Not Started" maps to backend value "pending".
          expect(find.text('Not Started'), findsWidgets);

          await tester.tap(statusDropdown);
          await tester.pumpAndSettle();

          // BUG CHECK: All three user-facing labels should be present.
          expect(find.text('In Progress'), findsWidgets);
          expect(find.text('Completed'), findsWidgets);

          // Select In Progress.
          await tester.tap(find.text('In Progress').last);
          await tester.pumpAndSettle();

          expect(find.text('In Progress'), findsWidgets);

          print('✅ ASSIGN_UI_011: Status dropdown options and selection verified');
        });

    testWidgets('Test ID: ASSIGN_UI_012 - Due date picker functionality',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          // Check the "No date selected" text and calendar icon row exists.
          expect(find.text('No date selected'), findsOneWidget);
          expect(find.byIcon(Icons.calendar_today), findsOneWidget);

          // We *do not* actually open the material date picker here because it
          // requires the material localization and date picker widgets; instead,
          // we verify the tap target is wired and does not crash synchronously.
          await tester.tap(find.byIcon(Icons.calendar_today));
          await tester.pump();

          // BUG CHECK (for your manual report):
          // - Date is mandatory; UI enforces this along with title before saving.

          print('✅ ASSIGN_UI_012: Due date picker UI wiring exercised');
        });

    testWidgets('Test ID: ASSIGN_UI_013 - File attachment functionality',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          // Verify attachment area and button exist.
          expect(find.text('Attachment (optional)'), findsOneWidget);
          expect(find.byIcon(Icons.attach_file), findsWidgets);
          expect(find.text('Add attachment'), findsOneWidget);

          // NOTE: We intentionally do NOT tap the button here because it would
          // invoke FilePicker, which depends on platform channels and is not
          // available in pure widget tests without additional mocking.

          print('✅ ASSIGN_UI_013: Attachment controls present in dialog');
        });

    testWidgets('Test ID: ASSIGN_UI_014 - Cancel button functionality',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          final cancelButton = find.text('Cancel');
          expect(cancelButton, findsOneWidget);

          await tester.tap(cancelButton);
          await tester.pumpAndSettle();

          // BUG CHECK: Cancel should close the dialog without persisting anything.
          expect(find.text('New Assignment'), findsNothing);

          print('✅ ASSIGN_UI_014: Cancel button closes New Assignment dialog');
        });

    testWidgets('Test ID: ASSIGN_UI_015 - Save button functionality',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          // Fill title but deliberately leave date empty to exercise validation.
          await tester.enterText(
              find.widgetWithText(TextField, 'Title'), testTitle);
          await tester.pump();

          final saveButton = find.text('Save');
          expect(saveButton, findsOneWidget);

          await tester.tap(saveButton);
          await tester.pump(); // show SnackBar

          // Since date is still null, we expect validation, not a backend call.
          expect(find.text('Please fill all fields'), findsOneWidget);

          print(
              '✅ ASSIGN_UI_015: Save button triggers validation when required fields missing');
        });

    testWidgets('Test ID: ASSIGN_UI_016 - Save without required fields',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          // No title, no date.
          await tester.tap(find.text('Save'));
          await tester.pump();

          // Same validation path as above.
          expect(find.text('Please fill all fields'), findsOneWidget);

          // NOTE: Backend expects userId + title + due_date; the UI prevents
          // invalid requests here, so this confirms the gatekeeping works.

          print('✅ ASSIGN_UI_016: Save blocked when required fields are empty');
        });

    testWidgets('Test ID: ASSIGN_UI_017 - Special characters in title',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          await tester.enterText(
              find.widgetWithText(TextField, 'Title'), specialCharsTitle);
          await tester.pump();

          // Verify the field can hold emojis and special characters.
          expect(find.text(specialCharsTitle), findsOneWidget);

          print('✅ ASSIGN_UI_017: Title field accepts special characters and emojis');
        });

    testWidgets('Test ID: ASSIGN_UI_018 - Form state management',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          // Fill title and description.
          await tester.enterText(
              find.widgetWithText(TextField, 'Title'), testTitle);
          await tester.enterText(
              find.widgetWithText(TextField, 'Description'), testDescription);
          await tester.pump();

          // Change priority from Medium to High.
          await tester.tap(find.byType(DropdownButtonFormField<String>).first);
          await tester.pumpAndSettle();
          await tester.tap(find.text('High').last);
          await tester.pumpAndSettle();

          // All entered values remain while interacting with dropdowns.
          expect(find.text(testTitle), findsOneWidget);
          expect(find.text(testDescription), findsOneWidget);
          expect(find.text('High'), findsWidgets);

          print('✅ ASSIGN_UI_018: Form state preserved across interactions');
        });

    // ==================== RESPONSIVE DESIGN TESTS ====================

    testWidgets(
        'Test ID: ASSIGN_UI_019 - Responsive design for different screen sizes',
            (WidgetTester tester) async {
          // Small/mobile-ish screen
          await tester.binding.setSurfaceSize(const Size(360, 640));
          await openNewAssignmentDialog(tester);

          expect(find.text('New Assignment'), findsOneWidget);

          // Larger/desktop-like screen
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          await tester.pump();

          // Dialog should still be visible and usable.
          expect(find.text('New Assignment'), findsOneWidget);

          // Reset
          await tester.binding.setSurfaceSize(null);

          print(
              '✅ ASSIGN_UI_019: New Assignment dialog appears correctly on multiple screen sizes');
        });

    // ==================== ACCESSIBILITY TESTS ====================

    testWidgets('Test ID: ASSIGN_UI_020 - Accessibility features',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          // Basic accessible labels are present via text and InputDecoration.labelText.
          expect(find.text('Title'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);
          expect(find.text('Priority'), findsOneWidget);
          expect(find.text('Status'), findsOneWidget);

          expect(find.text('Cancel'), findsOneWidget);
          expect(find.text('Save'), findsOneWidget);

          // For your report: You can mention that further a11y improvements could
          // include semantics for priority/status chips in the list.

          print('✅ ASSIGN_UI_020: Basic accessibility labels verified');
        });

    // ==================== PERFORMANCE / INTERACTION STABILITY ====================

    testWidgets(
        'Test ID: ASSIGN_UI_021 - Performance with rapid form interactions',
            (WidgetTester tester) async {
          await openNewAssignmentDialog(tester);

          final titleField = find.widgetWithText(TextField, 'Title');

          for (int i = 0; i < 10; i++) {
            await tester.enterText(titleField, 'Rapid test $i');
            await tester.pump();
          }

          // No crashes and final text visible.
          expect(find.text('Rapid test 9'), findsOneWidget);

          print('✅ ASSIGN_UI_021: Dialog remains stable under rapid text entry');
        });

    testWidgets(
        'Test ID: ASSIGN_UI_022 - Assignment list scrolling performance',
            (WidgetTester tester) async {
          await pumpScreenWithFakeAssignments(tester);

          // The grouped list is implemented as a ListView.
          final listView = find.byType(ListView);
          expect(listView, findsOneWidget);

          await tester.fling(listView, const Offset(0, -300), 1000);
          await tester.pumpAndSettle();

          // Still present and no exceptions => smooth enough for UI script testing.
          expect(find.byType(ListView), findsOneWidget);

          print('✅ ASSIGN_UI_022: List scrolling interaction exercised');
        });
  });
}

/**
 * ASSIGNMENTS FEATURE BUG DISCOVERY SUMMARY (ALIGNED WITH REAL IMPLEMENTATION):
 *
 * These tests are written against the real AssignmentsScreen + backend contract.
 * From this script you can derive the following discussion points for your report:
 *
 * VALIDATION & UX:
 * - Title and due date are both required; the dialog blocks Save when either is missing
 *   and shows "Please fill all fields" (slightly misleading because description/attachment
 *   are optional according to the backend schema).
 * - Special characters and long texts are accepted in fields, but long labels and long
 *   descriptions could cause truncation/overflow in cards on smaller screens.
 *
 * PRIORITY & STATUS MAPPING:
 * - UI uses low/medium/high and pending/in_progress/completed which match the database enums.
 * - User-facing labels ("High Priority", "Not Started", "In Progress", etc.) are consistent
 *   with these internal values.
 *
 * DATE & BACKEND FORMAT:
 * - UI always formats dates as yyyy-MM-dd before sending them; backend normalizes them to
 *   datetime (YYYY-MM-DD 00:00:00) and enforces presence of due_date.
 *
 * FILE ATTACHMENTS:
 * - Attachment controls exist and are integrated with a file picker and backend upload route.
 *   Widget tests do not exercise the actual FilePicker, but you can inspect that the button
 *   and icon states exist and that attachments are surfaced in the list via "View attachment"
 *   style buttons.
 *
 * LIST VIEW & GROUPING:
 * - Assignments are grouped by priority (High/Medium/Low) and sorted by due date within each
 *   group; the test seeds sample data to verify section headers and chips render correctly.
 * - Delete uses a popup menu; there is no confirmation dialog before deletion, which is a
 *   UX consideration worth mentioning.
 *
 * RESPONSIVE & ACCESSIBILITY:
 * - The dialog renders on both small (360x640) and large (1200x800) surfaces.
 * - Basic labels are present for form fields and actions; more advanced semantics could be
 *   added for assistive technologies.
 *
 * PERFORMANCE:
 * - Form remains stable under rapid text entry.
 * - List view scrolls without layout exceptions when seeded with multiple items.
 *
 * RUNNING TESTS:
 * flutter test test/assignments_widget_test.dart
 */
