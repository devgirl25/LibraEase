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
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: kPrimaryBrown,
              expandedHeight: 120,
              flexibleSpace: const FlexibleSpaceBar(
                title: Text('Browse E-Books'),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ),
            ),
            SliverFillRemaining(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data();
                    final title = (data['title'] ?? '').toLowerCase();
                    final author = (data['author'] ?? '').toLowerCase();
                    return title.contains(_searchQuery.toLowerCase()) ||
                        author.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text('No e-books found',
                          style: TextStyle(color: kPrimaryBrown)),
                    );
                  }

                  final screenWidth = MediaQuery.of(context).size.width;
                  final isWide = screenWidth > 600;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isWide
                        ? GridView.builder(
                            itemCount: filteredDocs.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 3.2,
                            ),
                            itemBuilder: (context, index) {
                              final data = filteredDocs[index].data();
                              return EBookListItem(
                                title: data['title'] ?? '',
                                author: data['author'] ?? '',
                                category: data['category'] ?? 'Unknown',
                                pdfUrl: data['pdfUrl'] ?? '',
                                imageUrl: data['imageUrl'] ?? '',
                                onOpenPreview: (url) => _openPreview(url),
                              );
                            },
                          )
                        : ListView.builder(
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final data = filteredDocs[index].data();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: EBookListItem(
                                  title: data['title'] ?? '',
                                  author: data['author'] ?? '',
                                  category: data['category'] ?? 'Unknown',
                                  pdfUrl: data['pdfUrl'] ?? '',
                                  imageUrl: data['imageUrl'] ?? '',
                                  onOpenPreview: (url) => _openPreview(url),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
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

class EBookListItem extends StatelessWidget {
  final String title;
  final String author;
  final String category;
  final String pdfUrl;
  final String imageUrl;
  final void Function(String url)? onOpenPreview;

  const EBookListItem({
    super.key,
    required this.title,
    required this.author,
    required this.category,
    required this.pdfUrl,
    required this.imageUrl,
    this.onOpenPreview,
  });

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
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
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
                        title,
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
                        author.isNotEmpty ? author : 'Unknown author',
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
                        if (pdfUrl.isNotEmpty) {
                          onOpenPreview?.call(pdfUrl);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('PDF not available')));
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
