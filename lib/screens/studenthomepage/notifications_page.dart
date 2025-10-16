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

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index];
              final isUnread = !(data['read'] ?? false);

              return GestureDetector(
                onTap: () {
                  if (isUnread) {
                    _notificationService.markAsRead(userId, data.id);
                  }
                },
                child: _buildNotificationCard(
                  icon: Icons.notifications,
                  title: data['title'] ?? '',
                  subtitle: data['message'] ?? '',
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

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isUnread,
    required Color cardColor,
    Color iconColor = Colors.white,
  }) {
    return Container(
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
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
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: kPrimaryBrown,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
