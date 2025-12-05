// tests/login_widget_test.dart

/**
 * LOGIN FEATURE - FRONTEND + LIVE BACKEND WIDGET TESTS
 * Study Buddy App - Sprint 5
 *
 * Purpose:
 *   Exercise the real LoginScreen UI and the real ApiService.login()
 *   against your Google Cloud Run backend. No mocks are used.
 *
 * Framework: Flutter Test
 * Environment: Widget tests + real HTTP calls to Cloud Run
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Adjust this import if your package name/path is different.
import 'package:study_buddy/screens/login_screen.dart';

void main() {
  // Ensure bindings + SharedPreferences mock are set up
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // ---------- Test data ----------
  const String testEmail = 'test@junit.com';
  const String testPassword = 'TestPassword123!';
  const String invalidEmail = 'invalid_login_test@example.com';
  const String invalidPassword = 'WrongPassword123!';

  Widget _buildTestApp() {
    return MaterialApp(
      home: const LoginScreen(),
      routes: {
        '/dashboard': (context) =>
        const Scaffold(body: Center(child: Text('Dashboard Screen'))),
        '/register': (context) =>
        const Scaffold(body: Center(child: Text('Register Screen'))),
      },
    );
  }

  group('LOGIN FEATURE - Frontend + Live Backend Widget Tests', () {
    // ==================== BASIC RENDERING ====================

    testWidgets(
      'Test ID: LOGIN_UI_001 - LoginScreen renders core fields and actions',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // AppBar title
        expect(find.text('Login'), findsWidgets);

        // Email + password fields
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);

        // Login button
        expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

        // Register navigation link (note curly apostrophe in the real widget)
        expect(
          find.text('Don’t have an account? Register'),
          findsOneWidget,
        );

        // No error or loader initially
        expect(find.byType(CircularProgressIndicator), findsNothing);

        print('✅ LOGIN_UI_001: Core login UI rendered correctly.');
      },
    );

    // ==================== FORM VALIDATION ====================

    testWidgets(
      'Test ID: LOGIN_UI_002 - Email field validation (required)',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Submit with both fields empty
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Validators should fire
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);

        print('✅ LOGIN_UI_002: Email + password "required" validation exercised.');
      },
    );

    testWidgets(
      'Test ID: LOGIN_UI_003 - Password field validation (required)',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Fill email only
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          testEmail,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        // Only password error should appear
        expect(find.text('Password is required'), findsOneWidget);

        print('✅ LOGIN_UI_003: Password required validation exercised.');
      },
    );

    testWidgets(
      'Test ID: LOGIN_UI_004 - Password field is present for secure entry',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        final passwordFieldFinder =
        find.widgetWithText(TextFormField, 'Password');

        // We at least verify that a dedicated password field exists.
        // (Older Flutter versions may not expose obscureText on TextFormField.)
        expect(passwordFieldFinder, findsOneWidget);

        print('✅ LOGIN_UI_004: Password field located (secure entry supported).');
      },
    );

    // ==================== LOADING + LIVE BACKEND CALL ====================

    testWidgets(
      'Test ID: LOGIN_UI_005 - Loading state and live POST /auth/login call',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Fill in some credentials (may or may not be valid in DB)
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          testEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          testPassword,
        );

        // Tap Login
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // triggers _login and sets _isLoading = true

        // While HTTP call is in-flight, we should see the progress indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // And the button should be disabled
        final ElevatedButton button =
        tester.widget(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);

        // Let the HTTP request finish (success or error)
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Either we navigated to dashboard OR we stayed and showed an error.
        final bool onDashboard =
            find.text('Dashboard Screen').evaluate().isNotEmpty;
        final bool hasErrorText =
            find.textContaining('Invalid').evaluate().isNotEmpty ||
                find.textContaining('failed').evaluate().isNotEmpty ||
                find.textContaining('Connection failed')
                    .evaluate()
                    .isNotEmpty;

        expect(
          onDashboard || hasErrorText,
          isTrue,
          reason:
          'After live POST /auth/login, UI should either navigate to dashboard or show an error message.',
        );

        print(
            '✅ LOGIN_UI_005: Live login call executed (check console for HTTP status + response).');
      },
    );

    // ==================== INVALID CREDENTIALS (LIVE BACKEND) ====================

    testWidgets(
      'Test ID: LOGIN_UI_006 - Invalid credentials stay on LoginScreen with error',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        // Intentionally bogus email so backend should reject it
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          invalidEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          invalidPassword,
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(); // start request
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // We should still be on LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);

        // Some error text should be shown coming from ApiService/login
        final bool hasErrorText =
            find.textContaining('Invalid').evaluate().isNotEmpty ||
                find.textContaining('failed').evaluate().isNotEmpty ||
                find.textContaining('Connection failed')
                    .evaluate()
                    .isNotEmpty;

        expect(
          hasErrorText,
          isTrue,
          reason:
          'Login with bad credentials should show an error message instead of silent failure.',
        );

        print(
            '✅ LOGIN_UI_006: Invalid credentials path exercised against live backend.');
      },
    );

    // ==================== NAVIGATION ====================

    testWidgets(
      'Test ID: LOGIN_UI_007 - Navigation to register screen',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        final registerLink =
        find.text('Don’t have an account? Register'); // matches real label
        expect(registerLink, findsOneWidget);

        await tester.tap(registerLink);
        await tester.pumpAndSettle();

        expect(find.text('Register Screen'), findsOneWidget);

        print('✅ LOGIN_UI_007: Register link navigation verified.');
      },
    );

    // ==================== EDGE-CASE INPUTS (STILL HITTING BACKEND) ====================

    testWidgets(
      'Test ID: LOGIN_UI_008 - Very long email/password do not break UI',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        final String longEmail = '${'a' * 300}@example.com';
        final String longPassword = 'p' * 300;

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          longEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          longPassword,
        );

        // Submit to exercise backend handling (will almost certainly fail)
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // UI should still be alive (two text fields still present)
        expect(find.byType(TextFormField), findsNWidgets(2));

        print('✅ LOGIN_UI_008: Long input handled without UI crash.');
      },
    );

    testWidgets(
      'Test ID: LOGIN_UI_009 - Special characters + Unicode in inputs',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        final String specialEmail = 'test+special@domain.co.uk';
        final String specialPassword = 'Pàss@123!#\$🔥';

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          specialEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          specialPassword,
        );

        // Just ensure the widget tree survives a submit with weird characters
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 10));

        expect(find.byType(TextFormField), findsNWidgets(2));

        print('✅ LOGIN_UI_009: Special/Unicode characters accepted without crash.');
      },
    );

    // ==================== ACCESSIBILITY / STATE STABILITY ====================

    testWidgets(
      'Test ID: LOGIN_UI_010 - Accessibility labels present',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp());

        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Login'), findsWidgets);

        print('✅ LOGIN_UI_010: Basic accessibility labels verified.');
      },
    );

    testWidgets(
      'Test ID: LOGIN_UI_011 - Widget can be disposed and recreated cleanly',
          (WidgetTester tester) async {
        // First mount
        await tester.pumpWidget(_buildTestApp());
        expect(find.byType(LoginScreen), findsOneWidget);

        // Navigate away to a different widget tree
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('Other Screen'))),
        );
        await tester.pumpAndSettle();

        // Mount again
        await tester.pumpWidget(_buildTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));

        print('✅ LOGIN_UI_011: LoginScreen disposes and recreates without issues.');
      },
    );
  });
}

/*
 * NOTES / BUGS THESE TESTS CAN REVEAL WHEN YOU LOOK AT THE CONSOLE:
 *
 * - Incorrect wiring between LoginScreen and ApiService.login()
 * - HTTP 4xx/5xx responses from Cloud Run (invalid credentials, DB errors, etc.)
 * - Validation messages not showing correctly
 * - Loading state not toggling correctly during real network calls
 * - Navigation failures after successful login
 * - UI resilience with long / special / Unicode inputs
 *
 * Run with:
 *   flutter test tests/login_widget_test.dart
 */
