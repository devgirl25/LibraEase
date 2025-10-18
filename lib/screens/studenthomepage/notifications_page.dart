import 'package:flutter/material.dart';
import '../logins/constants.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // goes back to HomePage
              },
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNotificationCard(
            icon: Icons.access_time,
            title: 'Due date reminder',
            subtitle: 'Your loan for \'Data Structures\' is due in 3 days',
            isUnread: true,
            cardColor: const Color(0xFFE0DACE),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.library_books_outlined,
            title: 'Book Available',
            subtitle: 'The book \'Data Structures\' from your wishlist is now available',
            isUnread: true,
            cardColor: const Color(0xFFE0DACE),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.check_circle_outline,
            title: 'Registration Approved',
            subtitle: 'Your request for book bank has been approved!',
            isUnread: true,
            cardColor: const Color(0xFFE0DACE),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.error_outline,
            iconColor: Colors.red,
            title: 'Overdue Notice',
            subtitle: 'Please return \'Data Structures\' - its now 2 days overdue',
            isUnread: false,
            cardColor: Colors.white,
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            icon: Icons.notifications_active_outlined,
            title: 'Welcome to LibraEase!',
            subtitle: 'Start exploring ......',
            isUnread: false,
            cardColor: Colors.white,
          ),
        ],
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