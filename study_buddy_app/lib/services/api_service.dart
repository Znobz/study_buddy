import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://10.0.2.2:3000/api";
  static String? authToken;

  static Future<void> setAuthToken(String token) async {
    authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  static Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('authToken');
  }

  static Future<void> clearAuthToken() async {
    authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (authToken != null) headers['Authorization'] = 'Bearer $authToken';
    return headers;
  }

  Future<Map<String, dynamic>?> postRegister(
    String first, String last, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': first,
          'last_name': last,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Register failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }


  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // expected { message, token, user }
        if (data['token'] != null) {
          await setAuthToken(data['token']);
        }
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  Future<bool> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        await clearAuthToken();
        return true;
      } else {
        print('Logout failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }


  // 📚 ================= ASSIGNMENTS =================
  Future<List<dynamic>?> getAssignments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assignments'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Assignments fetch failed: ${response.body}');
      }
    } catch (e) {
      print('Error fetching assignments: $e');
    }
    return null;
  }

  Future<bool> addAssignment(String title, String description, String dueDate) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assignments'),
        headers: _headers(),
        body: jsonEncode({
          'title': title,
          'description': description,
          'due_date': dueDate,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding assignment: $e');
      return false;
    }
  }

  Future<bool> updateAssignment(int id, String title, String description, String dueDate, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assignments/$id'),
        headers: _headers(),
        body: jsonEncode({
          'title': title,
          'description': description,
          'due_date': dueDate,
          'status': status,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating assignment: $e');
      return false;
    }
  }

  Future<bool> deleteAssignment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/assignments/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting assignment: $e');
      return false;
    }
  }


  // 🕓 ================= STUDY SESSIONS =================
  Future<List<dynamic>?> getSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Sessions fetch failed: ${response.body}');
      }
    } catch (e) {
      print('Error fetching sessions: $e');
    }
    return null;
  }

  Future<bool> addSession(String topic, String date, int duration, String notes) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sessions'),
        headers: _headers(),
        body: jsonEncode({
          'topic': topic,
          'date': date,
          'duration': duration,
          'notes': notes,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding session: $e');
      return false;
    }
  }

  Future<bool> deleteSession(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/sessions/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting session: $e');
      return false;
    }
  }

  // Ask AI Tutor (protected endpoint)
  Future<String?> askTutor(String question) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/ask'),
        headers: _headers(),
        body: jsonEncode({'question': question}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer'];
      } else {
        print('AI error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling AI Tutor: $e');
      return null;
    }
  }

  // Get chat history for the currently authenticated user
  Future<List<dynamic>?> getChatHistory(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ai/history/$userId'), headers: _headers());
      if (response.statusCode == 200) return jsonDecode(response.body);
      print('History fetch failed: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('Error fetching history: $e');
    }
    return null;
  }

}
