import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../logins/constants.dart';
import '../../services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        backgroundColor: kScaffoldBackground,
        body: Center(child: Text("Please login to see notifications")),
      );
    }

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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: NotificationService().getNotificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data();
              final isUnread = !(data['read'] ?? false);
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final type = data['type'] ?? 'general';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildNotificationCard(
                  context: context,
                  notificationId: doc.id,
                  userId: user.uid,
                  icon: _getIconForType(type),
                  iconColor: _getIconColorForType(type),
                  title: data['title'] ?? 'Notification',
                  subtitle: data['message'] ?? '',
                  timestamp: timestamp,
                  isUnread: isUnread,
                  cardColor: isUnread ? const Color(0xFFE0DACE) : Colors.white,
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'due_reminder':
        return Icons.access_time;
      case 'overdue':
        return Icons.error_outline;
      case 'book_available':
        return Icons.library_books_outlined;
      case 'registration':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'overdue':
        return Colors.red;
      case 'due_reminder':
        return Colors.orange;
      case 'book_available':
      case 'registration':
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required String notificationId,
    required String userId,
    required IconData icon,
    required String title,
    required String subtitle,
    DateTime? timestamp,
    required bool isUnread,
    required Color cardColor,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: isUnread ? () async {
        await NotificationService().markAsRead(userId, notificationId);
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: kPrimaryBrown,
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kPrimaryBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: kPrimaryBrown.withOpacity(0.8),
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: kPrimaryBrown.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: kPrimaryBrown,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}