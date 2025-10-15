import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Borrow a book
  Future<void> borrowBook({
    required String bookId,
    required String bookTitle,
    required String userId,
    int borrowDays = 14,
  }) async {
    final now = DateTime.now();
    final dueDate = now.add(Duration(days: borrowDays));

    // 1️⃣ Create borrow request
    await _firestore.collection('borrow_requests').add({
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userId': userId,
      'borrowDate': Timestamp.fromDate(now),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': 'borrowed',
    });

    // 2️⃣ Update or create book record
    await _firestore.collection('books').doc(bookId).set({
      'status': 'borrowed',
      'borrowedBy': userId,
      'borrowDate': Timestamp.fromDate(now),
      'dueDate': Timestamp.fromDate(dueDate),
    }, SetOptions(merge: true));
  }

  /// Return a book
  Future<void> returnBook({
    required String bookId,
    required String borrowRequestId,
  }) async {
    await _firestore.collection('borrow_requests').doc(borrowRequestId).update({
      'status': 'returned',
      'returnDate': Timestamp.now(),
    });

    await _firestore.collection('books').doc(bookId).update({
      'status': 'available',
      'borrowedBy': null,
      'borrowDate': null,
      'dueDate': null,
    });
  }

  /// Mark overdue books
  Future<void> markOverdueBooks() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('borrow_requests')
        .where('status', isEqualTo: 'borrowed')
        .get();

    for (var doc in snapshot.docs) {
      final dueDate = (doc['dueDate'] as Timestamp).toDate();
      if (now.isAfter(dueDate)) {
        await doc.reference.update({'status': 'overdue'});

        final bookId = doc['bookId'];
        await _firestore.collection('books').doc(bookId).update({
          'status': 'overdue',
        });
      }
    }
  }
}
