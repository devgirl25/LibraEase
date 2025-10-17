import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendDueDateReminderNotification({
    required String userId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    String message;
    if (daysUntilDue == 3) {
      message = 'Reminder: "$bookTitle" is due in 3 days (${_formatDate(dueDate)}). Please return it on time.';
    } else if (daysUntilDue == 1) {
      message = 'Urgent: "$bookTitle" is due tomorrow (${_formatDate(dueDate)}). Please return it soon.';
    } else if (daysUntilDue == 0) {
      message = 'Today is the last day! "$bookTitle" is due today. Please return it before the library closes.';
    } else {
      message = 'Reminder: "$bookTitle" is due on ${_formatDate(dueDate)}.';
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Due Date Reminder',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'due_date_reminder',
      'bookTitle': bookTitle,
      'dueDate': dueDate,
    });
  }

  Future<void> sendOverdueNotification({
    required String userId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    final daysOverdue = DateTime.now().difference(dueDate).inDays;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Overdue Book Alert',
      'message': 'URGENT: "$bookTitle" is $daysOverdue ${daysOverdue == 1 ? 'day' : 'days'} overdue! '
          'Please return it immediately to avoid penalties. Due date was ${_formatDate(dueDate)}.',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'overdue',
      'bookTitle': bookTitle,
      'dueDate': dueDate,
      'daysOverdue': daysOverdue,
    });
  }

  Future<void> sendBorrowSuccessNotification({
    required String userId,
    required String bookTitle,
    required DateTime borrowDate,
    required DateTime dueDate,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Book Borrowed Successfully',
      'message': 'You have successfully borrowed "$bookTitle". '
          'Please return it by ${_formatDate(dueDate)}. Happy reading!',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'borrow_success',
      'bookTitle': bookTitle,
      'borrowDate': borrowDate,
      'dueDate': dueDate,
    });
  }

  Future<void> sendBorrowApprovedNotification({
    required String userId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Borrow Request Approved',
      'message': 'Your request to borrow "$bookTitle" has been approved! '
          'Please collect the book from the library. Due date: ${_formatDate(dueDate)}.',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'borrow_approved',
      'bookTitle': bookTitle,
      'dueDate': dueDate,
    });
  }

  Future<void> sendBorrowRejectedNotification({
    required String userId,
    required String bookTitle,
    required String reason,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Borrow Request Rejected',
      'message': 'Your request to borrow "$bookTitle" has been rejected. '
          'Reason: $reason. Please contact the library for more information.',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'borrow_rejected',
      'bookTitle': bookTitle,
      'reason': reason,
    });
  }

  Future<void> sendBookRenewedNotification({
    required String userId,
    required String bookTitle,
    required DateTime oldDueDate,
    required DateTime newDueDate,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Book Renewed Successfully',
      'message': '"$bookTitle" has been renewed successfully! '
          'New due date: ${_formatDate(newDueDate)}. Previous due date was ${_formatDate(oldDueDate)}.',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'book_renewed',
      'bookTitle': bookTitle,
      'oldDueDate': oldDueDate,
      'newDueDate': newDueDate,
    });
  }

  Future<void> sendBookReturnedNotification({
    required String userId,
    required String bookTitle,
    required DateTime returnDate,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Book Returned',
      'message': 'Thank you for returning "$bookTitle" on ${_formatDate(returnDate)}. '
          'We hope you enjoyed reading it!',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'book_returned',
      'bookTitle': bookTitle,
      'returnDate': returnDate,
    });
  }

  Future<void> sendRegistrationApprovedNotification({
    required String userId,
    required String studentName,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Registration Approved',
      'message': 'Congratulations $studentName! Your library registration has been approved. '
          'You can now borrow books from the library. Visit the library to collect your library card.',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'registration_approved',
    });
  }

  Future<void> sendRegistrationRejectedNotification({
    required String userId,
    required String reason,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Registration Update',
      'message': 'Your library registration needs attention. '
          'Reason: $reason. Please contact the library office for more information.',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'registration_rejected',
      'reason': reason,
    });
  }

  Future<void> sendNewBookAvailableNotification({
    required String userId,
    required String bookTitle,
    required String author,
    required String category,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'New Book Available',
      'message': 'A new book "$bookTitle" by $author has been added to the library. '
          'Category: $category. Check it out now!',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'new_book',
      'bookTitle': bookTitle,
      'author': author,
      'category': category,
    });
  }

  Future<void> sendWishlistBookAvailableNotification({
    required String userId,
    required String bookTitle,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': 'Wishlist Book Available',
      'message': 'Great news! "$bookTitle" from your wishlist is now available for borrowing. '
          'Hurry up and borrow it before someone else does!',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'wishlist_available',
      'bookTitle': bookTitle,
    });
  }

  Future<void> sendLibraryAnnouncementNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'announcement',
    });
  }

  Future<void> checkAndSendDueDateReminders() async {
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));
    final oneDayLater = now.add(const Duration(days: 1));

    final usersSnapshot = await _firestore.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      final borrowHistorySnapshot = await _firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('borrow_history')
          .where('status', isEqualTo: 'borrowed')
          .get();

      for (var borrowDoc in borrowHistorySnapshot.docs) {
        final data = borrowDoc.data();
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final bookTitle = data['bookTitle'] ?? data['title'] ?? 'Unknown Book';

        final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
        final nowOnly = DateTime(now.year, now.month, now.day);
        final daysUntilDue = dueDateOnly.difference(nowOnly).inDays;

        final lastNotificationField = 'lastReminderSent_${borrowDoc.id}';
        final userDocData = userDoc.data() as Map<String, dynamic>?;
        final lastNotificationDate = userDocData?[lastNotificationField] as Timestamp?;

        final shouldSendNotification = lastNotificationDate == null ||
            DateTime.now().difference(lastNotificationDate.toDate()).inDays >= 1;

        if (shouldSendNotification) {
          if (daysUntilDue == 3 || daysUntilDue == 1 || daysUntilDue == 0) {
            await sendDueDateReminderNotification(
              userId: userDoc.id,
              bookTitle: bookTitle,
              dueDate: dueDate,
            );

            await _firestore.collection('users').doc(userDoc.id).set({
              lastNotificationField: FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }
    }
  }

  Future<void> checkAndSendOverdueNotifications() async {
    final now = DateTime.now();

    final usersSnapshot = await _firestore.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      final borrowHistorySnapshot = await _firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('borrow_history')
          .where('status', isEqualTo: 'borrowed')
          .get();

      for (var borrowDoc in borrowHistorySnapshot.docs) {
        final data = borrowDoc.data();
        final dueDate = (data['dueDate'] as Timestamp).toDate();
        final bookTitle = data['bookTitle'] ?? data['title'] ?? 'Unknown Book';

        if (now.isAfter(dueDate)) {
          final lastOverdueField = 'lastOverdueNotification_${borrowDoc.id}';
          final userDocData = userDoc.data() as Map<String, dynamic>?;
          final lastOverdueDate = userDocData?[lastOverdueField] as Timestamp?;

          final shouldSendOverdue = lastOverdueDate == null ||
              DateTime.now().difference(lastOverdueDate.toDate()).inDays >= 1;

          if (shouldSendOverdue) {
            await sendOverdueNotification(
              userId: userDoc.id,
              bookTitle: bookTitle,
              dueDate: dueDate,
            );

            await _firestore.collection('users').doc(userDoc.id).set({
              lastOverdueField: FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
      }
    }
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> deleteAllNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
