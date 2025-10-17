import 'package:cloud_firestore/cloud_firestore.dart';
import 'notificationservice.dart';

class BorrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Borrow a book
  Future<void> borrowBook({
    required String bookId,
    required String bookTitle,
    required String userId,
    int borrowDays = 14, // default 2 weeks
  }) async {
    final now = DateTime.now();
    final dueDate = now.add(Duration(days: borrowDays));

    // 1. Add to borrow requests
    final borrowRequestRef =
        _firestore.collection('borrow_requests').doc(); // auto ID
    await borrowRequestRef.set({
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userId': userId,
      'borrowDate': now,
      'dueDate': dueDate,
      'status': 'pending',
    });

    // 2. Add to borrow history
    final borrowHistoryRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('borrow_history')
        .doc();
    await borrowHistoryRef.set({
      'bookId': bookId,
      'bookTitle': bookTitle,
      'borrowDate': now,
      'dueDate': dueDate,
      'status': 'borrowed',
    });

    // 3. Send notification (request submitted - pending approval)
    await _notificationService.sendNotification(
      userId: userId,
      title: 'Borrow Request Submitted',
      message:
          'Your request to borrow "$bookTitle" has been submitted and is pending approval.',
      type: NotificationType.general,
    );
  }

  /// Renew a book
  Future<void> renewBook({
    required String userId,
    required String bookId,
    required String bookTitle,
    int extendDays = 14,
  }) async {
    // 1. Update borrow_history
    final historyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('borrow_history')
        .where('bookId', isEqualTo: bookId);

    final snapshot = await historyRef.get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final oldDueDate = (doc['dueDate'] as Timestamp).toDate();
      final newDueDate = oldDueDate.add(Duration(days: extendDays));

      await doc.reference.update({'dueDate': newDueDate});

      // 2. Send notification
      await _notificationService.sendBookRenewedNotification(
        userId: userId,
        bookTitle: bookTitle,
        newDueDate: newDueDate,
      );

      // Reset reminder sent flag for the new due date
      await doc.reference.update({'reminderSent': false});
    }
  }

  /// Return a book
  Future<void> returnBook({
    required String userId,
    required String bookId,
    required String bookTitle,
  }) async {
    // Update borrow_requests status to 'returned'
    final requestSnapshot = await _firestore
        .collection('borrow_requests')
        .where('userId', isEqualTo: userId)
        .where('bookId', isEqualTo: bookId)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (requestSnapshot.docs.isNotEmpty) {
      for (var doc in requestSnapshot.docs) {
        await doc.reference.update({'status': 'returned'});
      }

      // Send return confirmation notification
      await _notificationService.sendBookReturnedNotification(
        userId: userId,
        bookTitle: bookTitle,
      );
    }
  }
}
