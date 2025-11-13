import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:study_buddy/services/notification_service.dart';

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
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("New Assignment"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? "No date selected"
                              : "Due: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}",
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedDate = picked; // ✅ now updates immediately
                            });
                          }
                        },
                      ),
                    ],
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
                  if (titleCtrl.text.isEmpty || selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  final api = ApiService();

                  try {
                    await api.addAssignment(
                      titleCtrl.text,
                      descCtrl.text,
                      DateFormat('yyyy-MM-dd').format(selectedDate!),
                    );

                    await NotificationService.scheduleAssignmentReminder(
                      title: titleCtrl.text,
                      dueDate: selectedDate!,
                    );

                    Navigator.pop(context);
                    _loadAssignments();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text("Assignment saved and reminder set!")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error saving assignment: $e")),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assignments')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "addAssignment",
            onPressed: _showAddDialog,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "testNotification",
            backgroundColor: Colors.blue,
            onPressed: () async {
              await NotificationService.scheduleAssignmentReminder(
                title: "Test Notification",
                dueDate: DateTime.now().add(const Duration(seconds: 10)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Test notification scheduled!")),
              );
            },
            child: const Icon(Icons.notifications),
          ),
        ],
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
                        ? DateFormat('yyyy-MM-dd')
                            .format(DateTime.parse(a['due_date']))
                        : 'No date';
                    return Card(
                      child: ListTile(
                        title: Text(a['title'] ?? ''),
                        subtitle:
                            Text("Due: $due\n${a['description'] ?? ''}"),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await ApiService()
                                .deleteAssignment(a['assignment_id']);
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
