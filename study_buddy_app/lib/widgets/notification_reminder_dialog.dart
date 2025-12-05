import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationReminderDialog extends StatefulWidget {
  final String assignmentTitle;
  final DateTime dueDate;
  final Function(DateTime) onReminderScheduled;

  const NotificationReminderDialog({
    super.key,
    required this.assignmentTitle,
    required this.dueDate,
    required this.onReminderScheduled,
  });

  @override
  State<NotificationReminderDialog> createState() => _NotificationReminderDialogState();
}

class _NotificationReminderDialogState extends State<NotificationReminderDialog> {
  DateTime? selectedDateTime;
  String selectedOption = 'custom';

  @override
  void initState() {
    super.initState();
    // Default to 1 day before due date
    selectedDateTime = widget.dueDate.subtract(const Duration(days: 1));
  }

  void _selectQuickOption(String option, Duration subtraction) {
    setState(() {
      selectedOption = option;
      selectedDateTime = widget.dueDate.subtract(subtraction);
    });
  }

  Future<void> _selectCustomDateTime() async {
    setState(() => selectedOption = 'custom');

    // Date picker
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: widget.dueDate,
    );

    if (date == null) return;

    // Time picker
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Widget _buildQuickOptionCard({
    required String title,
    required String description,
    required String optionKey,
    required Duration subtraction,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedOption == optionKey;
    final reminderTime = widget.dueDate.subtract(subtraction);

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => _selectQuickOption(optionKey, subtraction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12), // ✅ Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // ✅ Center content
            children: [
              Icon(
                icon,
                size: 28, // ✅ Slightly smaller icon
                color: isSelected ? color : Colors.grey[600],
              ),
              const SizedBox(height: 6), // ✅ Reduced spacing
              Flexible( // ✅ Added Flexible to prevent overflow
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12, // ✅ Reduced font size
                    color: isSelected ? color : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1, // ✅ Prevent wrapping
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible( // ✅ Added Flexible to prevent overflow
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 10, // ✅ Smaller font
                    color: isSelected ? color : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1, // ✅ Prevent wrapping
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Flexible( // ✅ Added Flexible to prevent overflow
                child: Text(
                  DateFormat('MMM dd\nh:mm a').format(reminderTime), // ✅ Shorter format with line break
                  style: TextStyle(
                    fontSize: 9, // ✅ Even smaller font
                    fontWeight: FontWeight.w500,
                    color: isSelected ? color : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // ✅ Allow 2 lines for date
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSchedule = selectedDateTime != null &&
        selectedDateTime!.isAfter(DateTime.now());

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications_active, color: Colors.deepPurple),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Set Reminder',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'When would you like to be reminded about "${widget.assignmentTitle}"?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Due: ${DateFormat('EEEE, MMM dd, yyyy').format(widget.dueDate)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 20),

              // Quick Options Grid
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 0.85, // ✅ Increased height to fit content
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  _buildQuickOptionCard(
                    title: '1 Hour Before',
                    description: 'Last minute',
                    optionKey: '1hour',
                    subtraction: Duration(hours: 1),
                    icon: Icons.schedule,
                    color: Colors.orange,
                  ),
                  _buildQuickOptionCard(
                    title: '1 Day Before',
                    description: 'Perfect timing',
                    optionKey: '1day',
                    subtraction: Duration(days: 1),
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                  _buildQuickOptionCard(
                    title: '3 Days Before',
                    description: 'Early prep',
                    optionKey: '3days',
                    subtraction: Duration(days: 3),
                    icon: Icons.event_note,
                    color: Colors.green,
                  ),
                  _buildQuickOptionCard(
                    title: '1 Week Before',
                    description: 'Max prep time',
                    optionKey: '1week',
                    subtraction: Duration(days: 7),
                    icon: Icons.date_range,
                    color: Colors.purple,
                  ),
                ],
              ),

              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),

              // Custom Option
              Card(
                elevation: selectedOption == 'custom' ? 4 : 1,
                color: selectedOption == 'custom' ? Colors.deepPurple.withOpacity(0.1) : null,
                child: InkWell(
                  onTap: _selectCustomDateTime,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: selectedOption == 'custom' ? Colors.deepPurple : Colors.grey[600],
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Custom Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedOption == 'custom' ? Colors.deepPurple : Colors.black87,
                                ),
                              ),
                              Text(
                                selectedDateTime != null
                                    ? DateFormat('EEEE, MMM dd, yyyy at h:mm a').format(selectedDateTime!)
                                    : 'Tap to select date & time',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedOption == 'custom' ? Colors.deepPurple : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.edit,
                          size: 20,
                          color: selectedOption == 'custom' ? Colors.deepPurple : Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (!canSchedule && selectedDateTime != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selected time is in the past. Please choose a future time.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Skip'),
        ),
        ElevatedButton(
          onPressed: canSchedule ? () {
            widget.onReminderScheduled(selectedDateTime!);
            Navigator.pop(context);
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: Text('Set Reminder'),
        ),
      ],
    );
  }
}