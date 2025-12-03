import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/ai_tutor_screen.dart';
import 'screens/chat_list_screen.dart';  // ✅ Added ChatListScreen import
import 'screens/register_screen.dart';
import 'screens/study_session_screen.dart';
import 'screens/class_grades_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/dashboard':
        return MaterialPageRoute(settings: settings, builder: (_) => const DashboardScreen(),);
      case '/assignments':
        return MaterialPageRoute(builder: (_) => const AssignmentsScreen());
      case '/study':
        return MaterialPageRoute(builder: (_) => const StudySessionScreen());
      case '/ai-chats':  // ✅ Dashboard → ChatListScreen (shows list of chats)
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ChatListScreen(),
        );
      case '/ai':  // ✅ ChatListScreen → AiTutorScreen (specific chat)
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AiTutorScreen(),
        );
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/grades':
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