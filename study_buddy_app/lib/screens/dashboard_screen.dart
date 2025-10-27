import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic>? user;
  const DashboardScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] ?? user?['user_id'] ?? 1;
    final firstName = args?['firstName'] ?? user?['first_name'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $firstName 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.clearAuthToken();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _DashboardCard(
              title: 'Assignments',
              icon: Icons.book,
              color: Colors.deepPurple,
              onTap: () => Navigator.pushNamed(
                context,
                '/assignments',
                arguments: {'userId': userId},
              ),
            ),
            _DashboardCard(
              title: 'AI Tutor',
              icon: Icons.smart_toy,
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(
                context,
                '/ai-chats',
                arguments: {'userId': userId},
              ),
            ),
            _DashboardCard(
              title: 'Study Sessions',
              icon: Icons.schedule,
              color: Colors.indigo,
              onTap: () => Navigator.pushNamed(
                context,
                '/study',
                arguments: {'userId': userId},
              ),
            ),
            // 🟣 NEW CLASS GRADES CARD
            _DashboardCard(
              title: 'Class Grades',
              icon: Icons.school,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(
                context,
                '/grades',
                arguments: {'userId': userId},
              ),
            ),
            _DashboardCard(
              title: 'Profile',
              icon: Icons.person,
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(
                context,
                '/profile',
                arguments: {'userId': userId},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Color {
  Color get shade900 => Color.fromRGBO(
        (red + (255 - red) * 0.9).round(),
        (green + (255 - green) * 0.9).round(),
        (blue + (255 - blue) * 0.9).round(),
        opacity,
      );
}