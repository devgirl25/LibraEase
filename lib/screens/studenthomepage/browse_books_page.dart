import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';
import 'book_page.dart';

class BrowseBooksPage extends StatefulWidget {
  const BrowseBooksPage({super.key});

  @override
  State<BrowseBooksPage> createState() => _BrowseBooksPageState();
}

class _BrowseBooksPageState extends State<BrowseBooksPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140.0),
        child: Container(
          decoration: const BoxDecoration(
            color: kPrimaryBrown,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'Browse Books',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search books...',
                        prefixIcon: Icon(Icons.search, color: kPrimaryBrown),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

          final filteredDocs = docs.where((doc) {
            final data = doc.data();
            final title = (data['title'] ?? '').toString().toLowerCase();
            final author = (data['author'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            return title.contains(query) || author.contains(query);
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(
              child: Text(
                'No books found',
                style: TextStyle(color: kPrimaryBrown, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data();
              return BookListItem(
                bookId: filteredDocs[index].id,
                title: data['title'] ?? '',
                author: data['author'] ?? '',
                description: data['description'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                category: data['category'] ?? 'Unknown',
                available: data['available'] ?? true,
              );
            },
          );
        },
      ),
    );
  }
}

class BookListItem extends StatefulWidget {
  final String bookId;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String category;
  final bool available;

  const BookListItem({
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
  State<BookListItem> createState() => _BookListItemState();
}

class _BookListItemState extends State<BookListItem> {
  final user = FirebaseAuth.instance.currentUser;
  bool isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('wishlist')
        .doc(widget.bookId)
        .get();
    if (doc.exists) setState(() => isWishlisted = true);
  }

  Future<void> _toggleWishlist() async {
    if (user == null) return;
    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('wishlist')
        .doc(widget.bookId);

    if (isWishlisted) {
      await wishlistRef.delete();
      setState(() => isWishlisted = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Removed from Wishlist')));
    } else {
      await wishlistRef.set({
        'bookId': widget.bookId,
        'title': widget.title,
        'author': widget.author,
        'imageUrl': widget.imageUrl,
        'category': widget.category,
        'available': widget.available,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => isWishlisted = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added to Wishlist')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailPage(
                bookId: widget.bookId,
                title: widget.title,
                author: widget.author,
                description: widget.description ?? '',
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: kPrimaryBrown.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.category,
                              style: const TextStyle(
                                  color: kPrimaryBrown,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: widget.available
                                  ? Colors.green[100]
                                  : Colors.red[100],
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                              widget.available ? 'Available' : 'Not Available',
                              style: TextStyle(
                                  color: widget.available
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _toggleWishlist,
                        child: Icon(
                          isWishlisted ? Icons.bookmark : Icons.bookmark_border,
                          color: isWishlisted
                              ? kPrimaryBrown
                              : kPrimaryBrown.withOpacity(0.7),
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
