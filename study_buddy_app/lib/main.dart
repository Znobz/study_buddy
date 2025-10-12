import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'routes.dart'; // <--- THIS imports your AppRoutes class


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadAuthToken(); // keeps token between restarts
  
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
      onGenerateRoute: AppRoutes.generateRoute, // <--- This is key
      initialRoute:
          ApiService.authToken != null ? '/dashboard' : '/', // auto-login if token exists
    );
  }
}
