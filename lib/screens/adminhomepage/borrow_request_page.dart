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

  DateTime _timestampToDate(dynamic ts) {
    if (ts == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (ts is Timestamp) return ts.toDate();
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    try {
      return DateTime.parse(ts.toString());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool admin = isAdmin(user?.uid);

    final borrowStream = admin
        ? FirebaseFirestore.instance
            .collection('borrow_requests')
            .orderBy('requestedAt', descending: true)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('borrow_requests')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('requestedAt', descending: true)
            .snapshots();

    final renewStream = admin
        ? FirebaseFirestore.instance
            .collection('renew_requests')
            .orderBy('requestedAt', descending: true)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('renew_requests')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('requestedAt', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Borrow & Renew Requests",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        foregroundColor: Colors.white,
        backgroundColor: kPrimaryBrown,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: borrowStream,
        builder: (context, borrowSnapshot) {
          if (borrowSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (borrowSnapshot.hasError) {
            return Center(child: Text('Error: ${borrowSnapshot.error}'));
          }

          // Now listen to renew requests stream
          return StreamBuilder<QuerySnapshot>(
            stream: renewStream,
            builder: (context, renewSnapshot) {
              if (renewSnapshot.connectionState == ConnectionState.waiting) {
                // show loader only if both are waiting
                if (borrowSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
              }

              if (renewSnapshot.hasError) {
                return Center(child: Text('Error: ${renewSnapshot.error}'));
              }

              final borrowDocs = borrowSnapshot.data?.docs ?? [];
              final renewDocs = renewSnapshot.data?.docs ?? [];

              // Combine both lists with a small wrapper to know their type
              final List<Map<String, dynamic>> allEntries = [
                ...borrowDocs.map((d) => {'type': 'borrow', 'doc': d}),
                ...renewDocs.map((d) => {'type': 'renew', 'doc': d}),
              ];

              // Sort by requestedAt descending (most recent first)
              allEntries.sort((a, b) {
                final aDoc = a['doc'] as DocumentSnapshot;
                final bDoc = b['doc'] as DocumentSnapshot;
                final aTime = _timestampToDate(
                    (aDoc.data() as Map<String, dynamic>?)?['requestedAt']);
                final bTime = _timestampToDate(
                    (bDoc.data() as Map<String, dynamic>?)?['requestedAt']);
                return bTime.compareTo(aTime);
              });

              if (allEntries.isEmpty) {
                return const Center(
                  child: Text("No requests found."),
                );
              }

              return ListView.builder(
                itemCount: allEntries.length,
                itemBuilder: (context, index) {
                  final entry = allEntries[index];
                  final doc = entry['doc'] as DocumentSnapshot;
                  final data = (doc.data() as Map<String, dynamic>?) ?? {};
                  final requestId = doc.id;
                  final type = entry['type'] as String;
                  final status = data['status'] ?? 'pending';
                  final userId = data['userId'] ?? '';
                  final bookId = data['bookId'] ?? '';

                  final isRequestAdmin = admin;

                  return FutureBuilder<List<dynamic>>(
                    future: Future.wait(
                        [_getUserName(userId), _getBookImage(bookId)]),
                    builder: (context, metaSnapshot) {
                      final userName = metaSnapshot.data?[0] ?? userId;
                      final bookImage = metaSnapshot.data?[1];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                            "Requested by: $userName\n"
                            "Type: ${type == 'renew' ? 'Renew Request' : 'Borrow Request'}\n"
                            "Status: $status",
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
                                          // optional: you can pass type if ManageRequestPage needs it
                                          // requestType: type,
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
          );
        },
      ),
    );
  }
}
