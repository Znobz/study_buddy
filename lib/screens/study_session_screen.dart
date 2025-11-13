import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  List<dynamic> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final api = ApiService();
    final data = await api.getSessions();
    setState(() {
      sessions = data ?? [];
      isLoading = false;
    });
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Study Session"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: dateCtrl,
                decoration:
                    const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty ||
                  descCtrl.text.isEmpty ||
                  dateCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }

              await ApiService().addSession(
                titleCtrl.text,
                descCtrl.text,
                dateCtrl.text,
              );

              Navigator.pop(context);
              _loadSessions();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Sessions')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const Center(child: Text("No sessions scheduled"))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    return Card(
                      child: ListTile(
                        title: Text(s['title'] ?? ''),
                        subtitle: Text(
                            "Date: ${s['session_date']}\nDescription: ${s['description'] ?? ''}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await ApiService().deleteSession(s['session_id']);
                            _loadSessions();
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}