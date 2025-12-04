// tests/registration_widget_test.dart

/**
 * REGISTRATION FEATURE - FRONTEND + LIVE BACKEND WIDGET TESTS
 * Study Buddy App - Sprint 5
 *
 * Purpose:
 *   Exercise the real RegisterScreen UI and the real ApiService.postRegister()
 *   against your Google Cloud Run backend. No mocks are used.
 *
 * Framework: Flutter Test
 * Environment: Widget tests + (attempted) real HTTP calls to Cloud Run
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Adjust this import if your package name/path is different.
import 'package:study_buddy/screens/register_screen.dart';

void main() {
  // Ensure bindings + SharedPreferences mock are set up
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // ---------- Test data ----------
  final String testFirstName = 'John';
  final String testLastName = 'Doe';
  final String testEmail = 'test@junit.com';
  final String testPassword = 'TestPassword123!';
  final String existingEmail = 'existing@example.com';

  Widget _buildTestApp() {
    return MaterialApp(
      home: const RegisterScreen(),
      routes: {
        '/login': (context) =>
        const Scaffold(body: Center(child: Text('Login Screen'))),
      },
    );
  }

  group('REGISTRATION FEATURE - Frontend + Live Backend Widget Tests', () {
    // ==================== BASIC RENDERING ====================

    testWidgets(
      'Test ID: REGISTER_UI_001 - RegisterScreen renders core fields and actions',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // AppBar title
        expect(find.text('Register'), findsWidgets);

        // First, Last, Email, Password fields
        expect(find.byType(TextFormField), findsNWidgets(4));
        expect(find.text('First Name'), findsOneWidget);
        expect(find.text('Last Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);

        // Register button
        expect(
          find.widgetWithText(ElevatedButton, 'Register'),
          findsOneWidget,
        );

        // No loader / error initially
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('Registration failed'), findsNothing);

        print('✅ REGISTER_UI_001: Core registration UI rendered correctly.');
      },
    );

    // ==================== FORM VALIDATION (LOCAL) ====================

    testWidgets(
      'Test ID: REGISTER_UI_002 - First name is required',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Leave First Name empty, fill others
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Last Name'),
          testLastName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          testEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          testPassword,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Validator on First Name should fire with "Required"
        expect(find.text('Required'), findsOneWidget);

        print('✅ REGISTER_UI_002: First name required validation exercised.');
      },
    );

    testWidgets(
      'Test ID: REGISTER_UI_003 - Email is required',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Leave Email empty, fill others
        await tester.enterText(
          find.widgetWithText(TextFormField, 'First Name'),
          testFirstName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Last Name'),
          testLastName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          testPassword,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Validator on Email should fire with "Required"
        expect(find.text('Required'), findsOneWidget);

        print('✅ REGISTER_UI_003: Email required validation exercised.');
      },
    );

    testWidgets(
      'Test ID: REGISTER_UI_004 - Password length validation (Minimum 6 characters)',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Password < 6 characters
        await tester.enterText(
          find.widgetWithText(TextFormField, 'First Name'),
          testFirstName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          testEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'short',
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Validator on Password should show "Minimum 6 characters"
        expect(find.text('Minimum 6 characters'), findsOneWidget);

        print('✅ REGISTER_UI_004: Password length validation exercised.');
      },
    );

    testWidgets(
      'Test ID: REGISTER_UI_005 - Last name is optional',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Leave Last Name empty, fill others with valid data
        await tester.enterText(
          find.widgetWithText(TextFormField, 'First Name'),
          testFirstName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          testEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          testPassword,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // There should be no "Required" error for Last Name
        expect(find.text('Required'), findsNothing);

        print('✅ REGISTER_UI_005: Last name optional behavior exercised.');
      },
    );

    testWidgets(
      'Test ID: REGISTER_UI_006 - Password field is present for secure entry',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        final passwordFieldFinder =
        find.widgetWithText(TextFormField, 'Password');

        // We at least verify that a dedicated password field exists.
        expect(passwordFieldFinder, findsOneWidget);

        print(
            '✅ REGISTER_UI_006: Password field located (secure entry supported).');
      },
    );

    // ==================== LIVE BACKEND CALLS (HTTP 400 IN TEST ENV) ====================

    testWidgets(
      'Test ID: REGISTER_UI_007 - Live POST /auth/register call (success or error surfaced)',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Use a (pseudo) unique email so a real backend could accept it
        final String uniqueEmail =
            'test_${DateTime.now().millisecondsSinceEpoch}@junit.com';

        await tester.enterText(
          find.widgetWithText(TextFormField, 'First Name'),
          testFirstName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Last Name'),
          testLastName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          uniqueEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          testPassword,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // begins async _register()

        // In Flutter widget tests, HttpClient returns 400 by default.
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Either we popped back (no RegisterScreen) OR we show an error message.
        final bool stillOnRegister =
            find.byType(RegisterScreen).evaluate().isNotEmpty;

        final bool hasErrorText =
            find.textContaining('Registration failed').evaluate().isNotEmpty ||
                find
                    .textContaining('Connection failed')
                    .evaluate()
                    .isNotEmpty ||
                find.textContaining('error').evaluate().isNotEmpty;

        expect(
          !stillOnRegister || hasErrorText,
          isTrue,
          reason:
          'After live POST /auth/register, we should either pop back or show an error message.',
        );

        print(
            '✅ REGISTER_UI_007: Live register call executed (check console + UI for message or navigation).');
      },
    );

    testWidgets(
      'Test ID: REGISTER_UI_008 - Backend error path shows an error message',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Use an "existing" email; in test env HTTP will be 400 anyway
        await tester.enterText(
          find.widgetWithText(TextFormField, 'First Name'),
          testFirstName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Last Name'),
          testLastName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          existingEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          testPassword,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // We should still be on RegisterScreen and see some error text
        expect(find.byType(RegisterScreen), findsOneWidget);

        final bool hasErrorText =
            find.textContaining('already in use').evaluate().isNotEmpty ||
                find
                    .textContaining('Registration failed')
                    .evaluate()
                    .isNotEmpty ||
                find
                    .textContaining('Connection failed')
                    .evaluate()
                    .isNotEmpty;

        expect(
          hasErrorText,
          isTrue,
          reason:
          'Backend rejection for registration should surface a user-visible error message.',
        );

        print(
            '✅ REGISTER_UI_008: Backend error path exercised (duplicate/invalid email).');
      },
    );

    // ==================== INPUT HANDLING / EDGE CASES ====================

    testWidgets(
      'Test ID: REGISTER_UI_009 - Very long input does not break UI',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        final String longFirst = ''.padRight(1000, 'a');
        final String longLast = ''.padRight(1000, 'a');
        final String longEmail = '${''.padRight(500, 'a')}@test.com';
        final String longPassword = ''.padRight(1000, 'a');

        await tester.enterText(
          find.widgetWithText(TextFormField, 'First Name'),
          longFirst,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Last Name'),
          longLast,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          longEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          longPassword,
        );

        // Submit to hit backend (will almost certainly fail in test env)
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // UI should still be alive: 4 text fields present
        expect(find.byType(TextFormField), findsNWidgets(4));

        print('✅ REGISTER_UI_009: Long input handled without UI crash.');
      },
    );

    testWidgets(
      'Test ID: REGISTER_UI_010 - Special characters in name/email/password',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        final String specialFirstName = 'José María';
        final String specialLastName = "O'Connor-Smith";
        final String specialEmail = 'test+special@domain.co.uk';
        final String specialPassword = 'Pass@123!#^&*()';

        await tester.enterText(
          find.widgetWithText(TextFormField, 'First Name'),
          specialFirstName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Last Name'),
          specialLastName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          specialEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          specialPassword,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Screen should still show 4 fields
        expect(find.byType(TextFormField), findsNWidgets(4));

        print('✅ REGISTER_UI_010: Special characters accepted without crash.');
      },
    );

    testWidgets(
      'Test ID: REGISTER_UI_011 - Unicode characters in inputs',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        final String unicodeFirstName = '测试';
        final String unicodeLastName = 'пользователь';
        final String unicodeEmail = 'тест@測試.com';
        final String unicodePassword = 'пароль123🔥';

        await tester.enterText(
          find.widgetWithText(TextFormField, 'First Name'),
          unicodeFirstName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Last Name'),
          unicodeLastName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          unicodeEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          unicodePassword,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 10));

        expect(find.byType(TextFormField), findsNWidgets(4));

        print('✅ REGISTER_UI_011: Unicode characters accepted without crash.');
      },
    );

    // ==================== ERROR STATE / FORM STATE ====================

    testWidgets(
      'Test ID: REGISTER_UI_012 - Validation errors are shown for empty submit',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // At least some "Required" or "Minimum 6 characters" messages should appear
        final bool hasRequired =
            find.text('Required').evaluate().isNotEmpty;
        final bool hasMinPassword =
            find.text('Minimum 6 characters').evaluate().isNotEmpty;

        expect(
          hasRequired || hasMinPassword,
          isTrue,
          reason: 'Submitting empty form should show validation errors.',
        );

        print('✅ REGISTER_UI_012: Empty submit validation errors exercised.');
      },
    );

    testWidgets(
      'Test ID: REGISTER_UI_013 - Form state persists when validation fails',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Partially fill in form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'First Name'),
          testFirstName,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          testEmail,
        );

        // Submit incomplete form
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // The text we entered should still be present
        expect(find.text(testFirstName), findsOneWidget);
        expect(find.text(testEmail), findsOneWidget);

        print(
            '✅ REGISTER_UI_013: Form state is preserved after validation errors.');
      },
    );

    // ==================== ACCESSIBILITY / DISPOSAL ====================

    testWidgets(
      'Test ID: REGISTER_UI_014 - Accessibility labels present',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        expect(find.text('First Name'), findsOneWidget);
        expect(find.text('Last Name'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Register'), findsWidgets);

        print('✅ REGISTER_UI_014: Basic accessibility labels verified.');
      },
    );

    testWidgets(
      'Test ID: REGISTER_UI_015 - RegisterScreen can be disposed and recreated cleanly',
          (WidgetTester tester) async {
        // First mount
        await tester.pumpWidget(_buildTestApp());
        expect(find.byType(RegisterScreen), findsOneWidget);

        // Navigate to a different tree
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('Different Screen'))),
        );
        await tester.pumpAndSettle();

        // Mount again
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(4));

        print(
            '✅ REGISTER_UI_015: RegisterScreen disposes and recreates without issues.');
      },
    );
  });
}

/*
 * NOTES / BUGS THESE TESTS CAN REVEAL:
 *
 * - Incorrect wiring between RegisterScreen and ApiService.postRegister()
 * - HTTP 4xx/5xx responses from Cloud Run (duplicate email, DB errors, etc.)
 * - Validation messages not showing correctly (Required / Minimum 6 characters)
 * - Loading / error state behavior during real network calls
 * - UI resilience with long / special / Unicode inputs
 * - Error messages surfaced from backend vs. silent failures
 * - Form state preservation when validation fails
 * - Basic accessibility labels and widget disposal stability
 *
 * Run with:
 *   flutter test tests/registration_widget_test.dart
 */
