import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';
import 'book_list_page.dart';

// Enum for book status
enum BorrowStatus { borrowed, returned }

class BorrowRecord {
  final String id;
  final Book book;
  final BorrowStatus status;
  final DateTime? dueDate;

  BorrowRecord({
    required this.id,
    required this.book,
    required this.status,
    this.dueDate,
  });

  factory BorrowRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BorrowRecord(
      id: doc.id,
      book: Book(
        title: data['title'] ?? '',
        author: data['author'] ?? '',
        imagePath: data['imagePath'] ?? 'assets/images/book_placeholder.png',
        tag: data['tag'] ?? '',
      ),
      status: data['status'] == 'returned'
          ? BorrowStatus.returned
          : BorrowStatus.borrowed,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': book.title,
      'author': book.author,
      'imagePath': book.imagePath,
      'tag': book.tag,
      'status': status == BorrowStatus.returned ? 'returned' : 'borrowed',
      'dueDate': dueDate,
    };
  }
}

class BorrowHistoryPage extends StatefulWidget {
  const BorrowHistoryPage({super.key});

  @override
  State<BorrowHistoryPage> createState() => _BorrowHistoryPageState();
}

class _BorrowHistoryPageState extends State<BorrowHistoryPage> {
  late final User? user;
  late final CollectionReference borrowHistoryRef;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user is logged in, show an error or redirect
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to view your history")),
        );
        Navigator.of(context).pop();
      });
      return;
    }

    borrowHistoryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('borrow_history');

    _addSampleDataIfEmpty();
  }

  Future<void> _addSampleDataIfEmpty() async {
    final snapshot = await borrowHistoryRef.get();
    if (snapshot.docs.isEmpty) {
      final List<BorrowRecord> sampleRecords = [
        BorrowRecord(
          id: '1',
          book: Book(
              title: 'Software Engineering',
              author: "By Brian D'Andrade",
              imagePath: 'assets/images/book1.png',
              tag: 'Computer'),
          status: BorrowStatus.borrowed,
          dueDate: DateTime(2025, 12, 25),
        ),
        BorrowRecord(
          id: '2',
          book: Book(
              title: 'A Textbook of Engineering Drawing',
              author: "By Brian D'Andrade",
              imagePath: 'assets/images/book2.png',
              tag: 'Computer'),
          status: BorrowStatus.borrowed,
          dueDate: DateTime(2025, 12, 25),
        ),
        BorrowRecord(
          id: '3',
          book: Book(
              title: 'A Textbook of Engineering Physics',
              author: "By Brian D'Andrade",
              imagePath: 'assets/images/book3.png',
              tag: 'Physics'),
          status: BorrowStatus.returned,
        ),
      ];

      for (var record in sampleRecords) {
        await borrowHistoryRef.add(record.toFirestore());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: borrowHistoryRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              return _buildHistoryItemCard(records[index]);
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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

  Widget _buildHistoryItemCard(BorrowRecord record) {
    final bool isReturned = record.status == BorrowStatus.returned;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE3DC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                record.book.imagePath,
                width: 80,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 110,
                  color: Colors.grey[300],
                  child: const Icon(Icons.book, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      record.book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kPrimaryBrown,
                      ),
                    ),
                    Text(
                      record.book.author,
                      style: TextStyle(
                        fontSize: 12,
                        color: kPrimaryBrown.withOpacity(0.7),
                      ),
                    ),
                    _buildStatusChip(isReturned, record.dueDate),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (isReturned) {
                              await borrowHistoryRef.add(record.toFirestore());
                            } else if (record.id.isNotEmpty) {
                              await borrowHistoryRef.doc(record.id).update({
                                'dueDate':
                                    DateTime.now().add(const Duration(days: 7))
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(0, 30),
                          ),
                          child: Text(isReturned ? 'Borrow Again' : 'Renew',
                              style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimaryBrown,
                            side: BorderSide(
                                color: kPrimaryBrown.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Text('Review',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isReturned, DateTime? dueDate) {
    if (isReturned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFD7CCC8),
            borderRadius: BorderRadius.circular(8)),
        child: const Text('Returned',
            style: TextStyle(
                fontSize: 11,
                color: kPrimaryBrown,
                fontWeight: FontWeight.bold)),
      );
    } else {
      final String formattedDate =
          dueDate != null ? DateFormat('dd MMM yyyy').format(dueDate) : 'N/A';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8)),
        child: Text('Due Date: $formattedDate',
            style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold)),
      );
    }
  }
}
