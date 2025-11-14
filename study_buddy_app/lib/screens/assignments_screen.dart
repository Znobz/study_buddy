import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:study_buddy/services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
    setState(() => isLoading = true);
    final api = ApiService();
    try {
      final data = await api.getAssignments();
      setState(() {
        assignments = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading assignments: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load assignments: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _markAsDone(Map<String, dynamic> assignment) async {
    final api = ApiService();
    final assignmentId = assignment['assignment_id'];
    final title = assignment['title'] ?? '';
    final description = assignment['description'] ?? '';
    final dueDate = assignment['due_date'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(assignment['due_date']))
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    final priority = assignment['priority']?.toString().toLowerCase() ?? 'medium';

    final success = await api.updateAssignment(
      assignmentId,
      title,
      description,
      dueDate,
      priority: priority,
      status: 'completed',
    );

    if (success) {
      _loadAssignments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Assignment marked as done!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to mark assignment as done. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<PlatformFile?> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: kIsWeb,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;
      return result.files.single;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick file: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _openAttachment(Map<String, dynamic> assignment) async {
    final relativePath = assignment['file_path']?.toString();
    if (relativePath == null || relativePath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No attachment available for this assignment.')),
        );
      }
      return;
    }

    final api = ApiService();
    final url = api.buildAttachmentUrl(relativePath);
    final uri = Uri.parse(url);

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open attachment at $url')),
      );
    }
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? selectedDate;
    String selectedPriority = 'medium'; // Default priority
    String selectedStatus = 'pending'; // Default status: "Not Started"
    PlatformFile? selectedAttachment;

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
                  // Priority selector
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: "Priority",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Low'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Row(
                          children: [
                            Icon(Icons.remove, color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Text('Medium'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('High'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedPriority = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  // Status selector
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Row(
                          children: [
                            Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 18),
                            SizedBox(width: 8),
                            Text('Not Started'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_empty, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('In Progress'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Completed'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedStatus = value;
                        });
                      }
                    },
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Attachment (optional)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (selectedAttachment != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedAttachment!.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove attachment',
                            onPressed: () {
                              setStateDialog(() {
                                selectedAttachment = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final file = await _pickAttachment();
                      if (file != null) {
                        setStateDialog(() {
                          selectedAttachment = file;
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      selectedAttachment == null
                          ? 'Add attachment'
                          : 'Replace attachment',
                    ),
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

                  print('📝 Saving assignment...');
                  print('  - Title: ${titleCtrl.text}');
                  print('  - Description: ${descCtrl.text}');
                  print('  - Due Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}');
                  print('  - Priority: $selectedPriority');
                  print('  - Status: $selectedStatus');
                  
                  // Show loading indicator
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  try {
                    final success = await api.addAssignment(
                      titleCtrl.text,
                      descCtrl.text,
                      DateFormat('yyyy-MM-dd').format(selectedDate!),
                      priority: selectedPriority,
                      status: selectedStatus,
                        attachment: selectedAttachment,
                    );
                    
                    // Close loading indicator
                    if (mounted) {
                      Navigator.of(context).pop(); // Close loading dialog
                    }

                    if (success) {
                    try {
                      await NotificationService.scheduleAssignmentReminder(
                        title: titleCtrl.text,
                        dueDate: selectedDate!,
                      );
                    } catch (e) {
                      print('Warning: Could not schedule notification: $e');
                    }

                    Navigator.pop(context);
                    _loadAssignments();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Assignment saved and reminder set!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    const errorMsg = "Error saving assignment. Please check your connection and try again.";
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMsg),
                          duration: const Duration(seconds: 5),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                  } catch (e) {
                    // Close loading indicator if still open
                    if (mounted) {
                      Navigator.of(context).pop(); // Close loading dialog if open
                    }
                    print('❌ Exception in save: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: ${e.toString()}"),
                          duration: const Duration(seconds: 5),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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

  void _showEditDialog(Map<String, dynamic> assignment) {
    final titleCtrl = TextEditingController(text: assignment['title'] ?? '');
    final descCtrl = TextEditingController(text: assignment['description'] ?? '');
    DateTime? selectedDate;
    String selectedPriority = assignment['priority']?.toString().toLowerCase() ?? 'medium';
    String selectedStatus = assignment['status']?.toString().toLowerCase() ?? 'pending';
    PlatformFile? replacementAttachment;
    final existingAttachmentName = assignment['file_name']?.toString();
    final hasExistingAttachment = (assignment['file_path']?.toString().isNotEmpty ?? false);
    
    // Parse existing due date if available
    if (assignment['due_date'] != null) {
      try {
        selectedDate = DateTime.parse(assignment['due_date']);
      } catch (e) {
        print('Error parsing due date: $e');
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Edit Assignment"),
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
                  // Priority selector
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: "Priority",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'low',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Low'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'medium',
                        child: Row(
                          children: [
                            Icon(Icons.remove, color: Colors.orange, size: 18),
                            SizedBox(width: 8),
                            Text('Medium'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'high',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('High'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedPriority = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  // Status selector
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pending',
                        child: Row(
                          children: [
                            Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 18),
                            SizedBox(width: 8),
                            Text('Not Started'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_empty, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('In Progress'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Completed'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedStatus = value;
                        });
                      }
                    },
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
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Attachment',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasExistingAttachment && replacementAttachment == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              existingAttachmentName ?? 'Existing attachment',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openAttachment(assignment),
                            child: const Text('Open'),
                          ),
                        ],
                      ),
                    ),
                  if (replacementAttachment != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              replacementAttachment!.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Remove attachment',
                            onPressed: () {
                              setStateDialog(() {
                                replacementAttachment = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final file = await _pickAttachment();
                      if (file != null) {
                        setStateDialog(() {
                          replacementAttachment = file;
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(
                      replacementAttachment == null
                          ? (hasExistingAttachment ? 'Replace attachment' : 'Add attachment')
                          : 'Choose different file',
                    ),
                  ),
                  if (hasExistingAttachment)
                    const Text(
                      'Uploading a new file will replace the current attachment.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      const SnackBar(content: Text("Please fill all required fields")),
                    );
                    return;
                  }

                  final api = ApiService();

                  final success = await api.updateAssignment(
                    assignment['assignment_id'],
                    titleCtrl.text,
                    descCtrl.text,
                    DateFormat('yyyy-MM-dd').format(selectedDate!),
                    priority: selectedPriority,
                    status: selectedStatus,
                    attachment: replacementAttachment,
                  );

                  if (success) {
                    Navigator.pop(context);
                    _loadAssignments();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Assignment updated successfully!")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Error updating assignment. Please try again.")),
                    );
                  }
                },
                child: const Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupedAssignmentsList() {
    // Group assignments by priority and sort by due date within each group
    final highPriority = assignments.where((a) => 
      a['priority']?.toString().toLowerCase() == 'high'
    ).toList();
    
    final mediumPriority = assignments.where((a) => 
      a['priority']?.toString().toLowerCase() == 'medium' ||
      a['priority'] == null || a['priority'].toString().isEmpty
    ).toList();
    
    final lowPriority = assignments.where((a) => 
      a['priority']?.toString().toLowerCase() == 'low'
    ).toList();

    // Sort each group by due date (closest first, nulls last)
    highPriority.sort((a, b) {
      final dateA = a['due_date'];
      final dateB = b['due_date'];
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // nulls go to end
      if (dateB == null) return -1; // nulls go to end
      try {
        final parsedA = DateTime.parse(dateA);
        final parsedB = DateTime.parse(dateB);
        return parsedA.compareTo(parsedB); // ascending: closest first
      } catch (e) {
        return 0;
      }
    });

    mediumPriority.sort((a, b) {
      final dateA = a['due_date'];
      final dateB = b['due_date'];
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      try {
        final parsedA = DateTime.parse(dateA);
        final parsedB = DateTime.parse(dateB);
        return parsedA.compareTo(parsedB);
      } catch (e) {
        return 0;
      }
    });

    lowPriority.sort((a, b) {
      final dateA = a['due_date'];
      final dateB = b['due_date'];
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      try {
        final parsedA = DateTime.parse(dateA);
        final parsedB = DateTime.parse(dateB);
        return parsedA.compareTo(parsedB);
      } catch (e) {
        return 0;
      }
    });

    final List<Widget> widgets = [];

    // High Priority Section
    if (highPriority.isNotEmpty) {
      widgets.add(_buildPriorityHeader('High Priority', Colors.red, Icons.arrow_upward));
      widgets.addAll(highPriority.map((a) => _buildAssignmentCard(a)));
    }

    // Medium Priority Section
    if (mediumPriority.isNotEmpty) {
      widgets.add(_buildPriorityHeader('Medium Priority', Colors.orange, Icons.remove));
      widgets.addAll(mediumPriority.map((a) => _buildAssignmentCard(a)));
    }

    // Low Priority Section
    if (lowPriority.isNotEmpty) {
      widgets.add(_buildPriorityHeader('Low Priority', Colors.green, Icons.arrow_downward));
      widgets.addAll(lowPriority.map((a) => _buildAssignmentCard(a)));
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: widgets,
    );
  }

  Widget _buildPriorityHeader(String title, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> a) {
    final due = a['due_date'] != null
        ? DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(a['due_date']))
        : 'No date';
    
    // Priority color and icon
    Color priorityColor;
    IconData priorityIcon;
    String priorityText;
    switch (a['priority']?.toString().toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        priorityIcon = Icons.arrow_upward;
        priorityText = 'High';
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityIcon = Icons.arrow_downward;
        priorityText = 'Low';
        break;
      default:
        priorityColor = Colors.orange;
        priorityIcon = Icons.remove;
        priorityText = 'Medium';
    }

    // Status color and icon
    Color statusColor;
    IconData statusIcon;
    String statusText;
    switch (a['status']?.toString().toLowerCase()) {
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_empty;
        statusText = 'In Progress';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
        statusText = 'Not Started';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                a['title'] ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: priorityColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(priorityIcon, size: 14, color: priorityColor),
                  const SizedBox(width: 4),
                  Text(
                    priorityText,
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Due: $due"),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (a['description'] != null && a['description'].toString().isNotEmpty)
              Text(a['description'] ?? ''),
            if (a['file_path'] != null && a['file_path'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextButton.icon(
                  onPressed: () => _openAttachment(a),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: Text(
                    a['file_name']?.toString() ?? 'View attachment',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mark as Done button (only show if not already completed)
            if (a['status']?.toString().toLowerCase() != 'completed')
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                tooltip: 'Mark as Done',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _markAsDone(a),
              ),
            // PopupMenuButton for Edit and Delete
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'edit') {
                  _showEditDialog(a);
                } else if (value == 'delete') {
                  await ApiService().deleteAssignment(a['assignment_id']);
                  _loadAssignments();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
              : _buildGroupedAssignmentsList(),
    );
  }
}
