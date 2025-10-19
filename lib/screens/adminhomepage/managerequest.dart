import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logins/constants.dart';

class ManageRequestPage extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  ManageRequestPage({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates the request status. If accepted, sets dueDate 7 days from now
  Future<void> _updateStatus(String status) async {
    final updates = <String, dynamic>{'status': status};

    if (status == 'accepted') {
      final dueDate = DateTime.now().add(const Duration(days: 7));
      updates['dueDate'] = Timestamp.fromDate(dueDate);

      // Mark the book unavailable
      await _firestore
          .collection('books')
          .doc(requestData['bookId'])
          .update({'available': false});
    }

    await _firestore
        .collection('borrow_requests')
        .doc(requestId)
        .update(updates);
  }

  @override
  Widget build(BuildContext context) {
    final status = requestData['status'] ?? 'pending';
    final isReturned = status == 'returned';

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
                color: kPrimaryBrown,
              ),
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
                  onPressed: (!isReturned && status != 'accepted')
                      ? () async {
                          await _updateStatus('accepted');
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.check),
                  label: const Text("Accept"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: (!isReturned && status != 'rejected')
                      ? () async {
                          await _updateStatus('rejected');
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: (!isReturned && status == 'accepted')
                      ? () async {
                          await _updateStatus('returned');
                          await _firestore
                              .collection('books')
                              .doc(requestData['bookId'])
                              .update({'available': true});
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.assignment_turned_in),
                  label: const Text("Returned"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Create a new borrow request (from student side)
  static Future<void> createRequest({
    required String userId,
    required String bookId,
    required String bookTitle,
  }) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('borrow_requests').add({
      'userId': userId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }
}
