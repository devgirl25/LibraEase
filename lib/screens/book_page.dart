// lib/book_list_page.dart

import 'package:flutter/material.dart';
import 'constants.dart';

// A more detailed data model that can be used for both types of books
class Book {
  final String title;
  final String author;
  final String imagePath;
  final String tag;
  final bool isAvailable;

  Book({
    required this.title,
    required this.author,
    required this.imagePath,
    required this.tag,
    this.isAvailable = false, // Physical books can be available or not
  });
}

// Mock data for the E-Books list
final List<Book> ebooks = [
  Book(
    title: 'Software Engineering',
    author: 'By Dr. Mahesh M. Goyani',
    imagePath: 'assets/images/book1.png',
    tag: 'Computer',
  ),
  Book(
    title: 'A Textbook of Engineering Drawing',
    author: 'By Dr. Mahesh M. Goyani',
    imagePath: 'assets/images/book2.png',
    tag: 'Computer',
  ),
];

// Mock data for the Physical Books list
final List<Book> physicalBooks = [
  Book(
    title: 'Software Engineering',
    author: "By Brian D'Andrade",
    imagePath: 'assets/images/book1.png',
    tag: 'Computer',
    isAvailable: true,
  ),
  Book(
    title: 'Software Engineering',
    author: "By Brian D'Andrade",
    imagePath: 'assets/images/book2.png',
    tag: 'Computer',
    isAvailable: true,
  ),
];


// This is the single, reusable page for showing a list of books.
class BookListPage extends StatelessWidget {
  final String pageTitle;
  final List<Book> books;
  final bool isEBookList;

  const BookListPage({
    super.key,
    required this.pageTitle,
    required this.books,
    required this.isEBookList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: _buildAppBar(context),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return _buildBookListItem(books[index]);
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
                title: Text(
                  pageTitle, // Use the pageTitle parameter
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
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

  Widget _buildBookListItem(Book book) {
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
                    // --- CONDITIONAL WIDGETS ---
                    // This Row now builds itself based on whether it's an E-Book or a physical Book.
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7CCC8),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(book.tag, style: const TextStyle(fontSize: 10, color: kPrimaryBrown)),
                        ),
                        if (!isEBookList && book.isAvailable) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Text('Available', style: TextStyle(fontSize: 10, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        const Spacer(), // Pushes the button and icon to the end
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
                          child: Text(isEBookList ? 'Read Now' : 'Borrow Now', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
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