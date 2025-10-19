import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';

enum BorrowStatus { pending, accepted, rejected, returned }

class BorrowRecord {
  final String id;
  final String bookId;
  final String title;
  final BorrowStatus status;
  final DateTime? dueDate;

  BorrowRecord({
    required this.id,
    required this.bookId,
    required this.title,
    required this.status,
    this.dueDate,
  });

  factory BorrowRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    BorrowStatus status;
    switch (data['status']) {
      case 'accepted':
        status = BorrowStatus.accepted;
        break;
      case 'rejected':
        status = BorrowStatus.rejected;
        break;
      case 'returned':
        status = BorrowStatus.returned;
        break;
      default:
        status = BorrowStatus.pending;
    }

    return BorrowRecord(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      title: data['bookTitle'] ?? 'Untitled',
      status: status,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
    );
  }
}

class BorrowHistoryPage extends StatefulWidget {
  const BorrowHistoryPage({super.key});

  @override
  State<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends State<BorrowHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your history.")),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text("Borrow History"),
        backgroundColor: kPrimaryBrown,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('borrow_requests')
            .where('userId', isEqualTo: user!.uid)
            .orderBy('requestedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryBrown));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No borrow history found.'));
          }

          final records = snapshot.data!.docs
              .map((doc) => BorrowRecord.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(records[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BorrowRecord record) {
    final isReturned = record.status == BorrowStatus.returned;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE3DC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryBrown)),
            const SizedBox(height: 6),
            Text(
              'Status: ${record.status.name}',
              style: TextStyle(
                fontSize: 14,
                color:
                    isReturned ? Colors.green : kPrimaryBrown.withOpacity(0.7),
              ),
            ),
            if (record.dueDate != null && !isReturned) ...[
              Text(
                'Due Date: ${DateFormat('dd MMM yyyy').format(record.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // 🧩 Calculate remaining days and show message
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final diff = record.dueDate!.difference(now).inDays;
                  String statusText;

                  if (diff >= 0) {
                    statusText = 'Due in $diff day${diff == 1 ? '' : 's'}';
                  } else {
                    statusText =
                        'Overdue by ${diff.abs()} day${diff == -1 ? '' : 's'}';
                  }

                  return Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: diff >= 0 ? Colors.orange : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
