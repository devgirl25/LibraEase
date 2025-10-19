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

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _initializeStats();
    }
  }

  /// Calculates and stores stats in Firestore under users/{uid}/stats/latest
  Future<void> _initializeStats() async {
    if (user == null) return;

    final uid = user!.uid;
    final firestore = FirebaseFirestore.instance;

    try {
      // Fetch wishlist
      final wishlistSnap = await firestore
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .get();

      // Fetch borrow requests
      final borrowSnap = await firestore
          .collection('borrow_requests')
          .where('userId', isEqualTo: uid)
          .get();

      int ebooksReadCount = 0;
      int overdueCount = 0;
      double fineTotal = 0.0;
      const double finePerDay = 15.0;
      final now = DateTime.now();

      for (var doc in borrowSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final dueDateRaw = data['dueDate'];

        DateTime? dueDate;
        if (dueDateRaw is Timestamp)
          dueDate = dueDateRaw.toDate();
        else if (dueDateRaw is String) dueDate = DateTime.tryParse(dueDateRaw);

        if (status == 'returned') {
          ebooksReadCount++;
        } else if (status == 'accepted' &&
            dueDate != null &&
            dueDate.isBefore(now)) {
          overdueCount++;
          final daysOverdue = now.difference(dueDate).inDays;
          if (daysOverdue > 0) fineTotal += daysOverdue * finePerDay;
        }
      }

      // Store stats in Firestore
      await firestore
          .collection('users')
          .doc(uid)
          .collection('stats')
          .doc('latest')
          .set({
        'ebooksRead': ebooksReadCount,
        'wishlist': wishlistSnap.docs.length,
        'overdue': overdueCount,
        'fineTotal': fineTotal,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ Error initializing stats: $e');
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
              _buildStatisticsCard(),
              const SizedBox(height: 30),
              _buildLogoutButton(),
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCard() {
    final uid = user!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('stats')
          .doc('latest')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() ??
            {
              'ebooksRead': 0,
              'wishlist': 0,
              'overdue': 0,
              'fineTotal': 0.0,
            };

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
                      value: (data['ebooksRead'] ?? 0).toString(),
                      label: 'Books Read',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.playlist_add_check,
                      value: (data['wishlist'] ?? 0).toString(),
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
                      icon: Icons.timer_off_outlined,
                      value: (data['overdue'] ?? 0).toString(),
                      label: 'Overdue Books',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.money_off,
                      value:
                          '₹${(data['fineTotal'] ?? 0.0).toStringAsFixed(2)}',
                      label: 'Fines',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginStudentScreen()),
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
    );
  }
}
