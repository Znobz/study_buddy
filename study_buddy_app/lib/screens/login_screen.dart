import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final data = await api.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 🔍 DEBUG: Print the full API response
      print('🔍 LOGIN DEBUG - Full API response: $data');

      setState(() => _isLoading = false);

      if (data != null) {
        if (data['error'] != null) {
          setState(() => _errorMessage = data['error']);
        } else if (data['token'] != null) {
          final user = data['user'];

          // 🔍 DEBUG: Print the user object specifically
          print('🔍 LOGIN DEBUG - User object: $user');
          print('🔍 LOGIN DEBUG - User first_name: ${user?['first_name']}');

          final userId = user['user_id'];
          final firstName = user['first_name'];

          // 🔍 DEBUG: Print what we're about to pass to dashboard
          print('🔍 LOGIN DEBUG - About to navigate with userId: $userId, firstName: $firstName');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Welcome back, ${user['first_name']}!')),
          );

          Navigator.pushReplacementNamed(context, '/dashboard', arguments: {
            'userId': userId,
            'firstName': firstName, // Use the extracted variable
          });
        } else {
          setState(() => _errorMessage = 'Invalid email or password.');
        }
      } else {
        setState(() => _errorMessage = 'Invalid email or password.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Connection failed. Please check if the server is running and database is set up.';
      });
      print('🔍 LOGIN ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Email is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Password is required' : null,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14)),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text("Don’t have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
