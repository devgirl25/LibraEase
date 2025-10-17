import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';
import '../../services/notificationservice.dart';

class NotificationsPage extends StatelessWidget {
  final NotificationService _notificationService = NotificationService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: PreferredSize(
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
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getNotificationsStream(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('No notifications',
                    style: TextStyle(color: kPrimaryBrown, fontSize: 16)));
          }

          return Column(
            children: [
              // Mark all as read button
              if (docs.any((doc) => !(doc['read'] ?? false)))
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await _notificationService.markAllAsRead(userId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('All notifications marked as read'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.done_all, size: 20),
                      label: const Text('Mark all as read'),
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimaryBrown,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final isUnread = !(data['read'] ?? false);
                    final type = data['type'] ?? 'general';

                    return GestureDetector(
                      onTap: () {
                        if (isUnread) {
                          _notificationService.markAsRead(userId, data.id);
                        }
                      },
                      child: _buildNotificationCard(
                        icon: _getIconForType(type),
                        title: data['title'] ?? '',
                        subtitle: data['message'] ?? '',
                        isUnread: isUnread,
                        cardColor:
                            isUnread ? const Color(0xFFE0DACE) : Colors.white,
                        iconColor: _getIconColorForType(type),
                      ),
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

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isUnread,
    required Color cardColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isUnread
            ? Border.all(color: kPrimaryBrown.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: iconColor,
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        fontSize: 16,
                        color: kPrimaryBrown)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 14,
                        color: kPrimaryBrown.withOpacity(0.8))),
              ],
            ),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'borrow':
        return Icons.book;
      case 'return_reminder':
        return Icons.access_time;
      case 'overdue':
        return Icons.warning;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'renewed':
        return Icons.refresh;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'borrow':
        return const Color(0xFF4CAF50); // Green
      case 'return_reminder':
        return const Color(0xFFFF9800); // Orange
      case 'overdue':
        return const Color(0xFFF44336); // Red
      case 'approved':
        return const Color(0xFF2196F3); // Blue
      case 'rejected':
        return const Color(0xFF9C27B0); // Purple
      case 'renewed':
        return const Color(0xFF00BCD4); // Cyan
      default:
        return kPrimaryBrown;
    }
  }
}
