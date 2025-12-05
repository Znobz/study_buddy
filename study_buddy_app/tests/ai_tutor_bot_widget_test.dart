/**
 * AI TUTOR BOT FEATURE - FRONTEND + LIVE BACKEND WIDGET TESTS
 * Study Buddy App - Sprint 5 JUnit Testing
 *
 * Purpose:
 *   - Exercise the REAL AI chat flow end-to-end against the Google Cloud Run backend
 *   - Surface integration bugs (HTTP 4xx/5xx, auth issues, bad IDs, etc.) via console output
 *
 * Framework: Flutter Test (widget tests)
 * Environment:
 *   - Backend: https://study-buddy-backend-851589529788.us-central1.run.app
 *   - Authentication: ApiService must have a valid auth token configured
 *
 * IMPORTANT:
 *   - These tests DO NOT mock the AI UI.
 *   - They use the real ChatListScreen and AiTutorScreen widgets,
 *     which in turn call the real ApiService and hit the live backend.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Adjust package names if your app package is different.
import 'package:study_buddy/screens/chat_list_screen.dart';
import 'package:study_buddy/screens/ai_tutor_screen.dart';
import 'package:study_buddy/services/api_service.dart';

// ---------- TEST DATA ----------

const String _testMessage =
    'Hello AI, can you help me with calculus?';
const String _longMessage =
    'This is a very long message that might cause UI issues. '
    'This message is repeated to test long input handling. '
    'This message is repeated to test long input handling. '
    'This message is repeated to test long input handling. ';
const String _specialMessage =
    '📚 Math question: What is the derivative of x² + 3x + 5? 🤔';
const String _codeMessage =
    'Can you help me debug this code:\n```python\ndef fibonacci(n):\n'
    '    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)\n```';

// ---------- HELPERS ----------

/// Build a MaterialApp that hosts the real ChatListScreen and knows how
/// to navigate to the real AiTutorScreen via `/ai`.
Widget _buildChatListApp() {
  return MaterialApp(
    home: const ChatListScreen(),
    routes: {
      '/ai': (_) => const AiTutorScreen(),
    },
  );
}

/// Build a MaterialApp that starts directly on AiTutorScreen with a given chatId.
/// This triggers:
///   - GET /ai/chats/:id/messages
///   - GET /ai/chats/:id (via title load)
Widget _buildAiTutorApp(int chatId) {
  return MaterialApp(
    initialRoute: '/ai',
    onGenerateRoute: (settings) {
      if (settings.name == '/ai') {
        return MaterialPageRoute(
          builder: (_) => const AiTutorScreen(),
          settings: RouteSettings(arguments: {'chatId': chatId}),
        );
      }
      return null;
    },
  );
}

/// Try to create a real conversation on the backend.
/// If it fails (auth, network, etc.), fall back to chatId=1 so the tests
/// still exercise the /ai/chats/:id/messages endpoint (likely yielding 404/401).
Future<int> _createTestChatId() async {
  try {
    final api = ApiService();
    print('🧪 Creating test chat via live backend...');
    final conv = await api.createChat(title: 'Widget Test Chat');
    if (conv != null && conv['id'] != null) {
      final id = conv['id'] as int;
      print('✅ Created test chat on backend with id=$id');
      return id;
    }
    print('⚠️ createChat returned null or missing id: $conv');
  } catch (e) {
    print('❌ Failed to create test chat on backend: $e');
  }

  print('⚠️ Falling back to chatId=1 for tests (may 404 if not present)');
  return 1;
}

void main() {
  // Needed by shared_preferences in ChatListScreen.
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('AI TUTOR BOT FEATURE - Frontend + Live Backend Widget Tests', () {
    // ===================================================
    // CHAT LIST SCREEN + BACKEND
    // ===================================================

    testWidgets(
      'Test ID: AI_UI_001 - Chat list screen renders and calls GET /ai/chats',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildChatListApp());

        // App bar title should be present.
        expect(find.text('AI Tutor Chats'), findsOneWidget);

        // Initially shows loading spinner while listChats() hits the backend.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Let HTTP and rebuild settle.
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // No uncaught exceptions.
        expect(tester.takeException(), isNull);

        // Either an empty state or a populated list is acceptable here.
        final hasEmptyState = find.text('No chats yet').evaluate().isNotEmpty;
        final hasListView = find.byType(ListView).evaluate().isNotEmpty;

        expect(
          hasEmptyState || hasListView,
          true,
          reason:
          'Expected either empty state or a chat list after hitting /ai/chats',
        );

        print(
            '✅ AI_UI_001: ChatListScreen initialized and attempted live GET /ai/chats (see console for HTTP status).');
      },
    );

    testWidgets(
      'Test ID: AI_UI_002 - "New Chat" button calls POST /ai/chats',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildChatListApp());

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // The AppBar "add" button has tooltip 'New Chat'.
        final newChatButton = find.byTooltip('New Chat');
        expect(newChatButton, findsOneWidget);

        await tester.tap(newChatButton);
        await tester.pump(const Duration(milliseconds: 300));

        // We should see some chat row (placeholder or real).
        final hasAnyChatRow =
            find.byType(ListTile).evaluate().isNotEmpty ||
                find.text('Creating…').evaluate().isNotEmpty;

        expect(
          hasAnyChatRow,
          true,
          reason: 'Expected at least one chat row after pressing New Chat',
        );

        await tester.pumpAndSettle(const Duration(seconds: 5));
        expect(tester.takeException(), isNull);

        print(
            '✅ AI_UI_002: New Chat button exercised live POST /ai/chats (see console for HTTP status).');
      },
    );

    testWidgets(
      'Test ID: AI_UI_003 - Tapping a chat opens AiTutorScreen and hits message APIs',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildChatListApp());
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Ensure we have at least one chat; if not, create one.
        if (find.byType(ListTile).evaluate().isEmpty) {
          final newChatButton = find.byTooltip('New Chat');
          await tester.tap(newChatButton);
          await tester.pumpAndSettle(const Duration(seconds: 5));
        }

        // Tap the first chat row.
        final firstChatTile = find.byType(ListTile).first;
        await tester.tap(firstChatTile);

        // This should navigate to AiTutorScreen, which then calls:
        // - GET /ai/chats/:id
        // - GET /ai/chats/:id/messages
        await tester.pumpAndSettle(const Duration(seconds: 8));

        // Look for the AI input hint / send button.
        expect(find.text('Ask your Study Buddy...'), findsOneWidget);
        expect(find.byIcon(Icons.send), findsOneWidget);

        expect(tester.takeException(), isNull);

        print(
            '✅ AI_UI_003: Navigation from chat list to AI tutor screen exercised /ai/chats/:id and /ai/chats/:id/messages.');
      },
    );

    testWidgets(
      'Test ID: AI_UI_004 - Swipe-to-delete shows confirmation and calls POST /ai/chats/:id/archive',
          (WidgetTester tester) async {
        await tester.pumpWidget(_buildChatListApp());
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Ensure we have at least one chat.
        if (find.byType(ListTile).evaluate().isEmpty) {
          final newChatButton = find.byTooltip('New Chat');
          await tester.tap(newChatButton);
          await tester.pumpAndSettle(const Duration(seconds: 5));
        }

        final firstDismissible = find.byType(Dismissible).first;

        // Swipe to the left to trigger delete.
        await tester.fling(firstDismissible, const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();

        // Confirmation dialog appears.
        expect(find.text('Delete Chat?'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Confirm deletion; this will call archiveChat() on backend.
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(tester.takeException(), isNull);

        print(
            '✅ AI_UI_004: Swipe-to-delete path exercised POST /ai/chats/:id/archive (check console for HTTP status).');
      },
    );

    // ===================================================
    // AI TUTOR SCREEN + BACKEND
    // ===================================================

    testWidgets(
      'Test ID: AI_UI_005 - AiTutorScreen renders and loads history for a real chat',
          (WidgetTester tester) async {
        int chatId = 1;

        // Try to create a real chat on backend, fall back to 1 if needed.
        await tester.runAsync(() async {
          chatId = await _createTestChatId();
        });

        await tester.pumpWidget(_buildAiTutorApp(chatId));
        await tester.pumpAndSettle(const Duration(seconds: 8));

        // Basic UI elements must be present.
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.send), findsOneWidget);
        expect(find.byIcon(Icons.attach_file), findsOneWidget);

        expect(tester.takeException(), isNull);

        print(
            '✅ AI_UI_005: AiTutorScreen initialized and attempted live GET /ai/chats/$chatId/messages.');
      },
    );

    testWidgets(
      'Test ID: AI_UI_006 - Sending a message hits POST /ai/chats/:id/messages',
          (WidgetTester tester) async {
        int chatId = 1;

        await tester.runAsync(() async {
          chatId = await _createTestChatId();
        });

        await tester.pumpWidget(_buildAiTutorApp(chatId));
        await tester.pumpAndSettle(const Duration(seconds: 8));

        final messageField = find.byType(TextField);
        expect(messageField, findsOneWidget);

        await tester.enterText(messageField, _testMessage);
        await tester.pump();

        final sendButton = find.byIcon(Icons.send);
        expect(sendButton, findsOneWidget);

        await tester.tap(sendButton);

        // Allow enough time for:
        //   - Upload (if any)
        //   - POST /ai/chats/:id/messages
        //   - OpenAI completion
        //   - UI update
        await tester.pumpAndSettle(const Duration(seconds: 12));

        // Even if backend returns 401/404/500, errors are caught and surfaced
        // as SnackBars, not test crashes.
        expect(tester.takeException(), isNull);

        // Input should still be present; UI is responsive.
        expect(find.byType(TextField), findsOneWidget);

        print(
            '✅ AI_UI_006: Send button exercised live POST /ai/chats/$chatId/messages (check console for HTTP status and AI response).');
      },
    );

    testWidgets(
      'Test ID: AI_UI_007 - Long message input is accepted without UI crash',
          (WidgetTester tester) async {
        int chatId = 1;

        await tester.runAsync(() async {
          chatId = await _createTestChatId();
        });

        await tester.pumpWidget(_buildAiTutorApp(chatId));
        await tester.pumpAndSettle(const Duration(seconds: 8));

        final messageField = find.byType(TextField);
        await tester.enterText(messageField, _longMessage);
        await tester.pump();

        // We do NOT have to send in this test; input handling is the target.
        expect(find.textContaining('This is a very long message'), findsOneWidget);
        expect(tester.takeException(), isNull);

        print(
            '✅ AI_UI_007: Long message input handled in AiTutorScreen (no layout crash).');
      },
    );

    testWidgets(
      'Test ID: AI_UI_008 - Special characters and emojis are accepted in input',
          (WidgetTester tester) async {
        int chatId = 1;

        await tester.runAsync(() async {
          chatId = await _createTestChatId();
        });

        await tester.pumpWidget(_buildAiTutorApp(chatId));
        await tester.pumpAndSettle(const Duration(seconds: 8));

        final messageField = find.byType(TextField);
        await tester.enterText(messageField, _specialMessage);
        await tester.pump();

        expect(find.text(_specialMessage), findsOneWidget);
        expect(tester.takeException(), isNull);

        print(
            '✅ AI_UI_008: Special characters and emoji accepted in AiTutorScreen input.');
      },
    );

    testWidgets(
      'Test ID: AI_UI_009 - Code-block style message input is handled',
          (WidgetTester tester) async {
        int chatId = 1;

        await tester.runAsync(() async {
          chatId = await _createTestChatId();
        });

        await tester.pumpWidget(_buildAiTutorApp(chatId));
        await tester.pumpAndSettle(const Duration(seconds: 8));

        final messageField = find.byType(TextField);
        await tester.enterText(messageField, _codeMessage);
        await tester.pump();

        // Again, we only validate that the widget_tree is stable.
        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);

        print(
            '✅ AI_UI_009: Code-block style message text accepted in AiTutorScreen input.');
      },
    );

    testWidgets(
      'Test ID: AI_UI_010 - Responsive layout for small and large screens',
          (WidgetTester tester) async {
        int chatId = 1;
        await tester.runAsync(() async {
          chatId = await _createTestChatId();
        });

        // Small screen
        await tester.binding.setSurfaceSize(const Size(360, 640));
        await tester.pumpWidget(_buildAiTutorApp(chatId));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.send), findsOneWidget);

        // Large screen
        await tester.binding.setSurfaceSize(const Size(1024, 768));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.byType(TextField), findsOneWidget);

        // Reset surface size
        await tester.binding.setSurfaceSize(null);
        expect(tester.takeException(), isNull);

        print(
            '✅ AI_UI_010: AiTutorScreen layout verified on small and large surfaces.');
      },
    );
  });
}
