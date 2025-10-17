import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  borrow,
  return_reminder,
  overdue,
  approved,
  rejected,
  renewed,
  general,
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch notifications stream for a user
  Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'read': true});
    }
  }

  /// Send a new notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? additionalData,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.now(),
      'read': false,
      if (additionalData != null) ...additionalData,
    });
  }

  /// Send due date reminder (3 days before due)
  Future<void> sendDueDateReminder({
    required String userId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Due Date Reminder',
      message:
          'Your borrowed book "$bookTitle" is due on ${_formatDate(dueDate)}. Please return it on time.',
      type: NotificationType.return_reminder,
      additionalData: {'dueDate': Timestamp.fromDate(dueDate)},
    );
  }

  /// Send overdue notification
  Future<void> sendOverdueNotification({
    required String userId,
    required String bookTitle,
    required DateTime dueDate,
    required int daysOverdue,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Overdue Book',
      message:
          'The book "$bookTitle" is overdue by $daysOverdue day(s). It was due on ${_formatDate(dueDate)}. Please return it as soon as possible.',
      type: NotificationType.overdue,
      additionalData: {
        'dueDate': Timestamp.fromDate(dueDate),
        'daysOverdue': daysOverdue,
      },
    );
  }

  /// Send borrow request approved notification
  Future<void> sendBorrowApprovedNotification({
    required String userId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Borrow Request Approved',
      message:
          'Your request to borrow "$bookTitle" has been approved! Please collect it from the library. Due date: ${_formatDate(dueDate)}.',
      type: NotificationType.approved,
      additionalData: {'dueDate': Timestamp.fromDate(dueDate)},
    );
  }

  /// Send borrow request rejected notification
  Future<void> sendBorrowRejectedNotification({
    required String userId,
    required String bookTitle,
    String? reason,
  }) async {
    final message = reason != null
        ? 'Your request to borrow "$bookTitle" has been rejected. Reason: $reason'
        : 'Your request to borrow "$bookTitle" has been rejected. Please contact the librarian for more information.';

    await sendNotification(
      userId: userId,
      title: 'Borrow Request Rejected',
      message: message,
      type: NotificationType.rejected,
    );
  }

  /// Send book return confirmation
  Future<void> sendBookReturnedNotification({
    required String userId,
    required String bookTitle,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Book Returned',
      message: 'Thank you for returning "$bookTitle" to the library.',
      type: NotificationType.general,
    );
  }

  /// Send book renewed notification
  Future<void> sendBookRenewedNotification({
    required String userId,
    required String bookTitle,
    required DateTime newDueDate,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Book Renewed',
      message:
          '"$bookTitle" has been renewed successfully. New due date: ${_formatDate(newDueDate)}.',
      type: NotificationType.renewed,
      additionalData: {'dueDate': Timestamp.fromDate(newDueDate)},
    );
  }

  /// Check for books that need due date reminders (3 days before due)
  Future<void> checkAndSendDueDateReminders() async {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));

    try {
      // Get all active borrow requests
      final borrowSnapshot = await _firestore
          .collection('borrow_requests')
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in borrowSnapshot.docs) {
        final data = doc.data();
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final userId = data['userId'] as String;
        final bookTitle = data['bookTitle'] as String;

        // Check if reminder was already sent
        final reminderSent = data['reminderSent'] ?? false;

        // Send reminder if due date is within 3 days and reminder not sent yet
        if (!reminderSent &&
            dueDate.isAfter(now) &&
            dueDate.isBefore(threeDaysFromNow.add(const Duration(days: 1)))) {
          await sendDueDateReminder(
            userId: userId,
            bookTitle: bookTitle,
            dueDate: dueDate,
          );

          // Mark reminder as sent
          await doc.reference.update({'reminderSent': true});
        }
      }
    } catch (e) {
      print('Error checking due date reminders: $e');
    }
  }

  /// Check for overdue books and send notifications
  Future<void> checkAndSendOverdueNotifications() async {
    final now = DateTime.now();

    try {
      // Get all accepted borrow requests
      final borrowSnapshot = await _firestore
          .collection('borrow_requests')
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in borrowSnapshot.docs) {
        final data = doc.data();
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final userId = data['userId'] as String;
        final bookTitle = data['bookTitle'] as String;

        // Check if book is overdue
        if (now.isAfter(dueDate)) {
          final daysOverdue = now.difference(dueDate).inDays;
          final lastOverdueNotification = data['lastOverdueNotification'];

          // Send overdue notification once per day
          bool shouldSendNotification = true;
          if (lastOverdueNotification != null) {
            final lastNotificationDate =
                (lastOverdueNotification as Timestamp).toDate();
            final daysSinceLastNotification =
                now.difference(lastNotificationDate).inDays;
            shouldSendNotification = daysSinceLastNotification >= 1;
          }

          if (shouldSendNotification) {
            await sendOverdueNotification(
              userId: userId,
              bookTitle: bookTitle,
              dueDate: dueDate,
              daysOverdue: daysOverdue,
            );

            // Update last overdue notification timestamp
            await doc.reference
                .update({'lastOverdueNotification': Timestamp.now()});
          }
        }
      }
    } catch (e) {
      print('Error checking overdue notifications: $e');
    }
  }

  /// Format date to readable string
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
