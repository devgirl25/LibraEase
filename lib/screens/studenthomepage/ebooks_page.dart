import 'package:flutter/material.dart';
// foundation and Platform imports removed — import-based ebook feature disabled
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../logins/constants.dart';

// NOTE: The previous Google Books / import-function feature was removed.
// This student-facing page now only displays available e-books and opens
// previews. No network import or Cloud Function calls are made from here.

class EBooksPage extends StatefulWidget {
  const EBooksPage({super.key});

  @override
  State<EBooksPage> createState() => _EBooksPageState();
}

class _EBooksPageState extends State<EBooksPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  // flag reserved for future UI state

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Debug sample add removed to avoid calling remote import endpoints.

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

          // build category list from docs
          final categories = <String>{'All'};
          for (var d in docs) {
            final cat = (d.data()['category'] ?? '').toString();
            if (cat.isNotEmpty) categories.add(cat);
          }

          // ensure selected category is valid
          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'All';
          }

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
            final category = (data['category'] ?? '').toString();
            final query = _searchQuery.toLowerCase();
            final matchesQuery =
                title.contains(query) || author.contains(query);
            final matchesCategory =
                _selectedCategory == 'All' || category == _selectedCategory;
            return matchesQuery && matchesCategory;
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
                onOpenPreview: (url) => _openPreview(url),
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
                // Debug-only sample add removed to avoid remote calls.
                trailing: null,
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
              // Category filter row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    const Text('Category:',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildCategoryDropdown()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    // We'll fetch categories from the collection snapshot via a stream
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('ebooks').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final categories = <String>['All'];
        for (var d in docs) {
          final cat = (d.data()['category'] ?? '').toString();
          if (cat.isNotEmpty && !categories.contains(cat)) categories.add(cat);
        }
        return DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          items: categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedCategory = v ?? 'All';
          }),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        );
      },
    );
  }

  // ----------------------
  // Import from Google Books API
  // ----------------------
  // Import functionality has been moved to the Admin UI. Student-facing page
  // only displays available ebooks now.

  // Open pdf/preview in external browser (note: preventing download depends on provider)
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
  final void Function(String url)? onOpenPreview;

  const EBookListItem({
    super.key,
    required this.ebookId,
    required this.title,
    required this.author,
    required this.category,
    required this.pdfUrl,
    this.onOpenPreview,
  });

  @override
  State<EBookListItem> createState() => _EBookListItemState();
}

class _EBookListItemState extends State<EBookListItem> {
  // Wishlist removed from UI; this widget now displays ebook info + Read action only.

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
                              if (widget.onOpenPreview != null) {
                                widget.onOpenPreview!(widget.pdfUrl);
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Opening ${widget.title}...')),
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
                        // wishlist removed - no bookmark icon
                        const SizedBox(width: 8),
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
