import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final List<String> _attachmentPaths = [];

  bool _isLoading = false;
  bool _loadingHistory = true;
  bool _researchMode = false;
  int? _conversationId;
  String? _chatTitle;
  List<int> _pendingAttachments = [];
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _conversationId = args['chatId'] as int?;
        _loadMessages();
        _loadChatTitle();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachmentPaths.addAll(
              result.files.map((file) => file.path!).where((path) => path.isNotEmpty)
          );
        });
        print('📎 Selected ${result.files.length} images');
      }
    } catch (e) {
      print('❌ Image picker error: $e');
      if (mounted) {
        String errorMsg = 'Failed to load chat';
        if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
          errorMsg = 'Connection timeout. Please check if the server is running.';
        } else if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
          errorMsg = 'Cannot connect to server. Please check your connection.';
        } else {
          errorMsg = 'Failed to load chat: ${e.toString()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachmentPaths.removeAt(index);
    });
  }

  Future<void> _loadChatTitle() async {
    if (_conversationId == null) return;

    try {
      final api = ApiService();
      final chat = await api.getChatById(_conversationId!);

      if (chat != null && mounted) {
        setState(() {
          _chatTitle = chat['title'] as String?;
        });
      }
    } catch (e) {
      print('Error loading chat title: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) {
      setState(() => _loadingHistory = false);
      return;
    }

    setState(() => _loadingHistory = true);

    try {
      final api = ApiService();
      final result = await api.listMessages(_conversationId!);

      if (result != null && mounted) {
        final items = (result['items'] as List<dynamic>?) ?? [];
        setState(() {
          _messages.clear();
          _messages.addAll(items.reversed.map((msg) {
            return {
              'role': msg['role'],
              'text': msg['text'],
              'attachments': msg['attachments'] ?? [],
              'sources': msg['sources'] ?? [],
            };
          }));
          _loadingHistory = false;
        });

        _scrollToBottom();
      } else {
        setState(() => _loadingHistory = false);
      }
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();

    if (question.isEmpty && _attachmentPaths.isEmpty) {
      print('⚠️ Nothing to send');
      return;
    }

    if (_conversationId == null || _conversationId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat not ready yet')),
      );
      return;
    }

    final isFirstMessage = _messages.isEmpty;

    // Upload all attachments first
    List<int> attachmentIds = [];
    if (_attachmentPaths.isNotEmpty) {
      setState(() => _isLoading = true);

      try {
        print('📤 Uploading ${_attachmentPaths.length} attachments...');
        attachmentIds = await ApiService().uploadMultipleAttachments(
          _attachmentPaths,
          _conversationId!,
        );
        print('✅ Uploaded ${attachmentIds.length} attachments');
      } catch (e) {
        print('❌ Upload error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload images: $e')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    // Create optimistic user message
    final temp = {
      'role': 'user',
      'text': question.isEmpty ? '📎 ${attachmentIds.length} attachment(s)' : question,
      'attachments': [],
      'sources': [],
      '_tmp': true,
    };

    setState(() {
      _messages.add(temp);
      _isLoading = true;
      _attachmentPaths.clear();
    });
    _controller.clear();
    _scrollToBottom();

    final api = ApiService();
    try {
      print('📤 Sending message with ${attachmentIds.length} attachments');
      final res = await api.sendChatMessage(
        _conversationId!,
        question,
        attachmentIds: attachmentIds.isEmpty ? null : attachmentIds,
        researchMode: _researchMode,
      );

      if (res == null) throw Exception('sendChatMessage returned null');

      final user = res['user'] as Map<String, dynamic>;
      final asst = res['assistant'] as Map<String, dynamic>;

      final userMsg = {
        'role': 'user',
        'text': user['text'] ?? question,
        'attachments': user['attachments'] ?? [],
        'sources': [],
      };

      final aiMsg = {
        'role': 'assistant',
        'text': asst['text'] ?? '',
        'attachments': asst['attachments'] ?? [],
        'sources': asst['sources'] ?? [],
      };

      if (mounted) {
        setState(() {
          final idx = _messages.lastIndexWhere((m) => m['_tmp'] == true);
          if (idx != -1) {
            _messages[idx] = userMsg;
          } else {
            _messages.add(userMsg);
          }
          _messages.add(aiMsg);
        });
        _scrollToBottom();
      }

      // Auto-generate title on first message
      if (isFirstMessage) {
        print('🏷️ First message sent, auto-generating title...');
        final newTitle = await api.autoTitleChatAndFetchTitle(_conversationId!);
        if (mounted && newTitle != null) {
          setState(() => _chatTitle = newTitle);
        }
      }
    } catch (e) {
      print('❌ Send message error: $e');
      if (mounted) {
        setState(() => _messages.removeWhere((m) => m['_tmp'] == true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _cleanMarkdown(String text) {
    // Remove \boxed{...} LaTeX command and just keep the content
    text = text.replaceAllMapped(
      RegExp(r'\\boxed\{([^}]+)\}'),
          (match) => '**${match.group(1)}**',  // Make boxed content bold
    );

    // Convert inline math \(...\) to plain text (remove delimiters)
    text = text.replaceAllMapped(
      RegExp(r'\\\(([^)]+)\\\)'),
          (match) => match.group(1) ?? '',  // Just show the math expression
    );

    // Convert display math \[...\] to plain text with line breaks
    text = text.replaceAllMapped(
      RegExp(r'\\\[([^\]]+)\\\]', multiLine: true),
          (match) => '\n${match.group(1)}\n',  // Show math with spacing
    );

    // Remove any remaining backslashes from LaTeX commands
    text = text.replaceAll(RegExp(r'\\([a-zA-Z]+)'), '');  // Remove \command

    // Clean up excessive newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text;
  }


  Future<void> _showEditTitleDialog() async {
    final TextEditingController titleController = TextEditingController(
      text: _chatTitle ?? 'New Chat',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Edit Chat Title'),
          ],
        ),
        content: TextField(
          controller: titleController,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: 'Chat Title',
            hintText: 'Enter a title for this chat',
            border: OutlineInputBorder(),
            counterText: '',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.pop(context, newTitle);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _updateChatTitle(result);
    }

    titleController.dispose();
  }

  Future<void> _updateChatTitle(String newTitle) async {
    if (_conversationId == null) return;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Text('Updating title...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final api = ApiService();
      final success = await api.updateChatTitle(_conversationId!, newTitle);

      if (!mounted) return;

      if (success) {
        setState(() {
          _chatTitle = newTitle;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Title updated!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to update title'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating title: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildImageThumbnail(int attachmentId, bool isUser) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(attachmentId),
      child: Container(
        width: 120,
        height: 120,
        margin: EdgeInsets.only(top: 8, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isUser ? Colors.deepPurple[300]! : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              FutureBuilder<http.Response?>(
                future: ApiService().getAttachment(attachmentId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                      ),
                    );
                  }

                  return Image.memory(
                    snapshot.data!.bodyBytes,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.broken_image, color: Colors.grey[600]),
                        ),
                      );
                    },
                  );
                },
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(int attachmentId) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: FutureBuilder<http.Response?>(
          future: ApiService().getAttachment(attachmentId),
          builder: (context, snapshot) {
            return Stack(
              children: [
                Center(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? CircularProgressIndicator(color: Colors.white)
                      : snapshot.hasError || !snapshot.hasData || snapshot.data == null
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                      : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      snapshot.data!.bodyBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSourcesList(List<dynamic> sources) {
    if (sources.isEmpty) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 16, color: Colors.blue[700]),
              SizedBox(width: 4),
              Text(
                'Sources',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...sources.asMap().entries.map((entry) {
            final index = entry.key;
            final source = entry.value;
            return GestureDetector(
              onTap: () async {
                final url = source['url'] as String?;
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source['title'] ?? 'Source',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (source['snippet'] != null) ...[
                            SizedBox(height: 2),
                            Text(
                              source['snippet'],
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.open_in_new, size: 14, color: Colors.blue[700]),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isUser) {
    final attachments = (msg['attachments'] as List<dynamic>?) ?? [];
    final sources = (msg['sources'] as List<dynamic>?) ?? [];
    final text = msg['text'] as String? ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text.isNotEmpty)
              isUser
                  ? Text(text, style: TextStyle(fontSize: 15))  // User messages: plain text
                  : MarkdownBody(  // AI messages: render markdown
                data: _cleanMarkdown(text),
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 15, color: Colors.black87),
                  strong: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  em: TextStyle(fontStyle: FontStyle.italic, fontSize: 15),
                  code: TextStyle(
                    backgroundColor: Colors.grey[200],
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  blockquote: TextStyle(color: Colors.grey[700]),
                  listBullet: TextStyle(fontSize: 15),
                ),
                selectable: true,  // Allow text selection
              ),
            if (attachments.isNotEmpty) ...[
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attachments.map<Widget>((att) {
                  int? id;
                  if (att is int) {
                    id = att;
                  } else if (att is Map) {
                    id = att['id'] as int?;
                  }

                  if (id != null) {
                    return _buildImageThumbnail(id, isUser);
                  }
                  return SizedBox.shrink();
                }).toList(),
              ),
            ],
            if (sources.isNotEmpty)
              _buildSourcesList(sources),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showEditTitleDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _chatTitle ?? 'New Chat',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.edit, size: 16),
            ],
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _researchMode ? Icons.science : Icons.science_outlined,
              color: _researchMode ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              setState(() => _researchMode = !_researchMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _researchMode ? '🔬 Research Mode ON' : 'Research Mode OFF',
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Toggle Research Mode',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg, isUser);
              },
            ),
          ),

          // Image preview row
          if (_attachmentPaths.isNotEmpty)
            Container(
              height: 100,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _attachmentPaths.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.all(4),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepPurple, width: 2),
                          image: DecorationImage(
                            image: FileImage(File(_attachmentPaths[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeAttachment(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          if (_isLoading) const LinearProgressIndicator(),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file, color: Colors.deepPurple),
                  onPressed: _pickImages,
                  tooltip: 'Attach images',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask your Study Buddy...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: _attachmentPaths.isNotEmpty
                          ? Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text('${_attachmentPaths.length}'),
                          backgroundColor: Colors.deepPurple[100],
                        ),
                      )
                          : null,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
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