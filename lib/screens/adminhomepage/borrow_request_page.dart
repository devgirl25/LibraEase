import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';

class BorrowRequestsPage extends StatelessWidget {
  const BorrowRequestsPage({super.key});

  bool isAdmin(String? uid) {
    // Replace with your admin UID check or Firestore admins collection
    return uid == "ZZZA4GmfBlV6ZlYuL4Y84vVuui42";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Borrow Requests"),
        backgroundColor: kPrimaryBrown,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('borrow_requests')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No borrow requests"));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final requestId = docs[index].id;
              final status = data['status'] ?? 'pending';
              final isRequestAdmin = isAdmin(user?.uid);

              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(data['bookTitle'] ?? 'Unknown Book'),
                  subtitle: Text(
                    "Requested by: ${data['userId']}\nStatus: $status",
                    style: TextStyle(
                        color: status == "accepted"
                            ? Colors.green
                            : status == "rejected"
                                ? Colors.red
                                : Colors.orange),
                  ),
                  trailing: isRequestAdmin && status == "pending"
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                // Accept request
                                await FirebaseFirestore.instance
                                    .collection('borrow_requests')
                                    .doc(requestId)
                                    .update({'status': 'accepted'});

                                // Update book availability
                                await FirebaseFirestore.instance
                                    .collection('books')
                                    .doc(data['bookId'])
                                    .update({'available': false});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                // Reject request
                                await FirebaseFirestore.instance
                                    .collection('borrow_requests')
                                    .doc(requestId)
                                    .update({'status': 'rejected'});
                              },
                            ),
                          ],
                        )
                      : null,
                  onTap: () {
                    // Optional: navigate to BookPage
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
