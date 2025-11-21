import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  ApiService()
      : baseOrigin = Platform.isAndroid
            ? "http://10.0.2.2:3000"
            : "http://localhost:3000",
        baseUrl = Platform.isAndroid
            ? "http://10.0.2.2:3000/api"
            : "http://localhost:3000/api";

  final String baseOrigin;
  final String baseUrl;
  static String? authToken;

  static Future<void> setAuthToken(String token) async {
    authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  static Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('authToken');
    debugPrint('🔑 Token loaded: ${authToken != null}');
  }

  static Future<void> clearAuthToken() async {
    authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  // Validate if the stored token is still valid
  static Future<bool> validateToken() async {
    if (authToken == null) return false;

    try {
      final validateUrl = Platform.isAndroid 
          ? "http://10.0.2.2:3000/api/auth/validate"
          : "http://localhost:3000/api/auth/validate";
      final response = await http.get(
        Uri.parse(validateUrl),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (authToken != null) headers['Authorization'] = 'Bearer $authToken';  // ← Use static
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
        try {
          final errorData = jsonDecode(response.body);
          print('Register failed: ${errorData['error'] ?? response.body}');
          return {'error': errorData['error'] ?? 'Registration failed'};
        } catch (_) {
          print('Register failed: ${response.body}');
          return {'error': 'Registration failed'};
        }
      }
    } catch (e) {
      print('Register error: $e');
      return {'error': 'Connection failed. Please check if the server is running.'};
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
        try {
          final errorData = jsonDecode(response.body);
          print('Login failed: ${errorData['error'] ?? response.body}');
          return {'error': errorData['error'] ?? 'Login failed'};
        } catch (_) {
          print('Login failed: ${response.body}');
          return {'error': 'Login failed'};
        }
      }
    } catch (e) {
      print("Login error: $e");
      return {'error': 'Connection failed. Please check if the server is running.'};
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
      final headers = _headers();
      print('📥 Fetching assignments from: $baseUrl/assignments');
      final response = await http.get(
        Uri.parse('$baseUrl/assignments'),
        headers: headers,
      );
      print('📥 Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Assignments fetch failed: ${response.statusCode} - ${response.body}');
        if (response.statusCode == 401) {
          print('⚠️ Unauthorized - token may be invalid or expired');
        }
      }
    } catch (e) {
      print('❌ Error fetching assignments: $e');
    }
    return null;
  }

  Future<bool> addAssignment(
    String title,
    String description,
    String dueDate, {
    String priority = 'medium',
    String status = 'pending',
    PlatformFile? attachment,
  }) async {
    try {
      if (attachment != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/assignments'),
        );
        request.headers.addAll(_headers(json: false));
        request.fields.addAll({
          'title': title,
          'description': description,
          'due_date': dueDate,
          'priority': priority,
          'status': status,
        });
        request.files.add(
          await _multipartFromPlatformFile('attachment', attachment),
        );

        final response = await request.send().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Request timed out');
          },
        );
        final body = await response.stream.bytesToString();

        if (response.statusCode == 201 || response.statusCode == 200) {
          return true;
        }
        print('Add assignment failed: ${response.statusCode} - $body');
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/assignments'),
            headers: _headers(),
            body: jsonEncode({
              'title': title,
              'description': description,
              'due_date': dueDate,
              'priority': priority,
              'status': status,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Request timed out');
            },
          );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Add assignment failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Error adding assignment: $e');
      print('❌ Stack trace: $stackTrace');
      if (e is TimeoutException) {
        print('⏱️ Request timed out');
      } else if (e is SocketException) {
        print('🌐 Network error - check connection');
      } else if (e is HttpException) {
        print('📡 HTTP error');
      }
      return false;
    }
  }

  Future<bool> updateAssignment(
    int id,
    String title,
    String description,
    String dueDate, {
    String? priority,
    String status = 'pending',
    PlatformFile? attachment,
  }) async {
    try {
      print('📝 Updating assignment: $id (Priority: ${priority ?? 'unchanged'})');

      if (attachment != null) {
        final request = http.MultipartRequest(
          'PUT',
          Uri.parse('$baseUrl/assignments/$id'),
        );
        request.headers.addAll(_headers(json: false));
        request.fields.addAll({
          'title': title,
          'description': description,
          'due_date': dueDate,
          'status': status,
        });
        if (priority != null) {
          request.fields['priority'] = priority;
        }
        request.files.add(
          await _multipartFromPlatformFile('attachment', attachment),
        );

        final response = await request.send().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Request timed out');
          },
        );
        final body = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          return true;
        }
        print('❌ Update assignment failed: ${response.statusCode} - $body');
        return false;
      }

      final body = <String, dynamic>{
        'title': title,
        'description': description,
        'due_date': dueDate,
      };
      if (priority != null) body['priority'] = priority;
      body['status'] = status;

      final response = await http
          .put(
            Uri.parse('$baseUrl/assignments/$id'),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('❌ Update assignment timed out after 10 seconds');
              throw TimeoutException('Request timed out');
            },
          );

      print('📝 Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Update assignment failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating assignment: $e');
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

  // ========== AI CHATS ==========

