import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logins/constants.dart';
import '../../services/notificationservice.dart';

class ManageRequestPage extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const ManageRequestPage({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  Future<void> _updateStatus(String status, {String? rejectionReason}) async {
    final firestore = FirebaseFirestore.instance;
    final notificationService = NotificationService();

    await firestore.collection('borrow_requests').doc(requestId).update({
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });

    final userId = requestData['userId'] as String;
    final bookTitle = requestData['bookTitle'] as String;

    // If accepted, mark book unavailable and send approval notification
    if (status == 'accepted') {
      await firestore
          .collection('books')
          .doc(requestData['bookId'])
          .update({'available': false});

      // Get due date from request
      final dueDate = requestData['dueDate'] != null
          ? (requestData['dueDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 14));

      // Send approval notification
      await notificationService.sendBorrowApprovedNotification(
        userId: userId,
        bookTitle: bookTitle,
        dueDate: dueDate,
      );
    } else if (status == 'rejected') {
      // Send rejection notification
      await notificationService.sendBorrowRejectedNotification(
        userId: userId,
        bookTitle: bookTitle,
        reason: rejectionReason,
      );
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Request accepted and user notified'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
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
                          // Show dialog to enter rejection reason
                          final reason = await showDialog<String>(
                            context: context,
                            builder: (context) => _RejectionReasonDialog(),
                          );

                          if (reason != null) {
                            await _updateStatus('rejected',
                                rejectionReason: reason);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Request rejected and user notified'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
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

class _RejectionReasonDialog extends StatefulWidget {
  @override
  State<_RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<_RejectionReasonDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejection Reason'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Enter reason for rejection (optional)',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _controller.text.trim());
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
