import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadFormPage extends StatefulWidget {
  const UploadFormPage({super.key});

  @override
  State<UploadFormPage> createState() => _UploadFormPageState();
}

class _UploadFormPageState extends State<UploadFormPage> {
  final TextEditingController _formController = TextEditingController();
  final _formDocRef =
      FirebaseFirestore.instance.collection('settings').doc('registrationForm');
  bool _isSaving = false; // show loading when saving

  @override
  void initState() {
    super.initState();
    _loadExistingLink();
  }

  // Load existing link if any
  Future<void> _loadExistingLink() async {
    try {
      final doc = await _formDocRef.get();
      if (doc.exists && doc.data()!.containsKey('link')) {
        _formController.text = doc['link'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading link: $e')),
      );
    }
  }

  // Save the link to Firestore
  Future<void> _saveLink() async {
    final link = _formController.text.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a link')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Set the link in Firestore
      await _formDocRef.set({'link': link});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Form link saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving link: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Registration Form'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.brown[50],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Google Form Link',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _formController,
                  decoration: const InputDecoration(
                    labelText: 'Paste the Google Form URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Link',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
