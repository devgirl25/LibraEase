import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Scan_book_page.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController isbnController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Add book to Firestore
  Future<void> addBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Add book without image
      await _firestore.collection('books').add({
        'title': titleController.text.trim(),
        'author': authorController.text.trim(),
        'isbn': isbnController.text.trim(),
        'description': descriptionController.text.trim(),
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book added successfully!')),
      );

      // Clear form
      titleController.clear();
      authorController.clear();
      isbnController.clear();
      descriptionController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    isbnController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Books'),
        backgroundColor: const Color(0xFF255A5A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Title
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Book Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),

              // Author
              TextFormField(
                controller: authorController,
                decoration: const InputDecoration(
                  labelText: 'Author',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter author' : null,
              ),
              const SizedBox(height: 12),

              // ISBN
              TextFormField(
                controller: isbnController,
                decoration: const InputDecoration(
                  labelText: 'ISBN',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter ISBN' : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Barcode'),
                  onPressed: () async {
                    final scanned = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (_) => const ScanBookPage(),
                      ),
                    );
                    if (scanned != null && scanned.isNotEmpty) {
                      isbnController.text = scanned;
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 12),

              // No image stored for books
              const SizedBox(height: 20),

              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF255A5A))
                  : ElevatedButton(
                      onPressed: addBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF255A5A),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Add Book'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
