import 'package:flutter/material.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/ai_tutor_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/study_session_screen.dart';
import 'screens/class_grades_screen.dart'; // ✅ Added for Class Grades

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());

      case '/assignments':
        return MaterialPageRoute(builder: (_) => const AssignmentsScreen());

      case '/study':
        return MaterialPageRoute(builder: (_) => const StudySessionScreen());

      case '/ai-chats': // ✅ Chat list screen
        return MaterialPageRoute(builder: (_) => const ChatListScreen());

      case '/ai': // ✅ AI Tutor screen with arguments
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final userId = args['userId'] as int? ?? 1;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AiTutorScreen(userId: userId),
        );

      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case '/grades': // ✅ Class Grades route
        return MaterialPageRoute(builder: (_) => const ClassGradesScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}