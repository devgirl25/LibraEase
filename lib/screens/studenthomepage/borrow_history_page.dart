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
              child: CircularProgressIndicator(color: kPrimaryBrown),
            );
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
            Text(
              record.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kPrimaryBrown,
              ),
            ),
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

            // Renew button (only for accepted/pending books)
            if (!isReturned)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _sendRenewRequest(record),
                  icon:
                      const Icon(Icons.refresh, color: Colors.white, size: 18),
                  label: const Text("Renew Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRenewRequest(BorrowRecord record) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Prevent duplicate pending renew requests
      final existing = await _firestore
          .collection('renew_requests')
          .where('userId', isEqualTo: currentUser.uid)
          .where('bookId', isEqualTo: record.bookId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Renewal already requested."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final renewRef = _firestore.collection('renew_requests').doc();

      await renewRef.set({
        'renewId': renewRef.id,
        'bookId': record.bookId,
        'bookTitle': record.title,
        'userId': currentUser.uid,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // admin will later approve or reject
        'originalBorrowId': record.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Renewal request sent to admin."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send renew request: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
