import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/dashboardcard.dart';
import '../screens/add_book_page.dart';
import '../adminhomepage/borrow_request_page.dart'; // create this page to list borrow requests

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
          // MEMBERS
          DashboardCard(
            value: "750",
            title: "MEMBERS",
            icon: Icons.group,
            onTap: () {
              // Navigate to Members Page
            },
          ),

          // BOOKS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('books').snapshots(),
            builder: (context, snapshot) {
              String countText = "0";
              if (snapshot.hasData) countText = snapshot.data!.docs.length.toString();
              else if (snapshot.hasError) countText = "Err";

              return DashboardCard(
                value: countText,
                title: "BOOKS",
                icon: Icons.library_books,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddBookPage()),
                  );
                },
              );
            },
          ),

          // BORROW REQUESTS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrow_requests')
                .where('status', isEqualTo: 'borrowed') // only active requests
                .snapshots(),
            builder: (context, snapshot) {
              String countText = "0";
              if (snapshot.hasData) countText = snapshot.data!.docs.length.toString();
              else if (snapshot.hasError) countText = "Err";

              return DashboardCard(
                value: countText,
                title: "BORROW REQUESTS",
                icon: Icons.download_for_offline,
                onTap: () {
                  // Navigate to Borrow Requests Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BorrowRequestsPage()),
                  );
                },
              );
            },
          ),

          // OVERDUE BOOKS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrow_requests')
                .where('status', isEqualTo: 'borrowed')
                .where('dueDate', isLessThan: Timestamp.now())
                .snapshots(),
            builder: (context, snapshot) {
              String countText = "0";
              if (snapshot.hasData) countText = snapshot.data!.docs.length.toString();
              else if (snapshot.hasError) countText = "Err";

              return DashboardCard(
                value: countText,
                title: "OVERDUE BOOKS",
                icon: Icons.upload,
                onTap: () {
                  // Navigate to Overdue Books Page
                  // create OverdueBooksPage similar to BorrowRequestsPage
                },
              );
            },
          ),

          // REGISTRATION REQUESTS
          DashboardCard(
            value: "",
            title: "REGISTRATION REQUESTS",
            icon: Icons.person_add,
            onTap: () {
              // Navigate to Registration Requests Page
            },
          ),
        ],
      ),
    );
  }
}
