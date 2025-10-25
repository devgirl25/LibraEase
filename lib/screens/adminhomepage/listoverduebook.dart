import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/firestore_helpers.dart';

class OverdueBooksPage extends StatelessWidget {
  const OverdueBooksPage({super.key});

  /// Fetch user name by UID field in users collection
  Future<String> _getUserName(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: userId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data()['name'] ?? userId;
    }

    return userId; // fallback if not found
  }

  /// Fetch book image URL by book ID
  Future<String?> _getBookImage(String bookId) async {
    if (bookId.isEmpty) return null;

    final doc =
        await FirebaseFirestore.instance.collection('books').doc(bookId).get();
    if (doc.exists) {
      return doc.data()?['imageUrl'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overdue Books'),
        backgroundColor: const Color.fromARGB(255, 87, 36, 14),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('borrow_requests')
            .where('status', isEqualTo: 'borrowed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No borrowed books found'));
          }

          // Filter overdue requests
          final overdueDocs = snapshot.data!.docs.where((doc) {
            final dueDate = toDateTime(doc['dueDate']);
            return dueDate != null && dueDate.isBefore(DateTime.now());
          }).toList();

          if (overdueDocs.isEmpty) {
            return const Center(child: Text('No overdue books'));
          }

          return ListView.builder(
            itemCount: overdueDocs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = overdueDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final dueDate = toDateTime(data['dueDate']);
              final borrowDate = toDateTime(data['borrowDate']);
              final userId = data['userId'] as String?;
              final bookId = data['bookId'] as String?;
              final bookTitle = data['bookTitle'] ?? 'Unknown Book';

              if (dueDate == null || borrowDate == null || userId == null) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  _getUserName(userId),
                  if (bookId != null)
                    _getBookImage(bookId)
                  else
                    Future.value(null)
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final studentName = snapshot.data?[0] ?? userId;
                  final bookImage = snapshot.data?[1] as String?;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (bookImage != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    bookImage,
                                    width: 60,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.book,
                                  size: 60,
                                  color: Color.fromARGB(255, 87, 36, 14),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  bookTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Borrowed by: $studentName'),
                          const SizedBox(height: 4),
                          Text(
                              'Borrowed: ${DateFormat.yMMMd().format(borrowDate)}'),
                          const SizedBox(height: 4),
                          Text(
                            'Due: ${DateFormat.yMMMd().format(dueDate)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reminder sent to student'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.notifications),
                                label: const Text('Send Reminder'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('borrow_requests')
                                      .doc(doc.id)
                                      .update({'status': 'returned'});

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Book marked as returned'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Mark Returned'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
