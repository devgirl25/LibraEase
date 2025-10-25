import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';
import 'managerequest.dart';

class BorrowRequestsPage extends StatelessWidget {
  const BorrowRequestsPage({super.key});

  bool isAdmin(String? uid) {
    return uid == "ZZZA4GmfBlV6ZlYuL4Y84vVuui42"; // admin UID
  }

  Future<String> _getUserName(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data()?['name'] ?? userId;
    }
    return userId;
  }

  Future<String?> _getBookImage(String bookId) async {
    final doc =
        await FirebaseFirestore.instance.collection('books').doc(bookId).get();
    if (doc.exists) {
      return doc.data()?['imageUrl'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final borrowStream = isAdmin(user?.uid)
        ? FirebaseFirestore.instance
            .collection('borrow_requests')
            .orderBy('requestedAt', descending: true)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('borrow_requests')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('requestedAt', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Borrow Requests",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        foregroundColor: Colors.white,
        backgroundColor: kPrimaryBrown,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: borrowStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No borrow requests",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final requestId = docs[index].id;
              final status = data['status'] ?? 'pending';
              final isRequestAdmin = isAdmin(user?.uid);
              final userId = data['userId'] ?? '';
              final bookId = data['bookId'] ?? '';

              return FutureBuilder<List<dynamic>>(
                future:
                    Future.wait([_getUserName(userId), _getBookImage(bookId)]),
                builder: (context, snapshot) {
                  final userName = snapshot.data?[0] ?? userId;
                  final bookImage = snapshot.data?[1];

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: bookImage != null
                            ? Image.network(
                                bookImage,
                                width: 60,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.book,
                                size: 60, color: kPrimaryBrown),
                      ),
                      title: Text(
                        data['bookTitle'] ?? 'Unknown Book',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Requested by: $userName\nStatus: $status",
                        style: TextStyle(
                          fontSize: 14,
                          color: status == "accepted"
                              ? Colors.green
                              : status == "rejected"
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                      ),
                      trailing: isRequestAdmin
                          ? TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ManageRequestPage(
                                      requestId: requestId,
                                      requestData: data,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                "Manage",
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryBrown),
                              ),
                            )
                          : null,
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
