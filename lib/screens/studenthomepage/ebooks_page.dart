import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logins/constants.dart';

class EBooksPage extends StatefulWidget {
  const EBooksPage({super.key});

  @override
  State<EBooksPage> createState() => _EBooksPageState();
}

class _EBooksPageState extends State<EBooksPage> {
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
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('ebooks')
            .orderBy('title')
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
            return const Center(
              child: Text(
                'No e-books available',
                style: TextStyle(color: kPrimaryBrown, fontSize: 16),
              ),
            );
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
                'No e-books found',
                style: TextStyle(color: kPrimaryBrown, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data();
              return EBookListItem(
                ebookId: filteredDocs[index].id,
                title: data['title'] ?? '',
                author: data['author'] ?? '',
                category: data['category'] ?? 'Unknown',
                pdfUrl: data['pdfUrl'] ?? '',
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
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
                  'Browse E-Books',
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
                      hintText: 'Search e-books...',
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
    );
  }
}

class EBookListItem extends StatefulWidget {
  final String ebookId;
  final String title;
  final String author;
  final String category;
  final String pdfUrl;

  const EBookListItem({
    super.key,
    required this.ebookId,
    required this.title,
    required this.author,
    required this.category,
    required this.pdfUrl,
  });

  @override
  State<EBookListItem> createState() => _EBookListItemState();
}

class _EBookListItemState extends State<EBookListItem> {
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
        .collection('ebook_wishlist')
        .doc(widget.ebookId)
        .get();
    if (doc.exists) setState(() => isWishlisted = true);
  }

  Future<void> _toggleWishlist() async {
    if (user == null) return;
    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('ebook_wishlist')
        .doc(widget.ebookId);

    if (isWishlisted) {
      await wishlistRef.delete();
      setState(() => isWishlisted = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from Wishlist')));
      }
    } else {
      await wishlistRef.set({
        'ebookId': widget.ebookId,
        'title': widget.title,
        'author': widget.author,
        'category': widget.category,
        'pdfUrl': widget.pdfUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => isWishlisted = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-Book added to Wishlist')));
      }
    }
  }

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.menu_book, color: kPrimaryBrown, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
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
                          widget.author.isNotEmpty
                              ? widget.author
                              : 'Unknown author',
                          style: TextStyle(
                            fontSize: 12,
                            color: kPrimaryBrown.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7CCC8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.category,
                            style: const TextStyle(
                                fontSize: 10, color: kPrimaryBrown),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (widget.pdfUrl.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Opening ${widget.title}...')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('PDF not available')),
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
                          child: const Text('Read Now',
                              style: TextStyle(fontSize: 12)),
                        ),
                        GestureDetector(
                          onTap: _toggleWishlist,
                          child: Icon(
                            isWishlisted
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: isWishlisted
                                ? kPrimaryBrown
                                : kPrimaryBrown.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
