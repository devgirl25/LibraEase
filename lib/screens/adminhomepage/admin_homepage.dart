import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_helpers.dart';
//import 'package:libraease/screens/adminhomepage/manageregpage.dart';
import 'add_ebooks_page.dart';
import '../../widgets/dashboardcard.dart';
import 'add_book_page.dart';
import 'borrow_request_page.dart';
import 'overdue_books.dart';
import 'fines_page.dart';
import 'uploadformpage.dart';
import 'members_page.dart';

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

  DateTime get today => DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ✅ Members card
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              String countText = "0";
              if (snapshot.connectionState == ConnectionState.waiting) {
                countText = "...";
              } else if (snapshot.hasError) {
                countText = "0";
              } else if (snapshot.hasData) {
                countText = snapshot.data!.docs.length.toString();
              }

              return DashboardCard(
                value: countText,
                title: "MEMBERS",
                icon: Icons.group,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AllUsersPage()),
                  );
                },
              );
            },
          ),

          // ✅ Books card
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('books').snapshots(),
            builder: (context, snapshot) {
              String countText = "0";
              if (snapshot.hasData) {
                countText = snapshot.data!.docs.length.toString();
              } else if (snapshot.hasError) {
                countText = "Err";
              }

              return DashboardCard(
                value: countText,
                title: "ADD BOOKS",
                icon: Icons.library_books,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddBookPage()),
                  );
                },
              );
            },
          ),

          // ✅ Borrow Requests card
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrow_requests')
                .snapshots(),
            builder: (context, snapshot) {
              String countText = "0";
              if (snapshot.connectionState == ConnectionState.waiting) {
                countText = "...";
              } else if (snapshot.hasError) {
                countText = "Err";
              } else if (snapshot.hasData) {
                countText = snapshot.data!.docs.length.toString();
              }

              return DashboardCard(
                value: countText,
                title: "BORROW REQUESTS",
                icon: Icons.download_for_offline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BorrowRequestsPage()),
                  );
                },
              );
            },
          ),

          // ✅ Overdue Books card
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrow_requests')
                .where('status', isEqualTo: 'accepted')
                .snapshots(),
            builder: (context, snapshot) {
              int overdueCount = 0;

              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;
                overdueCount = docs.where((doc) {
                  final raw = doc['dueDate'];
                  final dueDate = toDateTime(raw);
                  return dueDate != null && dueDate.isBefore(today);
                }).length;
              }

              return DashboardCard(
                value: overdueCount.toString(),
                title: "OVERDUE BOOKS",
                icon: Icons.upload,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OverdueBooksPage()),
                  );
                },
              );
            },
          ),

// ✅ Upload Registration Form card
          DashboardCard(
            value: '+',
            title: "UPLOAD FORM",
            icon: Icons.upload_file,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadFormPage()),
              );
            },
          ),

          // ✅ Add E-Books card
          DashboardCard(
            value: '+',
            title: "ADD E-BOOKS",
            icon: Icons.cloud_download,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEBooksPage()),
              );
            },
          ),

          // ✅ Fines card
          // Inside your GridView children:

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return DashboardCard(
                  value: '...',
                  title: "FINES",
                  icon: Icons.money_off,
                  onTap: () {},
                );
              }

              final users = snapshot.data!.docs;

              final futures = users.map<Future<double>>((userDoc) async {
                final statsSnap = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userDoc.id)
                    .collection('stats')
                    .doc('latest')
                    .get();

                if (statsSnap.exists) {
                  return (statsSnap['fineTotal'] ?? 0.0).toDouble();
                }
                return 0.0;
              }).toList();

              return FutureBuilder<List<double>>(
                future: Future.wait(futures),
                builder: (context, finesSnapshot) {
                  if (!finesSnapshot.hasData) {
                    return DashboardCard(
                      value: '...',
                      title: "FINES",
                      icon: Icons.money_off,
                      onTap: () {},
                    );
                  }

                  double totalFines =
                      finesSnapshot.data!.fold(0.0, (a, b) => a + b);

                  return DashboardCard(
                    value: "₹${totalFines.toStringAsFixed(2)}",
                    title: "FINES",
                    icon: Icons.money_off,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FinesPage()),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
