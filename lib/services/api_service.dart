import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000/api"; // emulator alias for localhost
  static String? authToken;

  // ✅ Save token locally
  static Future<void> saveAuthToken(String token) async {
    authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  // ✅ Load token
  static Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('authToken');
  }

  // ✅ Clear token
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    authToken = null;
  }

  // ✅ Add token header if logged in
  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) headers['Authorization'] = 'Bearer $authToken';
    return headers;
  }

  // -------------------------------
  // 🔹 AUTH ROUTES
  // -------------------------------

  Future<Map<String, dynamic>?> postRegister(
      String first, String last, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'first_name': first,
        'last_name': last,
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['token'] != null) {
      await saveAuthToken(data['token']);
    }
    return data;
  }

  Future<void> logout() async {
    await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers(),
    );
    await clearAuthToken();
  }

  // -------------------------------
  // 🔹 ASSIGNMENTS
  // -------------------------------

  Future<List<dynamic>?> getAssignments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/assignments'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<void> addAssignment(String title, String desc, String dueDate) async {
    await http.post(
      Uri.parse('$baseUrl/assignments'),
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'description': desc,
        'due_date': dueDate,
      }),
    );
  }

  Future<void> deleteAssignment(int id) async {
    await http.delete(
      Uri.parse('$baseUrl/assignments/$id'),
      headers: _headers(),
    );
  }

  // -------------------------------
  // 🔹 STUDY SESSIONS
  // -------------------------------

  Future<List<dynamic>?> getSessions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sessions'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<void> addSession(String title, String desc, String date) async {
    await http.post(
      Uri.parse('$baseUrl/sessions'),
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'description': desc,
        'session_date': date,
      }),
    );
  }

  Future<void> deleteSession(int id) async {
    await http.delete(
      Uri.parse('$baseUrl/sessions/$id'),
      headers: _headers(),
    );
  }

  // -------------------------------
  // 🔹 AI TUTOR
  // -------------------------------

  Future<String?> askTutor(String question) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/ask'),
      headers: _headers(),
      body: jsonEncode({'question': question}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['answer'];
    }
    return null;
  }

  Future<List<dynamic>?> getChatHistory(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai/history/$userId'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}