Future<Map<String, dynamic>?> createChat({String? title}) async {
  try {
    print('Creating chat with title: $title');
    final res = await http.post(
      Uri.parse('$baseUrl/ai/chats'),
      headers: _headers(),
      body: jsonEncode({'title': title ?? 'New Chat'}),
    );

    print('Create chat response: ${res.statusCode} ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    return null;
  } catch (e) {
    print('createChat error: $e');
    return null;
  }
}

  Future<List<dynamic>> listChats() async {
    final url = '$baseUrl/ai/chats';
    debugPrint('🌐 GET $url');

    try {
      final headers = _headers(json: true);  // ← NO await here
      debugPrint('🔑 Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 10));

      debugPrint('📥 listChats status: ${response.statusCode}');
      debugPrint('📥 listChats body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded as List<dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ listChats error: $e');
      rethrow;
    }
  }

Future<Map<String, dynamic>?> getChatDetails(int chatId) async {
  try {
    print('📖 Fetching chat details for chatId: $chatId');
    final res = await http.get(
      Uri.parse('$baseUrl/ai/chats/$chatId'),
      headers: _headers(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      print('✅ Chat details fetched: $data');
      return data;
    }
    print('❌ Failed to fetch chat details: ${res.statusCode}');
    return null;
  } catch (e) {
    print('getChatDetails error: $e');
    return null;
  }
}

Future<bool> archiveChat(int chatId, bool archive) async {
  try {
    final res = await http.post(
      Uri.parse('$baseUrl/ai/chats/$chatId/archive'),
      headers: _headers(),
      body: jsonEncode({'archive': archive}),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (e) {
    print('archiveChat error: $e');
    return false;
  }
}

// Update chat title (manual edit)
  Future<bool> updateChatTitle(int chatId, String newTitle) async {
    try {
      print('📝 Updating chat title for chatId: $chatId to: $newTitle');

      final res = await http.patch(
        Uri.parse('$baseUrl/ai/chats/$chatId/title'),
        headers: _headers(),
        body: jsonEncode({'title': newTitle}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        print('✅ Chat title updated successfully');
        return true;
      }

      print('❌ Failed to update chat title: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      print('❌ updateChatTitle error: $e');
      return false;
    }
  }

// Auto-generate title by calling the title endpoint with empty body
  Future<String?> autoTitleChatAndFetchTitle(int chatId) async {
    try {
      print('🏷️ Auto-generating title for chat $chatId');

      final res = await http.post(
        Uri.parse('$baseUrl/ai/chats/$chatId/title'),
        headers: _headers(),
        body: jsonEncode({}),  // Empty body triggers auto-generation
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final title = data['title'] as String?;
        print('✅ Title auto-generated: $title');
        return title;
      }

      print('❌ Failed to auto-generate title: ${res.statusCode}');
      return null;
    } catch (e) {
      print('❌ autoTitleChatAndFetchTitle error: $e');
      return null;
    }
  }

// ========== MESSAGES ==========

Future<Map<String, dynamic>?> listChatMessages(int chatId, {int limit = 30, String? cursor}) async {
  try {
    final qp = <String, String>{'limit': '$limit'};
    if (cursor != null) qp['cursor'] = cursor;
    final uri = Uri.parse('$baseUrl/ai/chats/$chatId/messages').replace(queryParameters: qp);

    final res = await http.get(uri, headers: _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    print('listChatMessages failed: ${res.statusCode} ${res.body}');
  } catch (e) {
    print('listChatMessages error: $e');
  }
  return null;
}

Future<Map<String, dynamic>?> sendChatMessage(
  int chatId,
  String text, {
  List<int>? attachmentIds,
  bool researchMode = false,
}) async {
  try {
    final Map<String, dynamic> body = {'text': text};
    if (attachmentIds != null && attachmentIds.isNotEmpty) {
      body['attachmentIds'] = attachmentIds;
    }
    if (researchMode) {
      body['researchMode'] = true;
    }

    print('🚀 Sending message to chatId: $chatId');
    print('🚀 Body: $body');
    print('🔬 Research mode: $researchMode');

    final res = await http.post(
      Uri.parse('$baseUrl/ai/chats/$chatId/messages'),
      headers: _headers(),
      body: jsonEncode(body),
    );

    print('🚀 Response status: ${res.statusCode}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    print('sendChatMessage failed: ${res.statusCode} ${res.body}');
  } catch (e) {
    print('sendChatMessage error: $e');
  }
  return null;
}

// ========== UPLOADS ==========

  Future<Map<String, dynamic>?> uploadAttachment(String filePath, int conversationId) async {
    try {
      print('📤 Uploading file: $filePath to conversation: $conversationId');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ai/uploads'),
      );

      // Add auth header
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      request.fields['conversation_id'] = conversationId.toString();

      // ✅ Explicitly detect and set content type
      String? mimeType;
      final extension = filePath.split('.').last.toLowerCase();

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        default:
          mimeType = 'application/octet-stream';
      }

      print('📎 Detected MIME type: $mimeType for extension: $extension');

      // Add file with explicit content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType.parse(mimeType),  // ✅ Explicit content type
        ),
      );

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);

      print('📥 Upload response: ${res.statusCode}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        print('✅ File uploaded: ${data['id']}');
        return data;
      }

      print('❌ Upload failed: ${res.body}');
      return null;
    } catch (e) {
      print('❌ uploadAttachment error: $e');
      return null;
    }
  }

  // Upload multiple attachments at once
  Future<List<int>> uploadMultipleAttachments(List<String> filePaths, int conversationId) async {
    final List<int> attachmentIds = [];

    for (String filePath in filePaths) {
      try {
        final result = await uploadAttachment(filePath, conversationId);
        if (result != null && result['id'] != null) {
          attachmentIds.add(result['id'] as int);
          print('✅ Uploaded ${filePath.split('/').last}: ID ${result['id']}');
        }
      } catch (e) {
        print('❌ Failed to upload $filePath: $e');
        // Continue with other files even if one fails
      }
    }

    print('📦 Total uploaded: ${attachmentIds.length}/${filePaths.length} files');
    return attachmentIds;
  }

  Future<http.Response?> getAttachment(int attachmentId) async {
    try {
      debugPrint('🖼️ Fetching attachment: $attachmentId');

      final res = await http.get(
        Uri.parse('$baseUrl/ai/uploads/$attachmentId'),
        headers: {
          if (authToken != null) 'Authorization': 'Bearer $authToken',  // ✅ Use static authToken
        },
      );

      debugPrint('🖼️ Attachment response: ${res.statusCode}');

      if (res.statusCode == 200) {
        debugPrint('✅ Attachment loaded successfully');
        return res;
      } else {
        debugPrint('❌ Failed to load attachment: ${res.statusCode}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ getAttachment error: $e');
      return null;
    }
  }

Future<bool> deleteAttachment(int attachmentId) async {
  try {
    final res = await http.delete(
      Uri.parse('$baseUrl/ai/uploads/$attachmentId'),
      headers: _headers(),
    );
    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (e) {
    print('deleteAttachment error: $e');
    return false;
  }
}

// ========== HELPER METHODS ==========

// Helper to get newest chat ID (for placeholder resolution)
Future<int?> getNewestChatId() async {
  try {
    final chats = await listChats();
    if (chats != null && chats.isNotEmpty) {
      return chats.first['id'] as int?;
    }
    return null;
  } catch (e) {
    print('getNewestChatId error: $e');
    return null;
  }
}

// ========== WRAPPER METHODS (for ai_tutor_screen.dart compatibility) ==========

// Wrapper for getChatDetails
Future<Map<String, dynamic>?> getChatById(int chatId) async {
  return await getChatDetails(chatId);
}

// Wrapper for listChatMessages
Future<Map<String, dynamic>?> listMessages(int chatId, {int? cursor}) async {
  return await listChatMessages(chatId, limit: 50, cursor: cursor?.toString());
}

// Wrapper for sendChatMessage
Future<Map<String, dynamic>?> sendMessage(
  int chatId,
  String text, {
  List<int> attachmentIds = const [],
  bool researchMode = false,
}) async {
  return await sendChatMessage(
    chatId,
    text,
    attachmentIds: attachmentIds.isEmpty ? null : attachmentIds,
    researchMode: researchMode,
  );
}

// Wrapper for uploadAttachment
Future<Map<String, dynamic>?> uploadFile(String filePath, int conversationId) async {
  return await uploadAttachment(filePath, conversationId);
}

// ========== LEGACY/DEPRECATED METHODS ==========

@Deprecated('Use createChat and sendChatMessage instead')
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

    final res = await sendChatMessage(cid, question);
    final asst = (res?['assistant'] as Map<String, dynamic>?);
    return asst?['text'] as String?;
  } catch (e) {
    print('askTutor shim error: $e');
    return null;
  }
}

@Deprecated('Use listChats / listChatMessages instead')
Future<List<dynamic>?> getChatHistory(int userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cid = prefs.getInt('last_ai_conversation_id');
    if (cid == null) return <dynamic>[];

    final page = await listChatMessages(cid, limit: 100);
    final items = (page?['items'] as List? ?? []).cast<Map<String, dynamic>>();

    final List<Map<String, dynamic>> out = [];
    final seq = items.reversed.toList();

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
        i++;
      }
    }
    return out;
  } catch (e) {
    print('getChatHistory shim error: $e');
    return <dynamic>[];
  }
}

}
