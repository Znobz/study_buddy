import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (!mounted) return; // Safety check
    
    setState(() => isLoading = true);
    final api = ApiService();
    final data = await api.listChats();
    
    if (!mounted) return; // Check again after async call
    
    setState(() {
      chats = data ?? [];
      isLoading = false;
    });
  }

  Future<void> _createNewChat() async {
    print('➕ Creating new chat...');
    final api = ApiService();
    final conv = await api.createChat(title: 'New Chat');
    if (conv != null && mounted) {
      final chatId = conv['id'] as int;
      print('➕ New chat created with ID: $chatId');
      
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final userId = args?['userId'] ?? 1;
      
      print('➕ Navigating to new chat with userId=$userId, chatId=$chatId');
      
      // Navigate to AI Tutor with this chat ID
      await Navigator.pushNamed(
        context,
        '/ai',
        arguments: {'userId': userId, 'chatId': chatId},
      );
      
      // Only refresh if still mounted and add a small delay
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _loadChats();
        }
      }
    }
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
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
                    final chat = chats[index];
                    final chatId = chat['id'] as int;
                    final title = chat['title'] ?? 'New Chat';
                    final preview = chat['last_message_preview'] ?? '';
                    final updatedAt = chat['updated_at'];

                    return Dismissible(
                      key: Key('chat_$chatId'),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        // Show confirmation dialog
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Chat'),
                            content: Text('Are you sure you want to delete "$title"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        // Archive the chat
                        print('🗑️ Deleting chat ID: $chatId');
                        final success = await ApiService().archiveChat(chatId, true);
                        
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted "$title"'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          _loadChats(); // Refresh the list
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to delete chat')),
                          );
                          _loadChats(); // Refresh anyway to restore UI
                        }
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
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Text(
                            _formatDate(updatedAt),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          onTap: () async {
                            print('🎯 Tapping on chat ID: $chatId');
                            print('🎯 Navigating with arguments: userId=$userId, chatId=$chatId');
                            
                            // Navigate to AI Tutor with this chat ID
                            await Navigator.pushNamed(
                              context,
                              '/ai',
                              arguments: {'userId': userId, 'chatId': chatId},
                            );
                            
                            // Only refresh if still mounted and add a small delay
                            if (mounted) {
                              print('🎯 Returned from chat, refreshing list...');
                              await Future.delayed(const Duration(milliseconds: 300));
                              if (mounted) {
                                _loadChats();
                              }
                            }
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