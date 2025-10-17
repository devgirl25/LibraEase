import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_manager.dart';

class BorrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationManager _notificationManager = NotificationManager();

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

    // 3. Send notification
    await _notificationManager.sendBorrowSuccessNotification(
      userId: userId,
      bookTitle: bookTitle,
      borrowDate: now,
      dueDate: dueDate,
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
      await _notificationManager.sendBookRenewedNotification(
        userId: userId,
        bookTitle: bookTitle,
        oldDueDate: oldDueDate,
        newDueDate: newDueDate,
      );
    }
  }

  /// Overdue notification (to be called by a scheduled job or Cloud Function)
  Future<void> sendOverdueNotification({
    required String userId,
    required String bookTitle,
    required DateTime dueDate,
  }) async {
    await _notificationManager.sendOverdueNotification(
      userId: userId,
      bookTitle: bookTitle,
      dueDate: dueDate,
    );
  }

  /// Return a book
  Future<void> returnBook({
    required String userId,
    required String bookId,
    required String bookTitle,
  }) async {
    // 1. Update borrow_history
    final historyRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('borrow_history')
        .where('bookId', isEqualTo: bookId)
        .where('status', isEqualTo: 'borrowed');

    final snapshot = await historyRef.get();
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      await doc.reference.update({
        'status': 'returned',
        'returnDate': DateTime.now(),
      });

      // 2. Update book availability
      await _firestore.collection('books').doc(bookId).update({
        'available': true,
      });

      // 3. Send notification
      await _notificationManager.sendBookReturnedNotification(
        userId: userId,
        bookTitle: bookTitle,
        returnDate: DateTime.now(),
      );
    }
  }
}
