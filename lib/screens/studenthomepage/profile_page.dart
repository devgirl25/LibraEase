import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logins/constants.dart';
import '../logins/login_page_student.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, int> stats = {
    'ebooksRead': 0,
    'wishlist': 0,
    'reviews': 0,
    'overdue': 0,
  };

  @override
  void initState() {
    super.initState();
    if (user != null) _fetchUserStats();
  }

  Future<void> _fetchUserStats() async {
    final uid = user!.uid;

    try {
      // Fetch Wishlist count
      final wishlistSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .get();

      // Fetch Reviews count (assuming a 'reviews' subcollection exists)
      final reviewsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('reviews')
          .get();

      // Fetch Ebooks read count (assuming a 'borrow_history' with 'returned' status)
      final borrowedSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('borrow_history')
          .where('status', isEqualTo: 'returned')
          .get();

      // Fetch overdue books (borrowed but past due date)
      final borrowedBooksSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('borrow_history')
          .where('status', isEqualTo: 'borrowed')
          .get();
      int overdueCount = borrowedBooksSnap.docs.where((doc) {
        final dueDate = (doc['dueDate'] as Timestamp).toDate();
        return dueDate.isBefore(DateTime.now());
      }).length;

      setState(() {
        stats['wishlist'] = wishlistSnap.docs.length;
        stats['reviews'] = reviewsSnap.docs.length;
        stats['ebooksRead'] = borrowedSnap.docs.length;
        stats['overdue'] = overdueCount;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: kScaffoldBackground,
        body: Center(child: Text('Please login to see your profile')),
      );
    }

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildUserInfoCard(),
              const SizedBox(height: 20),
              _buildStatisticsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: Container(
        decoration: const BoxDecoration(
          color: kPrimaryBrown,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Center(
            child: ListTile(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const Text('No user data found');
        }

        final data = snapshot.data!.data()!;
        final name = data['name'] ?? 'Unknown';
        final email = data['email'] ?? user!.email ?? '';
        final id = data['id'] ?? '';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1ED),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: kPrimaryBrown,
                  child: Icon(Icons.person, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kPrimaryBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: kPrimaryBrown.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      'ID: $id',
                      style: TextStyle(
                        fontSize: 14,
                        color: kPrimaryBrown.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPrimaryBrown,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.menu_book,
                  value: stats['ebooksRead'].toString(),
                  label: 'E-Books Read',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.playlist_add_check,
                  value: stats['wishlist'].toString(),
                  label: 'Wishlist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.edit,
                  value: stats['reviews'].toString(),
                  label: 'Reviews written',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer_off_outlined,
                  value: stats['overdue'].toString(),
                  label: 'Overdue books',
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginStudentScreen(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryBrown,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: const BorderSide(color: kPrimaryBrown),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: kPrimaryBrown, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kPrimaryBrown,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: kPrimaryBrown.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
