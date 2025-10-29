import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_service.dart';
import 'browse_books_page.dart';
import 'ebooks_page.dart';
import 'borrow_history_page.dart';
import 'registrations_page.dart';
import 'Wishlist_page.dart';
import 'Profile_page.dart';
import '../logins/login_page_student.dart';
import 'dart:ui';

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
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.startPeriodicNotificationCheck();
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
    if (_isNavigating || index == 0) return;
    _isNavigating = true;
    setState(() => _selectedIndex = index);

    Widget? nextPage;
    switch (index) {
      case 1:
        nextPage = const BrowseBooksPage();
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
    return Container(
      decoration: BoxDecoration(
        color: kPrimaryBrown.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
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
              Text(
                'LibraEase',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kLightCream,
                ),
              ),
              Text(
                'Welcome, ${email.split('@').first}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: kLightCream,
                ),
              ),
            ],
          ),
        ],
      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBrown.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: kPrimaryBrown, size: 24),
            const SizedBox(width: 15),
            Text(
              'Search Books ...',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16.5,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.97),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: kPrimaryBrown,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: kPrimaryBrown,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                height: 1.2,
              ),
            ),
            Icon(
              backgroundIcon,
              size: 35,
              color: kScaffoldBackground.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: kPrimaryBrown.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: kPrimaryBrown,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.auto_stories_outlined, 1),
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
            ? kLightCream
            : kLightCream.withOpacity(0.6),
        size: 30,
      ),
      onPressed: () => _onItemTapped(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      body: Stack(
        children: [
          // ✅ Background image (lighter overlay for better release rendering)
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bkgd.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.08),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) =>
                  Container(color: kScaffoldBackground),
            ),
          ),

          // ✅ Subtle blur only (no strong gradient overlay)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
              child: Container(color: Colors.transparent),
            ),
          ),

          // ✅ Main content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 30),
                        _buildSearchBar(),
                        const SizedBox(height: 30),
                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kLightCream,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 1.0,
                          children: <Widget>[
                            _buildMenuCard(
                              context: context,
                              icon: Icons.menu_book_outlined,
                              title: 'E-BOOKS',
                              backgroundIcon: Icons.book_online_sharp,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const EBooksPage()),
                                );
                              },
                            ),
                            _buildMenuCard(
                              context: context,
                              icon: Icons.book_outlined,
                              title: 'PHYSICAL BOOKS',
                              backgroundIcon: Icons.auto_stories,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const BrowseBooksPage()),
                                );
                              },
                            ),
                            _buildMenuCard(
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
                            _buildMenuCard(
                              context: context,
                              icon: Icons.history,
                              title: 'BORROW HISTORY',
                              backgroundIcon: Icons.history,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const BorrowHistoryPage()),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _signOut(context),
                            icon: const Icon(Icons.logout, size: 20),
                            label: Text(
                              "SIGN OUT",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kLightCream.withOpacity(0.95),
                              foregroundColor: kPrimaryBrown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildBottomNavBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
