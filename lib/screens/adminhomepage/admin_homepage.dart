import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_helpers.dart';
import 'package:libra/screens/adminhomepage/manageregpage.dart';
import 'add_ebooks_page.dart';
// import 'package:libra/screens/adminhomepage/add_ebooks_page.dart' hide Padding;
import '../../widgets/dashboardcard.dart';
import 'add_book_page.dart';
import 'borrow_request_page.dart';
import 'overdue_books.dart';

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
            stream: FirebaseFirestore.instance
                .collection('users')
                //.where('role', isEqualTo: 'student') // optional filter
                .snapshots(),
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
                  // Navigate to Members Page
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
                  // Navigate to Borrow Requests Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BorrowRequestsPage(),
                    ),
                  );
                },
              );
            },
          ),

          // ✅ Overdue Books card
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

          // ✅ Registration Requests card
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('registration_requests')
                .where('status', isEqualTo: 'pending') // only pending
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
                title: "REGISTRATION REQUESTS",
                icon: Icons.person_add,
                onTap: () {
                  // Navigate to the Registration Requests Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageRegRequestsPage(),
                    ),
                  );
                },
              );
            },
          ),

          // ✅ Add E-Books card (admin-only)
          DashboardCard(
            value: '-',
            title: "ADD E-BOOKS",
            icon: Icons.cloud_download,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEBooksPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
