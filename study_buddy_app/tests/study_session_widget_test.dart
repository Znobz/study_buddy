// tests/study_session_widget_test.dart

/**
 * STUDY SESSION FEATURE - FRONTEND WIDGET + SERVICE TESTS
 * Study Buddy App - Sprint 5
 *
 * Scope:
 *   - This test suite targets ONLY the local/frontend implementation of
 *     the study session feature.
 *   - StudySessionScreen uses SessionService + SharedPreferences for:
 *       • Focus/break timer
 *       • Streak tracking
 *       • Total focus/break minutes
 *   - The /sessions backend endpoints are currently not used by this screen,
 *     so no live HTTP calls are tested here.
 *
 * Framework: Flutter Test
 * Environment: Widget tests + SharedPreferences mock
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:study_buddy/screens/study_session_screen.dart';
import 'package:study_buddy/services/session_service.dart';

void main() {
  // Ensure bindings + SharedPreferences mock are set up once.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('STUDY SESSION FEATURE - Frontend Widget Tests', () {
    setUp(() {
      // Fresh in-memory SharedPreferences for each test.
      SharedPreferences.setMockInitialValues({});
    });

    // ==================== BASIC RENDERING ====================

    testWidgets(
      'Test ID: SESS_UI_001 - Initial UI renders focus mode, streak, timer, and controls',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StudySessionScreen()),
        );
        await tester.pumpAndSettle();

        // Mode header
        expect(find.text('Focus Mode'), findsOneWidget);

        // Streak label (e.g., "🔥 1-day streak", value may vary)
        expect(find.textContaining('streak'), findsOneWidget);

        // Initial timer 00:00
        expect(find.text('00:00'), findsOneWidget);

        // Control buttons
        expect(find.text('Start'), findsOneWidget);
        expect(find.text('Take Break'), findsOneWidget);
        expect(find.text('End'), findsOneWidget);

        // Stats line defaults to 0m
        expect(
          find.text('Total Focus: 0m  •  Total Break: 0m'),
          findsOneWidget,
        );

        print('✅ SESS_UI_001: Initial StudySessionScreen UI verified.');
      },
    );

    // ==================== TIMER BEHAVIOR (FOCUS) ====================

    testWidgets(
      'Test ID: SESS_UI_002 - Start and pause focus timer increments correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StudySessionScreen()),
        );
        await tester.pumpAndSettle();

        // Initial time
        expect(find.text('00:00'), findsOneWidget);

        // Start focus timer
        await tester.tap(find.text('Start'));
        await tester.pump(); // triggers _startTimer
        await tester.pump(const Duration(seconds: 3)); // simulate 3 seconds

        // Timer should show 00:03
        expect(find.text('00:03'), findsOneWidget);

        // Pause timer
        await tester.tap(find.text('Pause'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 3)); // additional time should not advance

        // Timer should remain at 00:03
        expect(find.text('00:03'), findsOneWidget);

        print('✅ SESS_UI_002: Focus timer start/pause behavior verified.');
      },
    );

    // ==================== BREAK MODE BEHAVIOR ====================

    testWidgets(
      'Test ID: SESS_UI_003 - Break mode toggles and uses separate timer',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StudySessionScreen()),
        );
        await tester.pumpAndSettle();

        // Initial state: Focus Mode
        expect(find.text('Focus Mode'), findsOneWidget);

        // Switch to Break Mode
        await tester.tap(find.text('Take Break'));
        await tester.pump();

        expect(find.text('Break Mode'), findsOneWidget);

        // Start break timer
        await tester.tap(find.text('Start'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));

        // Timer should show 00:04 for breakSeconds
        expect(find.text('00:04'), findsOneWidget);

        print('✅ SESS_UI_003: Break mode timer behavior verified.');
      },
    );

    // ==================== BREAK REMINDER + AWARD MESSAGES ====================

    testWidgets(
      'Test ID: SESS_UI_004 - 20-minute break reminder and 40-minute award messages appear',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: StudySessionScreen()),
        );
        await tester.pumpAndSettle();

        // Start focus timer
        await tester.tap(find.text('Start'));
        await tester.pump();

        // Fast-forward 20 minutes (1200 seconds) for break reminder
        await tester.pump(const Duration(seconds: 1200));

        // Break reminder message should appear
        expect(
          find.textContaining('You\'ve been studying for 20 minutes'),
          findsOneWidget,
        );

        // Fast-forward another 20 minutes (total 40) for award
        await tester.pump(const Duration(seconds: 1200));

        // Award message should appear
        expect(
          find.textContaining('You studied 40 minutes'),
          findsOneWidget,
        );

        print(
          '✅ SESS_UI_004: 20-min break reminder and 40-min award messages verified.',
        );
      },
    );

    // ==================== END SESSION / STATS PERSISTENCE ====================

    testWidgets(
      'Test ID: SESS_UI_005 - End session saves stats and resets timers',
          (WidgetTester tester) async {
        // Seed initial totals to 0
        SharedPreferences.setMockInitialValues({
          'totalFocus': 0,
          'totalBreak': 0,
        });

        await tester.pumpWidget(
          const MaterialApp(home: StudySessionScreen()),
        );
        await tester.pumpAndSettle();

        // Grab the state to manipulate raw seconds for a shorter test
        final state =
        tester.state(find.byType(StudySessionScreen)) as dynamic;

        // Simulate 5 minutes focus, 2 minutes break
        state.seconds = 300; // 5 minutes
        state.breakSeconds = 120; // 2 minutes
        await tester.pump();

        // Tap End button (calls _endSession internally)
        await tester.tap(find.text('End'));
        await tester.pumpAndSettle();

        // Timers should be reset to 00:00
        expect(find.text('00:00'), findsOneWidget);

        // Stats line should reflect saved minutes (5 and 2)
        expect(
          find.text('Total Focus: 5m  •  Total Break: 2m'),
          findsOneWidget,
        );

        print(
          '✅ SESS_UI_005: End session saves stats and resets timers correctly.',
        );
      },
    );

    // ==================== STREAK LOGIC ====================

    testWidgets(
      'Test ID: SESS_UI_006 - Streak increments when last study date was yesterday',
          (WidgetTester tester) async {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        // Simulate a previous streak of 3 days, last studied yesterday.
        SharedPreferences.setMockInitialValues({
          'streak': 3,
          'lastStudyDate': yesterday.toIso8601String(),
        });

        await tester.pumpWidget(
          const MaterialApp(home: StudySessionScreen()),
        );
        await tester.pumpAndSettle();

        // _loadStreak should bump streak from 3 to 4.
        expect(find.textContaining('4-day streak'), findsOneWidget);

        print('✅ SESS_UI_006: Streak increment logic verified.');
      },
    );
  });

  // ==================== SESSION SERVICE UNIT TESTS ====================

  group('STUDY SESSION FEATURE - SessionService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Test ID: SESS_SVC_001 - saveSessionStats accumulates totals correctly',
          () async {
        // Seed existing totals
        SharedPreferences.setMockInitialValues({
          'totalFocus': 10,
          'totalBreak': 5,
        });

        final service = SessionService();

        // Add +3 focus minutes and +2 break minutes
        await service.saveSessionStats(3, 2);

        final stats = await service.loadSessionStats();
        expect(stats['totalFocus'], 13); // 10 + 3
        expect(stats['totalBreak'], 7);  // 5 + 2

        print('✅ SESS_SVC_001: saveSessionStats accumulation verified.');
      },
    );

    test(
      'Test ID: SESS_SVC_002 - resetStats clears stored totals',
          () async {
        // Seed some totals
        SharedPreferences.setMockInitialValues({
          'totalFocus': 20,
          'totalBreak': 10,
        });

        final service = SessionService();

        await service.resetStats();
        final stats = await service.loadSessionStats();

        expect(stats['totalFocus'], 0);
        expect(stats['totalBreak'], 0);

        print('✅ SESS_SVC_002: resetStats clears stored totals.');
      },
    );
  });
}

/*
 * RUNNING THESE TESTS:
 *   flutter test tests/study_session_widget_test.dart
 *
 * WHAT THESE TESTS COVER FOR SPRINT DOCUMENTATION:
 *  - UI behavior for focus/break timers, including start/pause and mode toggle.
 *  - Local streak tracking based on last study date.
 *  - Local persistence of total focus/break minutes via SessionService.
 *  - In-app motivational UX: 20-minute break reminder and 40-minute achievement award.
 *
 * NOTE:
 *  - No backend /sessions API calls are exercised here because the current
 *    StudySessionScreen implementation does not invoke ApiService.getSessions()
 *    / addSession() / deleteSession(). This feature is effectively a local
 *    study timer + stats tracker backed by SharedPreferences.
 */
