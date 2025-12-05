import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class FloatingNotificationWidget extends StatefulWidget {
  const FloatingNotificationWidget({super.key});

  @override
  State<FloatingNotificationWidget> createState() => _FloatingNotificationWidgetState();
}

class _FloatingNotificationWidgetState extends State<FloatingNotificationWidget> {
  List<Map<String, dynamic>> notifications = [];
  bool isExpanded = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);
    try {
      final api = ApiService();
      final userId = await api.getUserId();
      final data = await NotificationService.getUserNotifications(userId);

      // Filter for pending notifications only
      final pendingNotifications = data.where((n) =>
      n['status'] == 'pending' &&
          DateTime.parse(n['scheduled_time']).isAfter(DateTime.now())
      ).toList();

      setState(() {
        notifications = pendingNotifications;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _cancelNotification(Map<String, dynamic> notification) async {
    final notificationId = notification['notification_id'];
    final assignmentId = notification['assignment_id'];

    final success = await NotificationService.cancelNotificationById(notificationId, assignmentId);

    if (success) {
      setState(() {
        notifications.removeWhere((n) => n['notification_id'] == notificationId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel reminder'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTimeUntil(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  Widget _buildNotificationBadge() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (notifications.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    '${notifications.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandedNotifications() {
    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Upcoming Reminders',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => isExpanded = false),
                ),
              ],
            ),
          ),
          // Notifications list
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.notifications_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No upcoming reminders',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final scheduledTime = DateTime.parse(notification['scheduled_time']);
                  final assignmentTitle = notification['assignment_title'] ?? notification['title'];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          _formatTimeUntil(scheduledTime),
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      title: Text(
                        assignmentTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        DateFormat('MMM dd, h:mm a').format(scheduledTime),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'cancel') {
                            _cancelNotification(notification);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Cancel'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 140, // Position above main FAB
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
          if (isExpanded) {
            _loadNotifications(); // Refresh when opened
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isExpanded
              ? _buildExpandedNotifications()
              : _buildNotificationBadge(),
        ),
      ),
    );
  }
}