import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AiTutorScreen extends StatefulWidget {
  final int userId; // require authenticated user id

  const AiTutorScreen({super.key, required this.userId});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _loadingHistory = true;
  bool _didInitialize = false; // ← NEW: Prevent multiple calls

  int? _conversationId;
  String? _nextCursor;
  
  @override
  void initState() {
    super.initState();
    // Don't call _loadHistory here!
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load once when dependencies are ready
    if (!_didInitialize) {
      _didInitialize = true;
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    print('📂 _loadHistory started');
    setState(() => _loadingHistory = true);
    final api = ApiService();

    try {
      // Check if a chatId was passed (resuming existing chat)
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      print('📂 Route arguments: $args');
      
      final passedChatId = args?['chatId'] as int?;
      print('📂 Passed chatId: $passedChatId');

      if (passedChatId != null) {
        // Resume existing chat
        print('📂 Resuming existing chat: $passedChatId');
        _conversationId = passedChatId;
      } else {
        // Create a new chat (only if no chatId passed)
        print('📂 Creating new chat...');
        final conv = await api.createChat(title: 'New Chat');
        print('📂 Create chat response: $conv');
        
        if (conv == null) {
          throw Exception('Could not create chat');
        }
        _conversationId = conv['id'] as int;
        print('📂 New conversation ID: $_conversationId');
      }

      print('📂 Final conversation ID: $_conversationId');

      // Fetch recent messages
      final page = await api.listChatMessages(_conversationId!, limit: 30);
      final items = (page?['items'] as List? ?? []);

      print('📂 Loaded ${items.length} messages');

      // Backend returns newest-first; UI is oldest-first, so reverse for display
      final List<Map<String, dynamic>> normalized = items
          .cast<Map<String, dynamic>>()
          .reversed
          .map((m) => {
                'role': (m['role'] == 'assistant') ? 'ai' : 'user',
                'text': m['text'],
                'time': m['created_at'],
              })
          .toList();

      setState(() {
        _messages
          ..clear()
          ..addAll(normalized);
        _nextCursor = page?['next_cursor'] as String?;
      });
      
      print('📂 _loadHistory completed successfully');
    } catch (e) {
      print('❌ _loadHistory error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _sendMessage() async {
  final question = _controller.text.trim();
  
  print('🔍 Send button clicked');
  print('🔍 Question: $question');
  print('🔍 Conversation ID: $_conversationId');
  
  if (question.isEmpty || _conversationId == null) {
    print('⚠️ Send blocked - question empty: ${question.isEmpty}, conversationId null: ${_conversationId == null}');
    return;
  }

  // Check if this is the first message (for auto-titling)
  final isFirstMessage = _messages.isEmpty;

  // Optimistic user bubble
  final temp = {
    'role': 'user',
    'text': question,
    'time': DateTime.now().toIso8601String(),
    '_tmp': true,
  };

  setState(() {
    _messages.add(temp);
    _isLoading = true;
  });
  _controller.clear();

  final api = ApiService();
    try {
      print('📤 Calling sendChatMessage with chatId: $_conversationId');
      final res = await api.sendChatMessage(_conversationId!, question);
      print('📥 Response received: $res');
      
      if (res == null) throw Exception('sendChatMessage returned null');

      final user = res['user'] as Map<String, dynamic>;
      final asst = res['assistant'] as Map<String, dynamic>;

      final userMsg = {
        'role': 'user',
        'text': user['text'],
        'time': user['created_at'],
      };
      final aiMsg = {
        'role': 'ai',
        'text': asst['text'],
        'time': asst['created_at'],
      };

      setState(() {
        final idx = _messages.lastIndexWhere((m) => m['_tmp'] == true);
        if (idx != -1) {
          _messages[idx] = userMsg;
        } else {
          _messages.add(userMsg);
        }
        _messages.add(aiMsg);
      });

      // Auto-generate title after first message exchange
      if (isFirstMessage) {
        print('🏷️ First message sent, auto-generating title...');
        final titleSuccess = await api.autoTitleChat(_conversationId!);
        if (titleSuccess) {
          print('🏷️ Title auto-generated successfully');
        } else {
          print('⚠️ Failed to auto-generate title');
        }
      }
    } catch (e) {
      print('❌ Send message error: $e');
      setState(() => _messages.removeWhere((m) => m['_tmp'] == true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Tutor')),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.deepPurple[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg['text'] ?? ''),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask your Study Buddy...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.deepPurple,
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}