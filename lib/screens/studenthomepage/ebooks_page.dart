import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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
   // final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: _buildAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600; // tablet breakpoint

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

              // 🟢 Responsive list/grid view
              if (isWide) {
                // Grid for tablets/web
                return GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: filteredDocs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 3.2,
                  ),
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data();
                    return EBookListItem(
                      ebookId: filteredDocs[index].id,
                      title: data['title'] ?? '',
                      author: data['author'] ?? '',
                      category: data['category'] ?? 'Unknown',
                      pdfUrl: data['pdfUrl'] ?? '',
                      imageUrl: data['imageUrl'] ?? '',
                      onOpenPreview: (url) => _openPreview(url),
                    );
                  },
                );
              } else {
                // List for mobile
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data();
                    return Column(
                      children: [
                        EBookListItem(
                          ebookId: filteredDocs[index].id,
                          title: data['title'] ?? '',
                          author: data['author'] ?? '',
                          category: data['category'] ?? 'Unknown',
                          pdfUrl: data['pdfUrl'] ?? '',
                          imageUrl: data['imageUrl'] ?? '',
                          onOpenPreview: (url) => _openPreview(url),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100.0),
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
                      hintText: 'Search e-books..',
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

  Future<void> _openPreview(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cannot open link')));
      }
    }
  }
}

class EBookListItem extends StatefulWidget {
  final String ebookId;
  final String title;
  final String author;
  final String category;
  final String pdfUrl;
  final String imageUrl;
  final void Function(String url)? onOpenPreview;

  const EBookListItem({
    super.key,
    required this.ebookId,
    required this.title,
    required this.author,
    required this.category,
    required this.pdfUrl,
    required this.imageUrl,
    this.onOpenPreview,
  });

  @override
  State<EBookListItem> createState() => _EBookListItemState();
}

class _EBookListItemState extends State<EBookListItem> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Container(
      padding: EdgeInsets.all(isWide ? 16 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAE3DC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment:
            isWide ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Container(
            width: isWide ? 100 : 80,
            height: isWide ? 130 : 110,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: widget.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.menu_book,
                          color: kPrimaryBrown,
                          size: 40),
                    ),
                  )
                : const Icon(Icons.menu_book, color: kPrimaryBrown, size: 40),
          ),
          SizedBox(width: isWide ? 24 : 16),
          Expanded(
            child: SizedBox(
              height: isWide ? 130 : 110,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isWide ? 18 : 16,
                          color: kPrimaryBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.author.isNotEmpty
                            ? widget.author
                            : 'Unknown author',
                        style: TextStyle(
                          fontSize: isWide ? 13 : 12,
                          color: kPrimaryBrown.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment:
                        isWide ? Alignment.centerLeft : Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.pdfUrl.isNotEmpty) {
                          widget.onOpenPreview?.call(widget.pdfUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PDF not available')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBrown,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: isWide ? 16 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 30),
                      ),
                      child: Text('Read Now',
                          style: TextStyle(fontSize: isWide ? 14 : 12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
