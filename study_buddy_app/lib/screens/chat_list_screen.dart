import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:async' show unawaited;
import 'package:shared_preferences/shared_preferences.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> chats = [];
  bool isLoading = true;
  bool _dontShowDeleteWarning = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _loadDeleteWarningPreference();
  }


  Future<void> _loadDeleteWarningPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dontShowDeleteWarning = prefs.getBool('dont_show_delete_warning') ?? false;
    });
  }

  int _maxExistingChatId() {
    var maxId = 0;
    for (final c in chats) {
      final id = int.tryParse('${c['id']}') ?? -1;
      if (id > maxId) maxId = id;
    }
    return maxId;
  }

  void _applyResolvedChat(int tempId, int realId, {String? title}) {
    if (!mounted) return;
    setState(() {
      final idx = chats.indexWhere((c) => int.tryParse('${c['id']}') == tempId);
      final nowIso = DateTime.now().toIso8601String();
      final row = {
        'id': realId,
        'title': (title?.trim().isNotEmpty == true) ? title!.trim() : 'New Chat',
        'last_message_preview': '',
        'updated_at': nowIso,
      };
      if (idx >= 0) {
        chats[idx] = row;
      } else {
        chats.insert(0, row);
      }
    });
  }

  Future<void> _resolvePlaceholder(int tempId, int baselineMaxId) async {
    const int maxAttempts = 24;
    for (var i = 0; i < maxAttempts; i++) {
      if (!mounted) return;

      try {
        final list = await ApiService().listChats();
        if (list != null && list.isNotEmpty) {
          final newer = list
              .cast<Map<String, dynamic>>()
              .where((m) {
            final id = (m['id'] is int)
                ? m['id'] as int
                : int.tryParse('${m['id']}') ?? -1;
            return id > baselineMaxId;
          })
              .toList();

          if (newer.isNotEmpty) {
            newer.sort((a, b) => ((b['id'] as int) - (a['id'] as int)));
            final real = newer.first;
            final realId = real['id'] as int;
            final title = real['title'] as String?;
            _applyResolvedChat(tempId, realId, title: title);
            return;
          }
        }
      } catch (e) {
        debugPrint('resolvePlaceholder listChats error: $e');
      }

      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (!mounted) return;
    setState(() {
      final idx =
      chats.indexWhere((c) => int.tryParse('${c['id']}') == tempId);
      if (idx >= 0) {
        chats[idx]['_pending'] = false;
      }
    });
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    debugPrint('LOAD: start (was items=${chats.length})');
    setState(() => isLoading = true);

    try {
      final api = ApiService();
      debugPrint('🔍 Calling api.listChats()...');
      final data = await api.listChats();
      debugPrint('✅ api.listChats() returned: $data');

      if (!mounted) return;

      setState(() {
        chats = data ?? [];
        isLoading = false;
      });
      debugPrint('LOAD: done (now items=${chats.length})');
    } catch (e, stackTrace) {
      debugPrint('❌ _loadChats ERROR: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() => isLoading = false);  // ← CRITICAL: Stop loading on error

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load chats: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _createNewChat() async {
    debugPrint('➕ Creating new chat...');
    final api = ApiService();

    final baselineMaxId = _maxExistingChatId();

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    setState(() {
      chats.insert(0, {
        'id': tempId,
        'title': 'New Chat',
        'last_message_preview': '',
        'updated_at': DateTime.now().toIso8601String(),
        '_pending': true,
      });
    });

    Map<String, dynamic>? conv;
    try {
      conv = await api.createChat(title: 'New Chat');
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (_) {}

    if (!mounted) return;

    int? chatId = (conv?['id'] is int) ? conv!['id'] as int : int.tryParse('${conv?['id']}');
    if (chatId != null && chatId > 0) {
      _applyResolvedChat(tempId, chatId, title: (conv?['title'] as String?));
    } else {
      Future.microtask(() => _resolvePlaceholder(tempId, baselineMaxId));
    }
  }

  Future<void> _openChat(int userId, Map<String, dynamic> chat) async {
    var id = (chat['id'] as int?) ?? -1;

    final bool pending = chat['_pending'] == true;
    if (pending) {
      final api = ApiService();
      final realId = await api.getNewestChatId();
      if (realId != null && realId > 0 && mounted) {
        setState(() {
          final idx = chats.indexWhere((c) => (c['id'] as int?) == id);
          if (idx >= 0) {
            chats[idx]['id'] = realId;
            chats[idx].remove('_pending');
            id = realId;
          } else {
            id = realId;
          }
        });
      }
    }

    if (id <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setting up chat… try again in a moment')),
        );
      }
      return;
    }

    await Navigator.pushNamed(
      context,
      '/ai',
      arguments: {'userId': userId, 'chatId': id},
    );

    if (mounted) _loadChats();
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inDays == 0) {
        return DateFormat('h:mm a').format(dt);
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return DateFormat('EEEE').format(dt);
      } else {
        return DateFormat('MMM d').format(dt);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('BUILD(ChatList): isLoading=$isLoading, items=${chats.length}');
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userId = args?['userId'] ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewChat,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No chats yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _createNewChat,
                        icon: const Icon(Icons.add),
                        label: const Text('Start New Chat'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index] as Map<String, dynamic>;
                    final int chatId = (chat['id'] as int?) ?? -1;
                    final bool pending = chat['_pending'] == true;

                    final title = (chat['title'] as String?)?.trim();
                    final displayTitle = pending
                        ? 'Creating…'
                        : (title?.isNotEmpty == true ? title! : 'New Chat');

                    final preview = (chat['last_message_preview'] as String?) ?? '';
                    final updatedAt = chat['updated_at'];

                    return Dismissible(
                      key: ValueKey<int>(chatId),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        if (_dontShowDeleteWarning) {
                          return true;
                        }

                        bool dontShowAgain = false;
                        
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setDialogState) => AlertDialog(
                              title: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Delete Chat?'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Are you sure you want to delete "$displayTitle"?',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'This action cannot be undone.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        dontShowAgain = !dontShowAgain;
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: dontShowAgain,
                                          onChanged: (value) {
                                            setDialogState(() {
                                              dontShowAgain = value ?? false;
                                            });
                                          },
                                          activeColor: Colors.deepPurple,
                                        ),
                                        Expanded(
                                          child: Text(
                                            "Don't ask me again",
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (dontShowAgain) {
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('dont_show_delete_warning', true);
                                      if (mounted) {
                                        setState(() {
                                          _dontShowDeleteWarning = true;
                                        });
                                      }
                                    }
                                    Navigator.pop(context, true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        );

                        return confirmed ?? false;
                      },
                      onDismissed: (direction) {
                        print('🗑️ Deleting chat ID: $chatId');
                        final removedIndex = chats.indexWhere((c) => c['id'] == chatId);
                        final removedChat = chat;

                        setState(() {
                          chats.removeWhere((c) => c['id'] == chatId);
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Deleted "$displayTitle"')),
                          );
                        }

                        ApiService().archiveChat(chatId, true).then((ok) {
                          if (!ok && mounted) {
                            setState(() {
                              final insertAt = (removedIndex >= 0 && removedIndex <= chats.length) 
                                  ? removedIndex 
                                  : 0;
                              chats.insert(insertAt, removedChat);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to delete chat — restored')),
                            );
                          }
                        }).catchError((e) {
                          if (!mounted) return;
                          setState(() {
                            final insertAt = (removedIndex >= 0 && removedIndex <= chats.length) 
                                ? removedIndex 
                                : 0;
                            chats.insert(insertAt, removedChat);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Delete failed (network error) — restored')),
                          );
                        });
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white, size: 32),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Icon(Icons.chat, color: Colors.white),
                          ),
                          title: Text(
                            displayTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: pending ? Colors.grey[600] : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: pending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                                  _formatDate(updatedAt),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                          onTap: () async {
                            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                            final userId = args?['userId'] ?? 1;

                            debugPrint('🎯 Tapping on chat ID: ${chat['id']}');

                            _openChat(userId, chat);
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: chats.isNotEmpty
          ? FloatingActionButton(
              onPressed: _createNewChat,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}