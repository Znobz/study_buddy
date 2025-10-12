import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<dynamic> assignments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final api = ApiService();
    final data = await api.getAssignments();
    setState(() {
      assignments = data ?? [];
      isLoading = false;
    });
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Assignment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
            TextField(controller: dueCtrl, decoration: const InputDecoration(labelText: "Due Date (YYYY-MM-DD)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final api = ApiService();
              await api.addAssignment(titleCtrl.text, descCtrl.text, dueCtrl.text);
              Navigator.pop(context);
              _loadAssignments();
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
      appBar: AppBar(title: const Text('Assignments')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : assignments.isEmpty
              ? const Center(child: Text("No assignments yet"))
              : ListView.builder(
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final a = assignments[index];
                    final due = a['due_date'] != null
                        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(a['due_date']))
                        : 'No date';
                    return Card(
                      child: ListTile(
                        title: Text(a['title'] ?? ''),
                        subtitle: Text("Due: $due\n${a['description'] ?? ''}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await ApiService().deleteAssignment(a['assignment_id']);
                            _loadAssignments();
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
