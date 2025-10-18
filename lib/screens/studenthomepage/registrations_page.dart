import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
// removed unused import
import '../logins/constants.dart';

class RegistrationsPage extends StatefulWidget {
  const RegistrationsPage({super.key});

  @override
  State<RegistrationsPage> createState() => _RegistrationsPageState();
}

class _RegistrationsPageState extends State<RegistrationsPage> {
  final user = FirebaseAuth.instance.currentUser;

  // Replace with your Google Form URL
  final String bookBankFormUrl = 'https://forms.gle/YOUR_GOOGLE_FORM_LINK';

  // Last date to register
  final DateTime lastRegistrationDate = DateTime(2025, 10, 31);

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: kScaffoldBackground,
        body: Center(child: Text('Please login to view registrations')),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookBankCard(),
              const SizedBox(height: 24),
              const Text(
                'My Registration Requests',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBrown,
                ),
              ),
              const SizedBox(height: 16),
              _buildRegistrationRequestsList(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------- Book Bank Card ---------------------
  Widget _buildBookBankCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('registration_requests')
          .where('userId', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasPendingRequest = false;
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          hasPendingRequest = docs.any((doc) {
            final status = doc.data()['status'] ?? 'pending';
            return status == 'pending' || status == 'approved';
          });
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryBrown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.book,
                      color: kPrimaryBrown,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Book Bank Registration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryBrown,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Submit your Book Bank request via the Google Form or register directly below. Make sure to fill in all required details.',
                style: TextStyle(
                  fontSize: 14,
                  color: kPrimaryBrown.withOpacity(0.8),
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: hasPendingRequest ||
                              DateTime.now().isAfter(lastRegistrationDate)
                          ? null
                          : () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('registration_requests')
                                    .add({
                                  'userId': user!.uid,
                                  'studentName': user!.displayName ?? 'Student',
                                  'status': 'pending',
                                  'submittedAt': Timestamp.now(),
                                  'remarks': '',
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Registration request submitted!'),
                                  ),
                                );
                              } catch (e, st) {
                                // Log the error and show a helpful message to the user
                                debugPrint(
                                    'Failed to submit registration request: $e\n$st');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Registration failed: ${e.toString()}'),
                                    backgroundColor: Colors.red[700],
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.how_to_reg),
                      label: const Text('Register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBrown,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (await canLaunchUrl(Uri.parse(bookBankFormUrl))) {
                          await launchUrl(Uri.parse(bookBankFormUrl),
                              mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open the form.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Form'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------- Registration Requests List ---------------------
  Widget _buildRegistrationRequestsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('registration_requests')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('submittedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.assignment_outlined,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No registration requests yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: kPrimaryBrown,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final status = data['status'] ?? 'pending';
            final timestamp = data['submittedAt'] as Timestamp?;
            final remarks = data['remarks'] ?? '';
            final studentName = data['studentName'] ?? 'You';

            return _buildRegistrationCard(
              status: status,
              timestamp: timestamp,
              remarks: remarks,
              studentName: studentName,
            );
          },
        );
      },
    );
  }

  Widget _buildRegistrationCard({
    required String status,
    required Timestamp? timestamp,
    required String remarks,
    required String studentName,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case 'denied':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requested by: $studentName',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kPrimaryBrown,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $statusText',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        'Submitted: ${_formatDate(timestamp.toDate())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: kPrimaryBrown.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Remarks: $remarks',
              style: TextStyle(
                fontSize: 13,
                color: kPrimaryBrown.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: Container(
        decoration: const BoxDecoration(
          color: kPrimaryBrown,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Center(
            child: ListTile(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Registrations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
