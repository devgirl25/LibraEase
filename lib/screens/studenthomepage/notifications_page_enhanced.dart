import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';
import '../../services/notification_manager.dart';

class NotificationsPageEnhanced extends StatelessWidget {
  final NotificationManager _notificationManager = NotificationManager();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  NotificationsPageEnhanced({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationManager.getNotificationsStream(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              if (docs.any((doc) => !(doc['read'] ?? false)))
                _buildMarkAllReadButton(context, docs),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isUnread = !(data['read'] ?? false);
                    final type = data['type'] ?? 'general';

                    return _buildNotificationCard(
                      context: context,
                      notificationId: docs[index].id,
                      type: type,
                      title: data['title'] ?? '',
                      subtitle: data['message'] ?? '',
                      timestamp: data['timestamp'] as Timestamp?,
                      isUnread: isUnread,
                      data: data,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: Container(
        decoration: const BoxDecoration(
          color: kPrimaryBrown,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Notifications',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == 'mark_all_read') {
                  await _notificationManager.markAllAsRead(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('All notifications marked as read')),
                    );
                  }
                } else if (value == 'delete_all') {
                  await _showDeleteAllDialog(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, size: 20),
                      SizedBox(width: 12),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete all', style: TextStyle(color: Colors.red)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimaryBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something important happens',
            style: TextStyle(
              fontSize: 14,
              color: kPrimaryBrown.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMarkAllReadButton(BuildContext context, List<QueryDocumentSnapshot> docs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton.icon(
        onPressed: () async {
          await _notificationManager.markAllAsRead(userId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All notifications marked as read')),
            );
          }
        },
        icon: const Icon(Icons.done_all, size: 18),
        label: const Text('Mark all as read'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryBrown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required String notificationId,
    required String type,
    required String title,
    required String subtitle,
    required Timestamp? timestamp,
    required bool isUnread,
    required Map<String, dynamic> data,
  }) {
    final notificationInfo = _getNotificationInfo(type);

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await _notificationManager.deleteNotification(userId, notificationId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // In a real app, you'd want to restore the notification
                },
              ),
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () async {
          if (isUnread) {
            await _notificationManager.markAsRead(userId, notificationId);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFE0DACE) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isUnread
                ? Border.all(color: kPrimaryBrown.withOpacity(0.2), width: 2)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: notificationInfo.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(notificationInfo.icon,
                    color: notificationInfo.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 16,
                                  color: kPrimaryBrown)),
                        ),
                        if (timestamp != null)
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: kPrimaryBrown.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 14,
                            color: kPrimaryBrown.withOpacity(0.8),
                            height: 1.4)),
                    if (_shouldShowAction(type, data)) ...[
                      const SizedBox(height: 12),
                      _buildActionButton(context, type, data),
                    ],
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: kPrimaryBrown,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  NotificationInfo _getNotificationInfo(String type) {
    switch (type) {
      case 'due_date_reminder':
        return NotificationInfo(
          icon: Icons.calendar_today,
          color: Colors.orange,
        );
      case 'overdue':
        return NotificationInfo(
          icon: Icons.warning_rounded,
          color: Colors.red,
        );
      case 'borrow_success':
      case 'borrow_approved':
        return NotificationInfo(
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case 'borrow_rejected':
        return NotificationInfo(
          icon: Icons.cancel,
          color: Colors.red,
        );
      case 'book_renewed':
        return NotificationInfo(
          icon: Icons.refresh,
          color: Colors.blue,
        );
      case 'book_returned':
        return NotificationInfo(
          icon: Icons.assignment_turned_in,
          color: Colors.teal,
        );
      case 'registration_approved':
        return NotificationInfo(
          icon: Icons.verified,
          color: Colors.green,
        );
      case 'registration_rejected':
        return NotificationInfo(
          icon: Icons.info,
          color: Colors.orange,
        );
      case 'new_book':
      case 'wishlist_available':
        return NotificationInfo(
          icon: Icons.book,
          color: Colors.purple,
        );
      case 'announcement':
        return NotificationInfo(
          icon: Icons.campaign,
          color: Colors.indigo,
        );
      default:
        return NotificationInfo(
          icon: Icons.notifications,
          color: kPrimaryBrown,
        );
    }
  }

  bool _shouldShowAction(String type, Map<String, dynamic> data) {
    return type == 'due_date_reminder' ||
        type == 'overdue' ||
        type == 'wishlist_available';
  }

  Widget _buildActionButton(
      BuildContext context, String type, Map<String, dynamic> data) {
    String buttonText;
    VoidCallback onPressed;

    switch (type) {
      case 'due_date_reminder':
      case 'overdue':
        buttonText = 'Renew Book';
        onPressed = () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Navigate to book details to renew')),
          );
        };
        break;
      case 'wishlist_available':
        buttonText = 'Borrow Now';
        onPressed = () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Navigate to book details to borrow')),
          );
        };
        break;
      default:
        buttonText = 'View';
        onPressed = () {};
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryBrown,
        side: BorderSide(color: kPrimaryBrown.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(buttonText, style: const TextStyle(fontSize: 12)),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showDeleteAllDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Notifications'),
          content: const Text(
              'Are you sure you want to delete all notifications? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _notificationManager.deleteAllNotifications(userId);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('All notifications deleted')),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }
}

class NotificationInfo {
  final IconData icon;
  final Color color;

  NotificationInfo({required this.icon, required this.color});
}
