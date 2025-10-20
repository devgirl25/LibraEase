import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_page.dart'; // ✅ Make sure this import path is correct

// --- CONSTANT COLORS ---
const Color kPrimaryBrown = Color.fromARGB(255, 87, 36, 14);
const Color kLightCream = Color.fromARGB(255, 245, 235, 220);

class BrowseBooksPage extends StatefulWidget {
  const BrowseBooksPage({super.key});

  @override
  State<BrowseBooksPage> createState() => _BrowseBooksPageState();
}

class _BrowseBooksPageState extends State<BrowseBooksPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _availabilityFilter = 'All'; // All, Available, Unavailable

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightCream,
      appBar: AppBar(
        backgroundColor: kPrimaryBrown,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Browse Books',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ----------------- Search Bar -----------------
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search Book by title ',
                prefixIcon: const Icon(Icons.search, color: kPrimaryBrown),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // ----------------- Availability Filter -----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Text('Filter :', style: TextStyle(color: kPrimaryBrown)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _availabilityFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(
                        value: 'Available', child: Text('Available')),
                    DropdownMenuItem(
                        value: 'Unavailable', child: Text('Unavailable')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _availabilityFilter = value ?? 'All';
                    });
                  },
                ),
              ],
            ),
          ),

          // ----------------- Book List -----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('books').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: kPrimaryBrown));
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading books.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No books found.'));
                }

                final books = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final author =
                      (data['author'] ?? '').toString().toLowerCase();
                  final available = (data['available'] ?? true) as bool;

                  // Search filter
                  final matchesSearch = title.contains(_searchQuery) ||
                      author.contains(_searchQuery);

                  // Availability filter
                  bool matchesAvailability = true;
                  if (_availabilityFilter == 'Available') {
                    matchesAvailability = available;
                  }
                  if (_availabilityFilter == 'Unavailable') {
                    matchesAvailability = !available;
                  }

                  return matchesSearch && matchesAvailability;
                }).toList();

                if (books.isEmpty) {
                  return const Center(
                      child: Text('No books found matching filters.'));
                }

                return ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final data = books[index].data() as Map<String, dynamic>;
                    return BookListItem(
                      bookId: books[index].id,
                      title: data['title'] ?? 'Untitled',
                      author: data['author'] ?? 'Unknown Author',
                      description:
                          data['description'] ?? 'No description available.',
                      imageUrl: data['imageUrl'] ?? '',
                      category: data['category'] ?? 'General',
                      available: data['available'] ?? true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BookListItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 65,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.book, size: 50, color: kPrimaryBrown),
                ),
              )
            : const Icon(Icons.book, size: 50, color: kPrimaryBrown),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: kPrimaryBrown),
        ),
        subtitle: Text(author),
        trailing: Icon(
          available ? Icons.check_circle : Icons.cancel,
          color: available ? Colors.green : Colors.red,
        ),
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
                available: available,
              ),
            ),
          );
        },
      ),
    );
  }
}
