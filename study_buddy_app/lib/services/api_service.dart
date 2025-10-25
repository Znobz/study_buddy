import 'dart:convert';
import 'dart:io';
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
  Future<int?> _getOrCreateLegacyChatId() async {
  final prefs = await SharedPreferences.getInstance();
  var cid = prefs.getInt('last_ai_conversation_id');
  if (cid == null) {
    final conv = await createChat(title: 'Legacy Chat');
    if (conv == null) return null;
    cid = conv['id'] as int;
    await prefs.setInt('last_ai_conversation_id', cid);
  }
  return cid;
  }

  @Deprecated('Use sendChatMessage instead')
Future<String?> askTutor(String question) async {
  try {
    final cid = await _getOrCreateLegacyChatId();
    if (cid == null) return null;

    // IMPORTANT: body must be Map<String, dynamic>
    final res = await sendChatMessage(cid, question);
    final asst = (res?['assistant'] as Map<String, dynamic>?);
    return asst?['text'] as String?;
  } catch (e) {
    print('askTutor shim error: $e');
    return null;
  }
}


  // Get chat history for the currently authenticated user
  @Deprecated('Use listChats / listChatMessages instead')
  Future<List<dynamic>?> getChatHistory(int userId) async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final cid = prefs.getInt('last_ai_conversation_id');
    if (cid == null) return <dynamic>[];

    final page = await listChatMessages(cid, limit: 100);
    final items = (page?['items'] as List? ?? []).cast<Map<String, dynamic>>();

    // Convert to legacy shape your screen expected:
    final List<Map<String, dynamic>> out = [];
    final seq = items.reversed.toList(); // oldest-first

    for (int i = 0; i < seq.length - 1; i++) {
      final a = seq[i], b = seq[i + 1];
      if (a['role'] == 'user' && b['role'] == 'assistant') {
        out.add({
          'chat_id': cid,
          'user_id': userId,
          'session_id': null,
          'question': a['text'],
          'ai_response': b['text'],
          'timestamp': b['created_at'],
        });
        i++; // skip paired assistant
      }
    }
    return out;
  } catch (e) {
    print('getChatHistory shim error: $e');
    return <dynamic>[];
  }
}

  Future<Map<String, dynamic>?> createChat({String? title}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ai/chats'),
        headers: _headers(),
        body: jsonEncode({'title': title}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      print('createChat failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      print('createChat error: $e');
    }
    return null;
  }

  Future<List<dynamic>?> listChats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/ai/chats'),
        headers: _headers(),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      print('listChats failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      print('listChats error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> listChatMessages(int chatId, {int limit = 30, String? cursor}) async {
    try {
      final qp = <String, String>{ 'limit': '$limit' };
      if (cursor != null) qp['cursor'] = cursor;
      final uri = Uri.parse('$baseUrl/ai/chats/$chatId/messages').replace(queryParameters: qp);

      final res = await http.get(uri, headers: _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>; // { items: [...], next_cursor }
      }
      print('listChatMessages failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      print('listChatMessages error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> sendChatMessage(int chatId, String text, {List<int>? attachmentIds}) async {
    try {
      final Map<String, dynamic> body = {'text': text};
      if (attachmentIds != null && attachmentIds.isNotEmpty) {
        body['attachmentIds'] = attachmentIds;
      }

      print('🚀 Sending message to chatId: $chatId');
      print('🚀 URL: $baseUrl/ai/chats/$chatId/messages');
      print('🚀 Auth token present: ${authToken != null}');
      print('🚀 Body: $body');

      final res = await http.post(
        Uri.parse('$baseUrl/ai/chats/$chatId/messages'),
        headers: _headers(),
        body: jsonEncode(body),
      );
      
      print('🚀 Response status: ${res.statusCode}');
      print('🚀 Response body: ${res.body}');
      
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      print('sendChatMessage failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      print('sendChatMessage error: $e');
    }
    return null;
  }


  Future<int?> uploadAttachment(File file) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/ai/uploads'));
      if (authToken != null) req.headers['Authorization'] = 'Bearer $authToken';
      req.files.add(await http.MultipartFile.fromPath('file', file.path));

      final res = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final j = jsonDecode(body) as Map<String, dynamic>;
        return j['attachmentId'] as int?;
      }
      print('uploadAttachment failed: ${res.statusCode} $body');
    } catch (e) {
      print('uploadAttachment error: $e');
    }
    return null;
  }

  Future<bool> autoTitleChat(int chatId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ai/chats/$chatId/title'),
        headers: _headers(),
        body: jsonEncode({}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('autoTitleChat error: $e');
      return false;
    }
  }

  Future<bool> archiveChat(int chatId, bool archived) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ai/chats/$chatId/archive'),
        headers: _headers(),
        body: jsonEncode({'archived': archived}),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      print('archiveChat error: $e');
      return false;
    }
  }

}
