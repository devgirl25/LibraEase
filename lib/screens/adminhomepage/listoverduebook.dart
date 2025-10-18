import 'package:flutter/material.dart';
import '../../utils/firestore_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OverdueBooksPage extends StatelessWidget {
  const OverdueBooksPage({super.key});

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

          // Filter overdue books
          final overdueDocs = snapshot.data!.docs.where((doc) {
            final dueDate = toDateTime(doc['dueDate']);
            if (dueDate == null) return false;
            return dueDate.isBefore(DateTime.now());
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
              if (dueDate == null || borrowDate == null) {
                // missing dates - skip rendering this entry
                return const SizedBox.shrink();
              }
              final studentName = data['studentName'] ?? 'Unknown';
              final bookTitle = data['bookTitle'] ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookTitle,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Student: $studentName'),
                      const SizedBox(height: 4),
                      Text(
                          'Borrowed: ${DateFormat.yMMMd().format(borrowDate)}'),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${DateFormat.yMMMd().format(dueDate)}',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Send reminder notification to student
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Reminder sent to student')),
                              );
                            },
                            icon: const Icon(Icons.notifications),
                            label: const Text('Send Reminder'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Mark as returned
                              await FirebaseFirestore.instance
                                  .collection('borrow_requests')
                                  .doc(doc.id)
                                  .update({'status': 'returned'});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Book marked as returned')),
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Mark Returned'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                          ),
                        ],
                      )
                    ],
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
