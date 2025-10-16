import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/borrow_service.dart';
import '../logins/constants.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String category;

  final bool available;

  const BookDetailPage({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.available,
  });

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final BorrowService _borrowService = BorrowService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isBorrowed = false;
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBorrowStatus();
  }

  Future<void> _checkBorrowStatus() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('borrow_history')
        .where('bookId', isEqualTo: widget.bookId)
        .where('status', isEqualTo: 'borrowed')
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _isBorrowed = true;
        _dueDate = (snapshot.docs.first['dueDate'] as Timestamp).toDate();
      });
    }
  }

  Future<void> _borrowBook() async {
    setState(() => _isLoading = true);
    await _borrowService.borrowBook(
        bookId: widget.bookId,
        bookTitle: widget.title,
        userId: _userId,
        borrowDays: 14);
    setState(() {
      _isBorrowed = true;
      _dueDate = DateTime.now().add(const Duration(days: 14));
      _isLoading = false;
    });
  }

  Future<void> _renewBook() async {
    if (_dueDate == null) return;
    setState(() => _isLoading = true);
    await _borrowService.renewBook(
        userId: _userId,
        bookId: widget.bookId,
        bookTitle: widget.title,
        extendDays: 14);
    setState(() {
      _dueDate = _dueDate!.add(const Duration(days: 14));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance.collection('books').doc(widget.bookId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: kScaffoldBackground,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final bookData = snapshot.data!;
          final available = bookData['available'] ?? false;

          return Scaffold(
            backgroundColor: kScaffoldBackground,
            appBar: AppBar(
              title: Text(widget.title, style: const TextStyle(color: Colors.white)),
              backgroundColor: kPrimaryBrown,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: widget.imageUrl.isNotEmpty
                            ? (widget.imageUrl.startsWith('http')
                                ? Image.network(
                                    widget.imageUrl,
                                    height: 250,
                                    width: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 250,
                                      width: 180,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.book, size: 60),
                                    ),
                                  )
                                : Image.asset(
                                    widget.imageUrl,
                                    height: 250,
                                    width: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 250,
                                      width: 180,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.book, size: 60),
                                    ),
                                  ))
                            : Container(
                                height: 250,
                                width: 180,
                                color: Colors.grey[300],
                                child: const Icon(Icons.book, size: 60),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'by ${widget.author}',
                      style: TextStyle(
                        fontSize: 16,
                        color: kPrimaryBrown.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kPrimaryBrown.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.category,
                            style: const TextStyle(
                              color: kPrimaryBrown,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: available
                                ? Colors.green[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            available ? 'Available' : 'Not Available',
                            style: TextStyle(
                              color: available
                                  ? Colors.green[800]
                                  : Colors.red[800],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description.isNotEmpty
                          ? widget.description
                          : 'No description available.',
                      style: TextStyle(
                        fontSize: 15,
                        color: kPrimaryBrown.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_isBorrowed && _dueDate != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _dueDate!.isBefore(DateTime.now())
                              ? Colors.red[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _dueDate!.isBefore(DateTime.now())
                                ? Colors.red[300]!
                                : Colors.green[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _dueDate!.isBefore(DateTime.now())
                                  ? Icons.warning_rounded
                                  : Icons.check_circle_rounded,
                              color: _dueDate!.isBefore(DateTime.now())
                                  ? Colors.red[700]
                                  : Colors.green[700],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _dueDate!.isBefore(DateTime.now())
                                        ? 'Overdue!'
                                        : 'Currently Borrowed',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _dueDate!.isBefore(DateTime.now())
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _dueDate!.isBefore(DateTime.now())
                                          ? Colors.red[600]
                                          : Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: available && !_isLoading
                            ? () {
                                _isBorrowed ? _renewBook() : _borrowBook();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isBorrowed ? 'Renew Book' : 'Borrow Book',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
