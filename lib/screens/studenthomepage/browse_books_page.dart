import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_page.dart'; // Make sure this import path is correct

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
          // Search Bar
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
                hintText: 'Search Book by title',
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

          // Availability Filter
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

          // Book List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('books').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryBrown),
                  );
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
                  final noOfCopies = (data['no_of_copies'] ?? 0) as int;

                  // Search filter
                  final matchesSearch = title.contains(_searchQuery) ||
                      author.contains(_searchQuery);

                  // Availability filter based on noOfCopies
                  bool matchesAvailability = true;
                  if (_availabilityFilter == 'Available') {
                    matchesAvailability = noOfCopies > 0;
                  }
                  if (_availabilityFilter == 'Unavailable') {
                    matchesAvailability = noOfCopies <= 0;
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
                    final noOfCopies = (data['no_of_copies'] ?? 0) as int;

                    return BookListItem(
                      bookId: books[index].id,
                      title: data['title'] ?? 'Untitled',
                      author: data['author'] ?? 'Unknown Author',
                      description:
                          data['description'] ?? 'No description available.',
                      imageUrl: data['imageUrl'] ?? '',
                      category: data['category'] ?? 'General',
                      noOfCopies: noOfCopies,
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
  final int noOfCopies; // <-- use this instead of bool available

  const BookListItem({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.noOfCopies,
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
          noOfCopies > 0 ? Icons.check_circle : Icons.cancel,
          color: noOfCopies > 0 ? Colors.green : Colors.red,
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
                noOfCopies: noOfCopies, // pass actual copies
              ),
            ),
          );
        },
      ),
    );
  }
}
//---------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------//

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'book_page.dart';

// // --- CONSTANT COLORS ---
// const Color kPrimaryBrown = Color(0xFF2E1C0D);
// const Color kLightCream = Color(0xFFF5E9DA);
// const Color kSoftBeige = Color(0xFFD2BDA6);

// class BrowseBooksPage extends StatefulWidget {
//   const BrowseBooksPage({super.key});

//   @override
//   State<BrowseBooksPage> createState() => _BrowseBooksPageState();
// }

// class _BrowseBooksPageState extends State<BrowseBooksPage>
//     with TickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _searchController = TextEditingController();

//   String _searchQuery = '';
//   String _availabilityFilter = 'All';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kLightCream,
//       appBar: AppBar(
//         backgroundColor: kPrimaryBrown,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Browse Books',
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: true,
//       ),

//       // --- BODY ---
//       body: Column(
//         children: [
//           const SizedBox(height: 10),

