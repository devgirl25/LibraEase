import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'browse_books_page.dart';
import 'ebooks_page.dart';
import 'borrow_history_page.dart';
import 'registrations_page.dart';
import 'previous_papers_page.dart';
import 'Wishlist_page.dart';
import 'notifications_page.dart';
import 'Profile_page.dart';
import '../logins/login_page_student.dart';

// --- CONSTANT COLORS ---
const Color kPrimaryBrown = Color.fromARGB(255, 87, 36, 14);
const Color kLightCream = Color.fromARGB(255, 245, 235, 220);
const Color kScaffoldBackground = Color.fromARGB(255, 210, 189, 166);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = 0;
  bool _isNavigating = false;
  final User? user = FirebaseAuth.instance.currentUser;

  final AssetImage backgroundImage =
      const AssetImage("assets/images/forgot_password/library.png");

  @override
  void initState() {
    super.initState();
    // ✅ Preload background image to prevent frame drops
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(backgroundImage, context);
    });
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginStudentScreen()),
    );
  }

  Future<void> _onItemTapped(int index) async {
    if (_isNavigating) return;
    _isNavigating = true;

    setState(() => _selectedIndex = index);

    Widget? nextPage;
    switch (index) {
      case 1:
        nextPage =  NotificationsPage();
        break;
      case 2:
        nextPage = const WishlistPage();
        break;
      case 3:
        nextPage = const ProfilePage();
        break;
    }

    if (nextPage != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => nextPage!),
      );
    }

    if (mounted) setState(() => _selectedIndex = 0);
    _isNavigating = false;
  }

  Widget _buildHeader() {
    final email = user?.email ?? 'Guest User';
    return Row(
      children: [
        Image.asset(
          'assets/images/splash_screen/library_icon.png',
          color: kLightCream,
          width: 40,
          height: 40,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.school, color: kLightCream, size: 40),
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BrowseBooksPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: kPrimaryBrown),
            const SizedBox(width: 12),
            Text(
              'Search books or e-resources...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
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
    super.build(context); // needed for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              image: DecorationImage(
                image: backgroundImage,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  kPrimaryBrown.withOpacity(0.8),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                          const SizedBox(height: 32),

                          // Row 1
                          Row(
                            children: [
                              Expanded(
                                child: _buildMenuCard(
                                  context: context,
                                  icon: Icons.menu_book_outlined,
                                  title: 'BROWSE\nE-BOOKS',
                                  backgroundIcon: Icons.book_online_sharp,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const EBooksPage()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMenuCard(
                                  context: context,
                                  icon: Icons.book_outlined,
                                  title: 'BROWSE\nBOOKS',
                                  backgroundIcon: Icons.auto_stories,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const BrowseBooksPage()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Row 2
                          Row(
                            children: [
                              Expanded(
                                child: _buildMenuCard(
                                  context: context,
                                  icon: Icons.app_registration,
                                  title: 'REGISTRATIONS',
                                  backgroundIcon: Icons.edit_document,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegistrationsPage()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMenuCard(
                                  context: context,
                                  icon: Icons.description_outlined,
                                  title: 'PREVIOUS\nYEAR PAPERS',
                                  backgroundIcon: Icons.find_in_page,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const PreviousPapersPage()),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Wide Card
                          _buildWideMenuCard(
                            context: context,
                            icon: Icons.history,
                            title: 'BORROW HISTORY',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const BorrowHistoryPage()),
                              );
                            },
                          ),
                          const SizedBox(height: 32),

                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => _signOut(context),
                              icon: const Icon(Icons.logout),
                              label: const Text("Sign Out"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kLightCream.withOpacity(0.9),
                                foregroundColor: kPrimaryBrown,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
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
