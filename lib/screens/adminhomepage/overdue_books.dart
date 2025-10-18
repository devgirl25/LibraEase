import 'package:flutter/material.dart';
import '../../utils/firestore_helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OverdueBooksPage extends StatelessWidget {
  const OverdueBooksPage({super.key});

  DateTime get today => DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Overdue Books"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('borrow_requests')
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No overdue books"));
          }

          final docs = snapshot.data!.docs;

          // Filter overdue books and remove entries without a valid due date
          final overdueBooks = docs.where((doc) {
            final raw = (doc.data() as Map<String, dynamic>)['dueDate'];
            final due = toDateTime(raw);
            if (due == null) return false;
            final dueDateOnly = DateTime(due.year, due.month, due.day);
            final todayDate = DateTime(today.year, today.month, today.day);
            return dueDateOnly.isBefore(todayDate);
          }).toList();

          if (overdueBooks.isEmpty) {
            return const Center(child: Text("No overdue books"));
          }

          return ListView.builder(
            itemCount: overdueBooks.length,
            itemBuilder: (context, index) {
              final data = overdueBooks[index].data() as Map<String, dynamic>;
              final dueDate = toDateTime(data['dueDate'])!;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(data['bookTitle'] ?? 'Unknown Book'),
                  subtitle: Text(
                    "Borrowed by: ${data['userId'] ?? 'Unknown'}\nDue Date: ${dueDate.day}/${dueDate.month}/${dueDate.year}",
                    style: const TextStyle(height: 1.4),
                  ),
                  trailing: Text(
                    "${DateTime.now().difference(dueDate).inDays} days overdue",
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
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
