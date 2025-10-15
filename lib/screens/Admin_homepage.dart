import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/dashboardcard.dart';
import 'add_book_Page.dart';

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
          DashboardCard(
            value: "750",
            title: "MEMBERS",
            icon: Icons.group,
            onTap: () {
              // Navigate to Members Page
            },
          ),

          // ✅ Books card with dynamic count
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

          DashboardCard(
            value: "70",
            title: "BORROW REQUESTS",
            icon: Icons.download_for_offline,
            onTap: () {
              // Navigate to Borrow Requests Page
            },
          ),
          DashboardCard(
            value: "09",
            title: "OVERDUE BOOKS",
            icon: Icons.upload,
            onTap: () {
              // Navigate to Overdue Books Page
            },
          ),
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
