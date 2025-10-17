import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logins/constants.dart';

class ManageRequestPage extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const ManageRequestPage({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  Future<void> _updateStatus(String status) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('borrow_requests').doc(requestId).update({
      'status': status,
    });

    // If accepted, mark book unavailable
    if (status == 'accepted') {
      await firestore
          .collection('books')
          .doc(requestData['bookId'])
          .update({'available': false});
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = requestData['status'] ?? 'pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Request"),
        backgroundColor: kPrimaryBrown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requestData['bookTitle'] ?? 'Unknown Book',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBrown),
            ),
            const SizedBox(height: 16),
            Text("Requested by: ${requestData['userId']}"),
            const SizedBox(height: 16),
            Text("Current status: $status"),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: status != 'accepted'
                      ? () async {
                          await _updateStatus('accepted');
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text("Accept"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: status != 'rejected'
                      ? () async {
                          await _updateStatus('rejected');
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
