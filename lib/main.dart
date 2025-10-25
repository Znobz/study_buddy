import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'routes.dart';
import 'package:study_buddy/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(); // initialize notifications
  await ApiService.loadAuthToken(); // load saved login token

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Buddy',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      onGenerateRoute: AppRoutes.generateRoute,
      initialRoute:
          ApiService.authToken != null ? '/dashboard' : '/', // auto-login if token exists
    );
  }
}