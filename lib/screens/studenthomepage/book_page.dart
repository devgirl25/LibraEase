import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/borrow_service.dart';
import 'home_page.dart';

class BookPage extends StatefulWidget {
  final String bookId;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String category;

  final bool available;

  const BookPage({
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

class _BookPageState extends State<BookPage> {
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
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final bookData = snapshot.data!;
          final available = bookData['available'] ?? false;

          return Scaffold(
            appBar: AppBar(title: Text(widget.title), backgroundColor: kPrimaryBrown),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Image.network(widget.imageUrl, height: 200),
                  const SizedBox(height: 16),
                  Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('by ${widget.author}'),
                  const SizedBox(height: 16),
                  Text(widget.description),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: available && !_isLoading
                        ? () {
                            _isBorrowed ? _renewBook() : _borrowBook();
                          }
                        : null,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isBorrowed ? 'Renew Book' : 'Borrow Book'),
                  ),
                  if (_isBorrowed && _dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                            color: _dueDate!.isBefore(DateTime.now())
                                ? Colors.red
                                : Colors.black),
                      ),
                    ),
                ],
              ),
            ),
          );
        });
  }
}
