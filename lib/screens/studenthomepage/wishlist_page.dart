import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_page.dart';

const Color kPrimaryBrown = Color.fromARGB(255, 87, 36, 14);
const Color kScaffoldBackground = Color(0xFFF5F5F5);

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
            return const Center(child: Text("Your wishlist is empty."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final bookId = data['bookId'] as String;
              final title = data['title'] as String? ?? 'Untitled';

              return WishlistItem(
                bookId: bookId,
                title: title,
                userId: user.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class WishlistItem extends StatelessWidget {
  final String bookId;
  final String title;
  final String userId;

  const WishlistItem({
    super.key,
    required this.bookId,
    required this.title,
    required this.userId,
  });

  Future<void> _removeFromWishlist() async {
    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wishlist')
        .doc(bookId);

    await wishlistRef.delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getBookData() async {
    return await FirebaseFirestore.instance.collection('books').doc(bookId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getBookData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE3DC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE3DC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kPrimaryBrown),
                    ),
                  ),
                  const Icon(Icons.error, color: Colors.red),
                ],
              ),
            );
          }

          final bookData = snapshot.data!.data()!;
          final author = bookData['author'] ?? '';
          final description = bookData['description'] ?? '';
          final imageUrl = bookData['imageUrl'] ?? '';
          final category = bookData['category'] ?? '';
          final noOfCopies = bookData['no_of_copies'] ?? 0;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailPage(
                    bookId: bookId,
                    title: title,
                    author: author,
                    description: description,
                    imageUrl: imageUrl,
                    category: category,
                    noOfCopies: noOfCopies,
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
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kPrimaryBrown),
                    ),
                  ),
                  GestureDetector(
                    onTap: _removeFromWishlist,
                    child: const Icon(Icons.favorite, color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
