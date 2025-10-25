import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/ai_tutor_screen.dart';
import 'screens/register_screen.dart';
import 'screens/study_session_screen.dart';

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
      case '/ai':
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final userId = args['userId'] as int? ?? 1;
        return MaterialPageRoute(builder: (_) => AiTutorScreen(userId: userId));
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}


