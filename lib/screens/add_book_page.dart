import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  bool _isLoading = false;
  XFile? _pickedImage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ImagePicker _picker = ImagePicker();

  // ✅ Pick image from gallery
  Future<void> pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  // ✅ Upload image to Firebase Storage
  Future<String> uploadImage(XFile imageFile) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('book_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = storageRef.putFile(File(imageFile.path));
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // ✅ Add book to Firestore
  Future<void> addBook() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a book image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image and get URL
      String imageUrl = await uploadImage(_pickedImage!);

      // Add book with image URL
      await _firestore.collection('books').add({
        'title': titleController.text.trim(),
        'author': authorController.text.trim(),
        'isbn': isbnController.text.trim(),
        'image': imageUrl,
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book added successfully!')),
      );

      // Clear form
      titleController.clear();
      authorController.clear();
      isbnController.clear();
      setState(() => _pickedImage = null);
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
              const SizedBox(height: 12),

              // Image picker button
              Row(
                children: [
                  ElevatedButton(
                    onPressed: pickImage,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF255A5A)),
                    child: const Text('Pick Book Image'),
                  ),
                  const SizedBox(width: 12),
                  _pickedImage != null
                      ? Image.file(
                          File(_pickedImage!.path),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Text('No image selected'),
                ],
              ),
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
