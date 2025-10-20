import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_helpers.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> init() async {
    // Start periodic Firestore-based notification checking
    startPeriodicNotificationCheck();
    print('NotificationService initialized.');
  }

  /// Send notification to a specific user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'message': message,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  /// Get notifications stream for a user
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(
      String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
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

  /// Check for books due in 3 days and send notifications
  Future<void> checkAndSendDueDateNotifications() async {
    try {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));

      // Get all borrow requests that are accepted/borrowed
      final borrowRequestsSnapshot = await _firestore
          .collection('borrow_requests')
          .where('status', whereIn: ['accepted', 'borrowed']).get();

      for (final doc in borrowRequestsSnapshot.docs) {
        final data = doc.data();
        final dueDate = toDateTime(data['dueDate']);
        final userId = data['userId'] as String?;
        final bookTitle = data['bookTitle'] as String?;

        if (dueDate == null || userId == null || bookTitle == null) continue;

        // Check if due date is exactly 3 days from now (within a day range)
        final daysDifference = dueDate.difference(now).inDays;

        if (daysDifference == 3) {
          // Check if notification already sent for this book and user
          final existingNotification = await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .where('type', isEqualTo: 'due_reminder')
              .where('message',
                  isEqualTo:
                      'Your book "$bookTitle" is due in 3 days. Please return it on time to avoid late fees.')
              .get();

          if (existingNotification.docs.isEmpty) {
            await sendNotification(
              userId: userId,
              title: 'Book Due Soon',
              message:
                  'Your book "$bookTitle" is due in 3 days. Please return it on time to avoid late fees.',
              type: 'due_reminder',
            );
          }
        }

        // Also send overdue notifications
        if (daysDifference < 0) {
          final daysOverdue = daysDifference.abs();

          // Check if overdue notification already sent today
          final today = DateTime(now.year, now.month, now.day);
          final existingOverdueNotification = await _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .where('type', isEqualTo: 'overdue')
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(today))
              .get();

          if (existingOverdueNotification.docs.isEmpty) {
            await sendNotification(
              userId: userId,
              title: 'Book Overdue',
              message:
                  'Your book "$bookTitle" is $daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue. Please return it immediately to avoid additional fees.',
              type: 'overdue',
            );
          }
        }
      }
    } catch (e) {
      print('Error checking due date notifications: $e');
    }
  }

  /// Initialize periodic notification checking (call this when app starts)
  void startPeriodicNotificationCheck() {
    // Check immediately
    checkAndSendDueDateNotifications();

    // Note: In a production app, you would use Cloud Functions with scheduled triggers
    // For now, this can be called periodically when the app is active
  }
}
