import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowRequestsPage extends StatelessWidget {
  const BorrowRequestsPage({super.key});

  // Return a book
  Future<void> markAsReturned(String borrowRequestId, String bookId) async {
    final firestore = FirebaseFirestore.instance;

    // Update borrow_requests
    await firestore.collection('borrow_requests').doc(borrowRequestId).update({
      'status': 'returned',
    });

    // Update book document
    await firestore.collection('books').doc(bookId).update({
      'status': 'available',
      'borrowedBy': null,
      'borrowDate': null,
      'dueDate': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Requests'),
        backgroundColor: const Color(0xFF255A5A),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('borrow_requests')
            .where('status', isEqualTo: 'borrowed')
            .orderBy('borrowDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No active borrow requests.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final borrowRequestId = docs[index].id;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['bookTitle'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student: ${data['userId']}'),
                      Text(
                          'Borrowed: ${data['borrowDate'] != null ? (data['borrowDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'N/A'}'),
                      Text(
                          'Due: ${data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'N/A'}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await markAsReturned(borrowRequestId, data['bookId']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Book marked as returned')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Return'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