//           // --- Search Bar ---
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: TextField(
//               controller: _searchController,
//               onChanged: (value) => setState(() {
//                 _searchQuery = value.toLowerCase();
//               }),
//               style: GoogleFonts.poppins(),
//               decoration: InputDecoration(
//                 hintText: 'Search by title or author...',
//                 hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
//                 prefixIcon: const Icon(Icons.search, color: kPrimaryBrown),
//                 filled: true,
//                 fillColor: Colors.white,
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide:
//                       const BorderSide(color: kPrimaryBrown, width: 1.4),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(14),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 12),

//           // --- Filter Dropdown ---
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 Text(
//                   'Filter:',
//                   style: GoogleFonts.poppins(
//                     fontSize: 15,
//                     color: kPrimaryBrown,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: Colors.brown.shade200),
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: _availabilityFilter,
//                       items: const [
//                         DropdownMenuItem(value: 'All', child: Text('All')),
//                         DropdownMenuItem(
//                             value: 'Available', child: Text('Available')),
//                         DropdownMenuItem(
//                             value: 'Unavailable', child: Text('Unavailable')),
//                       ],
//                       onChanged: (value) {
//                         setState(() => _availabilityFilter = value ?? 'All');
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 10),

//           // --- Book List Stream ---
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection('books').snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(
//                     child: CircularProgressIndicator(color: kPrimaryBrown),
//                   );
//                 }

//                 if (snapshot.hasError) {
//                   return const Center(child: Text('Error loading books.'));
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       'No books found.',
//                       style: TextStyle(color: Colors.black54),
//                     ),
//                   );
//                 }

//                 final books = snapshot.data!.docs.where((doc) {
//                   final data = doc.data() as Map<String, dynamic>;
//                   final title = (data['title'] ?? '').toString().toLowerCase();
//                   final author =
//                       (data['author'] ?? '').toString().toLowerCase();
//                   final noOfCopies = (data['no_of_copies'] ?? 0) as int;

//                   final matchesSearch = title.contains(_searchQuery) ||
//                       author.contains(_searchQuery);

//                   bool matchesAvailability = true;
//                   if (_availabilityFilter == 'Available') {
//                     matchesAvailability = noOfCopies > 0;
//                   } else if (_availabilityFilter == 'Unavailable') {
//                     matchesAvailability = noOfCopies <= 0;
//                   }

//                   return matchesSearch && matchesAvailability;
//                 }).toList();

//                 if (books.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       'No books found matching filters.',
//                       style: TextStyle(color: Colors.black54),
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   physics: const BouncingScrollPhysics(),
//                   itemCount: books.length,
//                   itemBuilder: (context, index) {
//                     final data = books[index].data() as Map<String, dynamic>;
//                     final noOfCopies = (data['no_of_copies'] ?? 0) as int;

//                     return AnimatedScale(
//                       scale: 1,
//                       duration: Duration(milliseconds: 250 + (index * 60)),
//                       curve: Curves.easeOutBack,
//                       child: BookListItem(
//                         bookId: books[index].id,
//                         title: data['title'] ?? 'Untitled',
//                         author: data['author'] ?? 'Unknown Author',
//                         description:
//                             data['description'] ?? 'No description available.',
//                         imageUrl: data['imageUrl'] ?? '',
//                         category: data['category'] ?? 'General',
//                         noOfCopies: noOfCopies,
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class BookListItem extends StatelessWidget {
//   final String bookId;
//   final String title;
//   final String author;
//   final String description;
//   final String imageUrl;
//   final String category;
//   final int noOfCopies;

//   const BookListItem({
//     super.key,
//     required this.bookId,
//     required this.title,
//     required this.author,
//     required this.description,
//     required this.imageUrl,
//     required this.category,
//     required this.noOfCopies,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final available = noOfCopies > 0;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(18),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => BookDetailPage(
//                 bookId: bookId,
//                 title: title,
//                 author: author,
//                 description: description,
//                 imageUrl: imageUrl,
//                 category: category,
//                 noOfCopies: noOfCopies,
//               ),
//             ),
//           );
//         },
//         child: Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(18),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.brown.withOpacity(0.1),
//                 blurRadius: 6,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               Hero(
//                 tag: imageUrl,
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(18),
//                     bottomLeft: Radius.circular(18),
//                   ),
//                   child: imageUrl.isNotEmpty
//                       ? Image.network(
//                           imageUrl,
//                           width: 80,
//                           height: 110,
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) => const Icon(Icons.book,
//                               size: 50, color: kPrimaryBrown),
//                         )
//                       : const Icon(Icons.book, size: 50, color: kPrimaryBrown),
//                 ),
//               ),
//               Expanded(
//                 child: Padding(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         title,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: kPrimaryBrown,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         author,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: GoogleFonts.poppins(
//                           color: Colors.black87,
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(height: 6),
//                       Text(
//                         available ? "Available" : "Unavailable",
//                         style: GoogleFonts.poppins(
//                           color: available ? Colors.green : Colors.red,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(right: 12),
//                 child: Icon(
//                   available ? Icons.check_circle : Icons.cancel,
//                   color: available ? Colors.green : Colors.red,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

//**************************************************************************************************************************** */
