import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';

// --- Enum for borrow status ---
enum BorrowStatus { borrowed, returned }

class BorrowRecord {
  final String id;
  final String bookId;
  final String title;
  final String author;
  final String imageUrl;
  final String category;
  final BorrowStatus status;
  final DateTime? dueDate;

  BorrowRecord({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.category,
    required this.status,
    this.dueDate,
  });

  factory BorrowRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BorrowRecord(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      title: data['bookTitle'] ?? data['title'] ?? 'Untitled',
      author: data['author'] ?? 'Unknown Author',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'General',
      status: (data['status'] == 'returned')
          ? BorrowStatus.returned
          : BorrowStatus.borrowed,
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
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
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
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('borrow_requests')
            .where('userId', isEqualTo: user!.uid)
            .where('status', whereIn: ['accepted', 'returned'])
            .orderBy('borrowDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryBrown));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading borrow history.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No borrow history found.'));
          }

          final records = snapshot.data!.docs
              .map((doc) => BorrowRecord.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(records[index]);
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: Container(
        decoration: const BoxDecoration(
          color: kPrimaryBrown,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Center(
            child: ListTile(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Borrow History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BorrowRecord record) {
    final isReturned = record.status == BorrowStatus.returned;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE3DC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookImage(record.imageUrl),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kPrimaryBrown,
                      ),
                    ),
                    Text(
                      record.author,
                      style: TextStyle(
                        fontSize: 13,
                        color: kPrimaryBrown.withOpacity(0.7),
                      ),
                    ),
                    _buildStatusChip(isReturned, record.dueDate),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (isReturned) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please borrow this book again from the Browse page.'),
                                ),
                              );
                            } else {
                              final newDueDate =
                                  DateTime.now().add(const Duration(days: 14));
                              await _firestore
                                  .collection('borrow_requests')
                                  .doc(record.id)
                                  .update({
                                'dueDate': Timestamp.fromDate(newDueDate)
                              });

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Book renewed successfully!'),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            minimumSize: const Size(0, 32),
                          ),
                          child: Text(isReturned ? 'Borrow Again' : 'Renew',
                              style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Review feature coming soon!')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimaryBrown,
                            side: BorderSide(
                                color: kPrimaryBrown.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text('Review',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 80,
        height: 110,
        color: Colors.grey[300],
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.book, color: Colors.grey),
              )
            : const Icon(Icons.book, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusChip(bool isReturned, DateTime? dueDate) {
    if (isReturned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD7CCC8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Returned',
          style: TextStyle(
            fontSize: 11,
            color: kPrimaryBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      final formattedDate =
          dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate) : 'N/A';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Due Date: $formattedDate',
          style: TextStyle(
            fontSize: 11,
            color: Colors.green.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
