import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';
import 'managerequest.dart';

class BorrowRequestsPage extends StatelessWidget {
  const BorrowRequestsPage({super.key});

  bool isAdmin(String? uid) {
    return uid == "ZZZA4GmfBlV6ZlYuL4Y84vVuui42";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Borrow Requests"),
        foregroundColor: Colors.white,
        backgroundColor: kPrimaryBrown,
        actions: [
          if (isAdmin(user?.uid))
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('borrow_requests')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                int pendingCount = 0;
                if (snapshot.hasData) pendingCount = snapshot.data!.docs.length;

                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.notifications),
                        if (pendingCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$pendingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('borrow_requests')
            .orderBy('requestedAt', descending: true)
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
                  trailing: isRequestAdmin
                      ? TextButton(
                          child: const Text("Manage"),
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
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
