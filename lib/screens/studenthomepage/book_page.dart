import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'wishlist_page.dart'; // Make sure the path is correct

const Color kPrimaryBrown = Color.fromARGB(255, 87, 36, 14);
const Color kLightCream = Color.fromARGB(255, 245, 235, 220);

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
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isInWishlist = false;
  bool isBorrowing = false;

  @override
  void initState() {
    super.initState();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(widget.bookId)
        .get();

    setState(() {
      isInWishlist = doc.exists;
    });
  }

  Future<void> _toggleWishlist() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to use wishlist')),
      );
      return;
    }

    final wishlistRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(widget.bookId);

    if (isInWishlist) {
      await wishlistRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from Wishlist')),
      );
    } else {
      await wishlistRef.set({
        'bookId': widget.bookId,
        'title': widget.title,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Wishlist')),
      );
    }

    setState(() => isInWishlist = !isInWishlist);
  }

  Future<void> _sendBorrowRequest() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to borrow a book')),
      );
      return;
    }

    if (!widget.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This book is not available right now')),
      );
      return;
    }

    setState(() => isBorrowing = true);

    try {
      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: 14));

      await _firestore.collection('borrow_requests').add({
        'bookId': widget.bookId,
        'bookTitle': widget.title,
        'userId': user.uid,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'dueDate': dueDate.toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Borrow request sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e')),
      );
    } finally {
      setState(() => isBorrowing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightCream,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: kPrimaryBrown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.imageUrl,
                            height: 250,
                            width: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.book,
                                size: 150, color: kPrimaryBrown),
                          )
                        : const Icon(
                            Icons.book,
                            size: 150,
                            color: kPrimaryBrown,
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Heart icon
                  GestureDetector(
                    onTap: _toggleWishlist,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        isInWishlist ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(isInWishlist),
                        color: isInWishlist ? Colors.red : Colors.grey[700],
                        size: 40,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
              style: const TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.brown),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.category, color: kPrimaryBrown),
                const SizedBox(width: 8),
                Text(widget.category, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info, color: kPrimaryBrown),
                const SizedBox(width: 8),
                Text(
                  widget.available ? 'Available' : 'Not Available',
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.available ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1.5),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 30),

            // Borrow button
            Center(
              child: ElevatedButton.icon(
                onPressed: isBorrowing ? null : _sendBorrowRequest,
                icon: const Icon(Icons.bookmark_add, color: Colors.white),
                label: Text(
                  isBorrowing ? 'Requesting...' : 'Borrow This Book',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBrown,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
