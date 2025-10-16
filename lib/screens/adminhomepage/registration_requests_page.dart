import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RegistrationRequestsPage extends StatelessWidget {
  const RegistrationRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Requests'),
        backgroundColor: const Color.fromARGB(255, 87, 36, 14),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('registration_requests')
            .where('status', isEqualTo: 'pending') // only pending requests
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No registration requests'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final studentName = data['studentName'] ?? 'Unknown';
              final requestType = data['requestType'] ?? 'Unknown';
              final submittedDate = (data['submittedDate'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Request: $requestType'),
                      const SizedBox(height: 4),
                      Text(
                        'Submitted: ${DateFormat.yMMMd().format(submittedDate)}',
                        style: TextStyle(
                            color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Approve request
                              await FirebaseFirestore.instance
                                  .collection('registration_requests')
                                  .doc(doc.id)
                                  .update({'status': 'approved'});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Request Approved')),
                              );
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              // Deny request
                              await FirebaseFirestore.instance
                                  .collection('registration_requests')
                                  .doc(doc.id)
                                  .update({'status': 'denied'});

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Request Denied')),
                              );
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Deny'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
