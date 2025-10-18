import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_helpers.dart';

class BorrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // store timestamps as Firestore Timestamps
      'borrowDate': Timestamp.fromDate(now),
      'dueDate': Timestamp.fromDate(dueDate),
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
      'borrowDate': Timestamp.fromDate(now),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': 'borrowed',
    });

    // 3. Notification removed — clients can poll borrow_requests / history
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
      final oldDueDate = toDateTime(doc['dueDate']);
      final newDueDate =
          (oldDueDate ?? DateTime.now()).add(Duration(days: extendDays));

      await doc.reference.update({'dueDate': Timestamp.fromDate(newDueDate)});

      // 2. Notification removed
    }
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
        'returnDate': Timestamp.fromDate(DateTime.now()),
      });

      // 2. Update book availability
      await _firestore.collection('books').doc(bookId).update({
        'available': true,
      });

      // 3. Notification removed
    }
  }
}
