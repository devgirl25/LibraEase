import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_services.dart';
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
  final TextEditingController copiesController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _uploadBookWithImage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a book image first.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final imageUrl =
          await CloudinaryService().uploadImageToCloudinary(_selectedImage!);

      if (imageUrl == null) {
        throw Exception("Image upload failed");
      }

      await _firestore.collection('books').add({
        'title': titleController.text.trim(),
        'author': authorController.text.trim(),
        'isbn': isbnController.text.trim(),
        'description': descriptionController.text.trim(), // ✅ added
        'no_of_copies': int.parse(copiesController.text.trim()),
        'imageUrl': imageUrl,
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Book added successfully!')),
      );

      setState(() {
        _selectedImage = null;
      });

      titleController.clear();
      authorController.clear();
      isbnController.clear();
      descriptionController.clear(); // ✅ clear description
      copiesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Books'),
        backgroundColor: const Color(0xFF255A5A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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

                // Number of Copies
                TextFormField(
                  controller: copiesController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Copies',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter number of copies';
                    }
                    final number = int.tryParse(value);
                    if (number == null || number < 1) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Book Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter description'
                      : null,
                ),
                const SizedBox(height: 20),

                // Image Section
                if (_selectedImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: 150,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Retake Image"),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Camera"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          iconColor: Colors.white,
                          backgroundColor: const Color(0xFF255A5A),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text("Gallery"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          iconColor: Colors.white,
                          backgroundColor: const Color(0xFF255A5A),
                        ),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                _isUploading
                    ? const CircularProgressIndicator(color: Color(0xFF255A5A))
                    : ElevatedButton(
                        onPressed: _uploadBookWithImage,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF255A5A),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Add Book with Image'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
