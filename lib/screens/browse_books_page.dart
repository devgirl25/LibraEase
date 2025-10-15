import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'constants.dart';
import '../services/borrow_service.dart';

class BrowseBooksPage extends StatelessWidget {
  const BrowseBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .orderBy('addedAt', descending: true)
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
            return const Center(child: Text('No books found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return _BookListItem(
                bookId: doc.id,
                title: (data['title'] ?? '').toString(),
                author: (data['author'] ?? '').toString(),
                description: (data['description'] ?? '').toString(),
                imageUrl: (data['imageUrl'] ?? '').toString(),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70.0),
      child: Container(
        decoration: const BoxDecoration(
          color: kPrimaryBrown,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Text(
                'Browse Books',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookListItem extends StatelessWidget {
  final String bookId;
  final String title;
  final String author;
  final String description;
  final String imageUrl;

  const _BookListItem({
    required this.bookId,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE3DC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookImage(imageUrl: imageUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kPrimaryBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author.isNotEmpty ? author : 'Unknown author',
                    style: TextStyle(
                      fontSize: 12,
                      color: kPrimaryBrown.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isNotEmpty
                        ? description
                        : 'No description provided.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: kPrimaryBrown.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          await BorrowService().borrowBook(
                            bookId: bookId,
                            bookTitle: title,
                            userId: user.uid,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Borrow request sent')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size(0, 30),
                        ),
                        child: const Text(
                          'Borrow',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.bookmark_border,
                        color: kPrimaryBrown.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookImage extends StatelessWidget {
  final String imageUrl;
  const _BookImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasNetwork = imageUrl.startsWith('http');
    final isAsset = imageUrl.startsWith('assets/');
    Widget imageChild;
    if (hasNetwork) {
      imageChild = Image.network(
        imageUrl,
        width: 80,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    } else if (isAsset) {
      imageChild = Image.asset(
        imageUrl,
        width: 80,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    } else {
      imageChild = _fallback();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageChild,
    );
  }

  Widget _fallback() {
    return Container(
      width: 80,
      height: 110,
      color: Colors.grey[300],
      child: const Icon(Icons.book, color: Colors.grey),
    );
  }
}
