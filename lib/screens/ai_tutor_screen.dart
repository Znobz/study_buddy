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

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    final api = ApiService();
    final history = await api.getChatHistory(widget.userId.toString());
    if (history != null) {
      // each history item: {chat_id, user_id, session_id, question, ai_response, timestamp}
      setState(() {
        _messages.clear();
        for (var h in history) {
          _messages.add({'role': 'user', 'text': h['question'], 'time': h['timestamp']});
          _messages.add({'role': 'ai', 'text': h['ai_response'], 'time': h['timestamp']});
        }
      });
    }
    setState(() => _loadingHistory = false);
  }

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': question, 'time': DateTime.now().toIso8601String()});
      _isLoading = true;
    });
    _controller.clear();

    final api = ApiService();
    final answer = await api.askTutor(question);

    setState(() {
      _isLoading = false;
      _messages.add({'role': 'ai', 'text': answer ?? 'No response', 'time': DateTime.now().toIso8601String()});
    });
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
        