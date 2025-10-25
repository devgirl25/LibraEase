import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class RegistrationsPage extends StatefulWidget {
  const RegistrationsPage({super.key});

  @override
  State<RegistrationsPage> createState() => _RegistrationsPageState();
}

class _RegistrationsPageState extends State<RegistrationsPage> {
  String googleFormLink = '';
  final lastRegistrationDate = DateTime(2025, 10, 31);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoogleFormLink();
  }

  Future<void> _loadGoogleFormLink() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('registrationForm')
          .get();

      if (doc.exists && doc.data()!.containsKey('link')) {
        setState(() {
          googleFormLink = doc['link'];
        });
      }
    } catch (e) {
      // Handle errors here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading form link: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = DateTime.now().isAfter(lastRegistrationDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Bank Registration'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.brown,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Register for Book Bank',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Submit your Book Bank request via the Google Form or register directly below. Make sure to fill in all required details.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.brown.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Last date to register: ${_formatDate(lastRegistrationDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: (googleFormLink.isEmpty || isClosed)
                                ? null
                                : () async {
                                    final uri = Uri.parse(googleFormLink);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Could not open the form')),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open Registration Form'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.brown, // button background
                              foregroundColor:
                                  Colors.white, // text & icon color
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          if (isClosed)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Registration Closed',
                                style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (googleFormLink.isEmpty && !isClosed)
                    const Text(
                      'The registration form is not available yet.',
                      style: TextStyle(
                          color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
