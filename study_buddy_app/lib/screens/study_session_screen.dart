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
    final topicCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Study Session"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: "Topic")),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date (YYYY-MM-DD HH:mm)")),
              TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: "Duration (mins)")),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Notes")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await ApiService().addSession(
                topicCtrl.text,
                dateCtrl.text,
                int.tryParse(durationCtrl.text) ?? 60,
                notesCtrl.text,
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
                        title: Text(s['topic'] ?? ''),
                        subtitle: Text("Date: ${s['date']}\nNotes: ${s['notes'] ?? ''}"),
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
