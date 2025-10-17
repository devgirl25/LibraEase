import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libra/screens/adminhomepage/manageregpage.dart';
import '../widgets/dashboardcard.dart';
import '../screens/adminhomepage/add_book_page.dart';
import '../screens/adminhomepage/borrow_request_page.dart';
import '../screens/adminhomepage/listoverduebook.dart';
//import '../screens/adminhomepage/registration_requests_page.dart';

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

  Widget _buildCard({
    required String value,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 140,
      child: DashboardCard(
        value: value,
        title: title,
        icon: icon,
        onTap: onTap,
      ),
    );
  }

  Future<Map<String, int>> _fetchCounts() async {
    final counts = <String, int>{};

    // Users count
    final usersSnap =
        await FirebaseFirestore.instance.collection('users').get();
    counts['members'] = usersSnap.docs.length;

    // Books count
    final booksSnap =
        await FirebaseFirestore.instance.collection('books').get();
    counts['books'] = booksSnap.docs.length;

    // Borrow requests count (pending)
    final borrowSnap = await FirebaseFirestore.instance
        .collection('borrow_requests')
        .where('status', isEqualTo: 'pending')
        .get();
    counts['borrowRequests'] = borrowSnap.docs.length;

    // Overdue books count
    final borrowedSnap = await FirebaseFirestore.instance
        .collection('borrow_requests')
        .where('status', isEqualTo: 'borrowed')
        .get();
    final overdueCount = borrowedSnap.docs.where((doc) {
      final dueDate = (doc['dueDate'] as Timestamp).toDate();
      return dueDate.isBefore(DateTime.now());
    }).length;
    counts['overdueBooks'] = overdueCount;

    // Registration requests count (pending)
    final regSnap = await FirebaseFirestore.instance
        .collection('registration_requests')
        .where('status', isEqualTo: 'pending')
        .get();
    counts['registrationRequests'] = regSnap.docs.length;

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchCounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final counts = snapshot.data ?? {};

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
          child: GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCard(
                value: counts['members']?.toString() ?? '0',
                title: "MEMBERS",
                icon: Icons.group,
                onTap: () {},
              ),
              _buildCard(
                value: counts['books']?.toString() ?? '0',
                title: "BOOKS",
                icon: Icons.library_books,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddBookPage()),
                  );
                },
              ),
             
             // Borrow Requests card
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('borrow_requests')
      .where('status', isEqualTo: 'pending')
      .snapshots(),
  builder: (context, snapshot) {
    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BorrowRequestsPage()),
        );
      },
      child: DashboardCard(
        value: count.toString(),
        title: "BORROW REQUESTS",
        icon: Icons.download_for_offline,
      ),
    );
  },
),

// Overdue Books card
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('borrow_requests')
      .where('status', isEqualTo: 'borrowed')
      .snapshots(),
  builder: (context, snapshot) {
    int overdueCount = 0;
    if (snapshot.hasData) {
      overdueCount = snapshot.data!.docs.where((doc) {
        final dueDate = (doc['dueDate'] as Timestamp).toDate();
        return dueDate.isBefore(DateTime.now());
      }).length;
    }
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OverdueBooksPage()),
        );
      },
      child: DashboardCard(
        value: overdueCount.toString(),
        title: "OVERDUE BOOKS",
        icon: Icons.upload,
      ),
    );
  },
),

              _buildCard(
                value: counts['registrationRequests']?.toString() ?? '0',
                title: "REGISTRATION REQUESTS",
                icon: Icons.person_add,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ManageRegRequestsPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
