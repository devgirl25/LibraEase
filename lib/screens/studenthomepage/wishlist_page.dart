import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logins/constants.dart';
import 'book_page.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: kScaffoldBackground,
        body: Center(child: Text("Please login to see your wishlist")),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryBrown,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_outline,
                        size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 24),
                    const Text(
                      "You haven't added any books to the wishlist yet",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBrown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Tap the bookmark icon on the book page to add here or click the button below to browse books.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: kPrimaryBrown.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to browse books page
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowseBooksPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBrown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      child: const Text(
                        "Browse Books",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return WishlistItem(
                bookId: data['bookId'],
                title: data['title'],
                author: data['author'],
                description: data['description'],
                imageUrl: data['imageUrl'],
                category: data['category'],
                available: data['available'] ?? true,
                userId: user.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class WishlistItem extends StatefulWidget {
  final String bookId;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String category;
  final bool available;
  final String userId;

  const WishlistItem({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.available,
    required this.userId,
  });

  @override
  State<WishlistItem> createState() => _WishlistItemState();
}

class _WishlistItemState extends State<WishlistItem> {
  bool isWishlisted = true;

  Future<void> _removeFromWishlist() async {
    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('wishlist')
        .doc(widget.bookId);

    await wishlistRef.delete();
    setState(() => isWishlisted = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Removed from Wishlist')));
  }

  @override
  Widget build(BuildContext context) {
    if (!isWishlisted) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookPage(
                bookId: widget.bookId,
                title: widget.title,
                author: widget.author,
                description: widget.description,
                imageUrl: widget.imageUrl,
                category: widget.category,
                available: widget.available,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAE3DC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 Placeholder for book image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80,
                  height: 110,
                  color: Colors.grey[300],
                  child: widget.imageUrl.isNotEmpty
                      ? (widget.imageUrl.startsWith('http')
                          ? Image.network(widget.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.book))
                          : Image.asset(widget.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.book)))
                      : const Icon(Icons.book, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kPrimaryBrown)),
                    const SizedBox(height: 4),
                    Text(
                        widget.author.isNotEmpty
                            ? widget.author
                            : 'Unknown author',
                        style: TextStyle(
                            fontSize: 12,
                            color: kPrimaryBrown.withOpacity(0.7))),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _removeFromWishlist,
                        child: const Icon(
                          Icons.bookmark,
                          color: kPrimaryBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
