// lib/ebooks_page.dart

import 'package:flutter/material.dart';
import 'constants.dart';

// A simple data model for an E-Book
class EBook {
  final String title;
  final String author;
  final String imagePath;
  final String tag;

  EBook({
    required this.title,
    required this.author,
    required this.imagePath,
    required this.tag,
  });
}

// Mock data for the list
final List<EBook> ebooks = [
  EBook(
    title: 'Software Engineering',
    author: 'By Dr. Mahesh M. Goyani',
    imagePath: 'assets/images/book1.png',
    tag: 'Computer',
  ),
  EBook(
    title: 'A Textbook of Engineering Drawing',
    author: 'By Dr. Mahesh M. Goyani',
    imagePath: 'assets/images/book2.png',
    tag: 'Computer',
  ),
  EBook(
    title: 'A Textbook of Engineering Physics',
    author: 'By Dr. Mahesh M. Goyani',
    imagePath: 'assets/images/book3.png',
    tag: 'Physics',
  ),
];

class EBooksPage extends StatelessWidget {
  const EBooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: _buildAppBar(context),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: ebooks.length,
        itemBuilder: (context, index) {
          return _buildEBookListItem(ebooks[index]);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(140.0), // Increased height for search bar
      child: Container(
        decoration: const BoxDecoration(
          color: kPrimaryBrown,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Title Row
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
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
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

  Widget _buildEBookListItem(EBook book) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAE3DC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Book Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                book.imagePath,
                width: 80,
                height: 110,
                fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 110,
                  color: Colors.grey[300],
                  child: const Icon(Icons.book, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Book Details
            Expanded(
              child: SizedBox(
                height: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and Author
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
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
                          book.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: kPrimaryBrown.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    // Tag, Button, and Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7CCC8),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(book.tag, style: const TextStyle(fontSize: 10, color: kPrimaryBrown)),
                        ),
                        // Read Now Button
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(0, 30)
                          ),
                          child: const Text('Read Now', style: TextStyle(fontSize: 12)),
                        ),
                        Icon(Icons.bookmark_border, color: kPrimaryBrown.withOpacity(0.7)),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}