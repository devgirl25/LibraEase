import 'package:cloud_firestore/cloud_firestore.dart';

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

    // 1️⃣ Create borrow request
    await _firestore.collection('borrow_requests').add({
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userId': userId,
      'borrowDate': Timestamp.fromDate(now),
      'dueDate': Timestamp.fromDate(dueDate),
      'status': 'borrowed',
    });

    // 2️⃣ Update book status
    await _firestore.collection('books').doc(bookId).update({
      'status': 'borrowed',
      'borrowedBy': userId,
      'borrowDate': Timestamp.fromDate(now),
      'dueDate': Timestamp.fromDate(dueDate),
    });
  }

  /// Return a book
  Future<void> returnBook({
    required String bookId,
    required String borrowRequestId,
  }) async {
    // Update borrow request
    await _firestore.collection('borrow_requests').doc(borrowRequestId).update({
      'status': 'returned',
    });

    // Update book document
    await _firestore.collection('books').doc(bookId).update({
      'status': 'available',
      'borrowedBy': null,
      'borrowDate': null,
      'dueDate': null,
    });
  }
}

