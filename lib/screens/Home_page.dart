import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Note: In a real app, these imports would be separate files.
// They are mocked below for a single-file environment.
// import 'constants.dart';
// import 'notifications_page.dart';
// import 'wishlist_page.dart';
// import 'profile_page.dart';
// import 'login_page_student.dart';

// --- MOCK CONSTANTS (Assuming colors based on context) ---
const Color kPrimaryBrown = Color.fromARGB(255, 87, 36, 14);
const Color kLightCream = Color.fromARGB(255, 245, 235, 220);
const Color kScaffoldBackground = Color.fromARGB(255, 210, 189, 166);

// --- MOCK NAVIGATION PAGES ---
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications Content')));
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Wishlist/Bookmarks')),
      body: const Center(child: Text('Wishlist Content')));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Content')));
}

class LoginStudentScreen extends StatelessWidget {
  const LoginStudentScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Login Screen Mock')),
      body: const Center(child: Text('Returned to Login.')));
}
// -----------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // After sign out, navigate back to login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginStudentScreen()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationsPage()),
      ).then((_) => setState(() => _selectedIndex = 0)); // Reset tab on return
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WishlistPage()),
      ).then((_) => setState(() => _selectedIndex = 0));
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      ).then((_) => setState(() => _selectedIndex = 0));
    }
  }

  // Helper widget for the header displaying user info
  Widget _buildHeader() {
    final email = user?.email ?? 'Guest User';
    return Row(
      children: [
        Image.asset(
          // Using a common placeholder icon if the asset path is invalid
          'assets/images/splash_screen/library_icon.png',
          color: kLightCream,
          width: 40,
          height: 40,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.school,
            color: kLightCream,
            size: 40,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LibraEase',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kLightCream,
              ),
            ),
            Text(
              'Welcome, ${email.split('@').first}',
              style: const TextStyle(
                fontSize: 14,
                color: kLightCream,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: kPrimaryBrown),
          hintText: 'Search books or e-resources...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required IconData backgroundIcon,
    required VoidCallback onTap,
  }) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              top: 25,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kPrimaryBrown,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Icon(
                      backgroundIcon,
                      size: 40,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: kPrimaryBrown,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 20,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: kPrimaryBrown,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 85.0),
              child: Text(
                title,
                style: const TextStyle(
                  color: kPrimaryBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 10, right: 10),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: kPrimaryBrown,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.notifications, 1),
            _buildNavItem(Icons.bookmark, 2),
            _buildNavItem(Icons.account_circle, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index
            ? Colors.white
            : kLightCream.withOpacity(0.6),
        size: 28,
      ),
      onPressed: () => _onItemTapped(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              image: DecorationImage(
                // This asset path must be valid in your project setup
                image: const AssetImage(
                    "assets/images/forgot_password/library.png"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  kPrimaryBrown.withOpacity(0.85),
                  BlendMode.darken,
                ),
                // Add error handling for the background image
                onError: (exception, stackTrace) => const SizedBox(),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                          const SizedBox(height: 32),

                          // Row 1: E-Books & Books
                          Row(
                            children: [
                              Expanded(
                                child: _buildMenuCard(
                                  context: context,
                                  icon: Icons.menu_book_outlined,
                                  title: 'BROWSE\nE-BOOKS',
                                  backgroundIcon: Icons.book_online_sharp,
                                  onTap: () => print('Browse E-Books Tapped'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMenuCard(
                                  context: context,
                                  icon: Icons.book_outlined,
                                  title: 'BROWSE\nBOOKS',
                                  backgroundIcon: Icons.auto_stories,
                                  onTap: () => print('Browse Books Tapped'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Row 2: Registrations & Previous Papers
                          Row(
                            children: [
                              Expanded(
                                child: _buildMenuCard(
                                  context: context,
                                  icon: Icons.app_registration,
                                  title: 'REGISTRATIONS',
                                  backgroundIcon: Icons.edit_document,
                                  onTap: () => print('Registrations Tapped'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMenuCard(
                                  context: context,
                                  icon: Icons.description_outlined,
                                  title: 'PREVIOUS\nYEAR PAPERS',
                                  backgroundIcon: Icons.find_in_page,
                                  onTap: () =>
                                      print('Previous Year Papers Tapped'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Wide Card: Borrow History
                          _buildWideMenuCard(
                            context: context,
                            icon: Icons.history,
                            title: 'BORROW HISTORY',
                            onTap: () => print('Borrow History Tapped'),
                          ),
                          const SizedBox(height: 32),

                          // Sign Out Button (Replaces simple button from original Firebase file)
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _signOut(context),
                              icon: const Icon(Icons.logout),
                              label: const Text("Sign Out"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kLightCream.withOpacity(0.9),
                                foregroundColor: kPrimaryBrown,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildBottomNavBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
