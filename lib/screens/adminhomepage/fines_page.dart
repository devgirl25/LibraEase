import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinesPage extends StatefulWidget {
  const FinesPage({super.key});

  @override
  State<FinesPage> createState() => _FinesPageState();
}

class _FinesPageState extends State<FinesPage> {
  final usersRef = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fines Dashboard'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.brown,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = userSnapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(8),
            children: users.map((userDoc) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final userName = userData['name'] ?? 'Student';
              final email = userData['email'] ?? '';
              final studentId = userData['studentId'] ?? '';
              final uid = userDoc.id;

              return StreamBuilder<DocumentSnapshot>(
                stream: usersRef
                    .doc(uid)
                    .collection('stats')
                    .doc('latest')
                    .snapshots(),
                builder: (context, statsSnap) {
                  if (!statsSnap.hasData || !statsSnap.data!.exists) {
                    return const SizedBox();
                  }

                  final statsData =
                      statsSnap.data!.data() as Map<String, dynamic>;
                  final fineTotal = (statsData['fineTotal'] ?? 0.0).toDouble();
                  final overdue = statsData['overdue'] ?? 0;

                  if (fineTotal <= 0) return const SizedBox();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.brown[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Email: $email'),
                                Text('Student ID: $studentId'),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text('Overdue: $overdue'),
                                  backgroundColor: Colors.red[100],
                                ),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text('Total Fines: ₹$fineTotal'),
                                  backgroundColor: Colors.orange[100],
                                ),
                              ],
                            ),
                          ),

                          // Mark Paid button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                            ),
                            child: const Text(
                              'Mark Paid',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              await usersRef
                                  .doc(uid)
                                  .collection('stats')
                                  .doc('latest')
                                  .update({'fineTotal': 0.0, 'overdue': 0});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
