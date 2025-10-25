import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logins/constants.dart';

class ManageRequestPage extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;

  const ManageRequestPage({
    super.key,
    required this.requestId,
    required this.requestData,
  });

  @override
  State<ManageRequestPage> createState() => _ManageRequestPageState();
}

class _ManageRequestPageState extends State<ManageRequestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String requestedByName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.requestData['userId'])
          .get();

      if (userDoc.exists) {
        setState(() {
          requestedByName = userDoc['name'] ?? 'Unknown User';
        });
      } else {
        setState(() {
          requestedByName = 'Unknown User';
        });
      }
    } catch (e) {
      setState(() {
        requestedByName = 'Unknown User';
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    final bookRef =
        _firestore.collection('books').doc(widget.requestData['bookId']);

    if (status == 'accepted') {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(bookRef);
        if (!snapshot.exists) return;
        final currentCopies = snapshot['no_of_copies'] ?? 0;
        if (currentCopies > 0) {
          transaction.update(bookRef, {'no_of_copies': currentCopies - 1});
        } else {
          throw Exception("No copies available");
        }
      });
    } else if (status == 'returned') {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(bookRef);
        if (!snapshot.exists) return;
        final currentCopies = snapshot['no_of_copies'] ?? 0;
        transaction.update(bookRef, {'no_of_copies': currentCopies + 1});
      });
    }

    await _firestore
        .collection('borrow_requests')
        .doc(widget.requestId)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.requestData['status'] ?? 'pending';
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';

    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore
            .collection('books')
            .doc(widget.requestData['bookId'])
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final imageUrl = bookData['imageUrl'] ?? '';

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top AppBar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back,
                              color: kPrimaryBrown, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Manage Borrow Request",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBrown,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Book Info Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 6,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      height: 120,
                                      width: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 120,
                                        width: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.book,
                                            size: 50, color: kPrimaryBrown),
                                      ),
                                    )
                                  : Container(
                                      height: 120,
                                      width: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.book,
                                          size: 50, color: kPrimaryBrown),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.requestData['bookTitle'] ?? 'Unknown Book',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBrown,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Requested by: $requestedByName",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info, color: kPrimaryBrown),
                                const SizedBox(width: 8),
                                Text(
                                  "Status: $status",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isAccepted
                                        ? Colors.green
                                        : isPending
                                            ? Colors.orange
                                            : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: isPending
                              ? () async {
                                  await _updateStatus('accepted');
                                  Navigator.pop(context);
                                }
                              : null,
                          icon: const Icon(Icons.check),
                          label: Text("Accept",
                              style: GoogleFonts.poppins(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: isPending
                              ? () async {
                                  await _updateStatus('rejected');
                                  Navigator.pop(context);
                                }
                              : null,
                          icon: const Icon(Icons.close),
                          label: Text("Reject",
                              style: GoogleFonts.poppins(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: isAccepted
                              ? () async {
                                  await _updateStatus('returned');
                                  Navigator.pop(context);
                                }
                              : null,
                          icon: const Icon(Icons.assignment_turned_in),
                          label: Text("Returned",
                              style: GoogleFonts.poppins(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
