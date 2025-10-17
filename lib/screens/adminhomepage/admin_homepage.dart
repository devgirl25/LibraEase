import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libra/screens/adminhomepage/manageregpage.dart';
import '../../widgets/dashboardcard.dart';
import 'add_book_page.dart';
import 'borrow_request_page.dart'; // import the borrow requests page
//import 'registration_requests_page.dart';

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

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
                title: "BOOKS",
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
          DashboardCard(
            value: "09", // You can later replace with dynamic count
            title: "OVERDUE BOOKS",
            icon: Icons.upload,
            onTap: () {
              // Navigate to Overdue Books Page
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
        ],
      ),
    );
  }
}
