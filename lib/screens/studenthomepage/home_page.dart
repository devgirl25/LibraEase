import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'browse_books_page.dart';
import 'ebooks_page.dart';
import 'borrow_history_page.dart';
import 'registrations_page.dart';
import 'previous_papers_page.dart';
import 'Wishlist_page.dart';
import 'notifications_page.dart';
import 'Profile_page.dart';
import '../logins/login_page_student.dart';
import '../../services/notificationservice.dart';

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

  // Reduced image path for brevity, assuming it's correct
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
    if (_isNavigating || index == 0) {
      return; // Ignore if already navigating or index is home
    }
    _isNavigating = true;

    setState(() => _selectedIndex = index);

    Widget? nextPage;
    switch (index) {
      case 1:
        nextPage = NotificationsPage();
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

    // Reset selection to Home (index 0) after returning from another page
    if (mounted) setState(() => _selectedIndex = 0);
    _isNavigating = false;
  }

  // --- CONSTANT COLORS (for context) ---
// const Color kPrimaryBrown = Color.fromARGB(255, 87, 36, 14);
// const Color kLightCream = Color.fromARGB(255, 245, 235, 220);

  Widget _buildHeader() {
    final email = user?.email ?? 'Guest User';
    return Container(
      // 🎨 Apply kPrimaryBrown background and rounded corners
      decoration: BoxDecoration(
        color: kPrimaryBrown.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
      ),
      // Increased left padding to push content further right from the edge
      padding: const EdgeInsets.only(left: 20, right: 16, top: 12, bottom: 12),
      child: Row(
        // The default mainAxisAlignment is MainAxisAlignment.start,
        // which aligns content to the left.
        // Removed mainAxisSize: MainAxisSize.min to allow it to stretch full width.
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(15), // Slightly larger border radius
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
              'Search books or e-resources...',
              style: TextStyle(
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: MediaQuery.of(context).size.width /
              2.5, // Fixed height based on screen width
          padding: const EdgeInsets.all(12),
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
                style: const TextStyle(
                  color: kPrimaryBrown,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  height: 1.2,
                ),
              ),
              // Moved the background icon out for a cleaner look or removed it,
              // but I'll keep the small ghosted one inside for a subtle effect
              Icon(
                backgroundIcon,
                size: 35,
                color: kScaffoldBackground, // Use a less intrusive color
              ),
            ],
          ),
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
        height: 80, // Increased height for better visibility
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
        child: Row(
          children: [
            const SizedBox(width: 20),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: kPrimaryBrown,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                color: kPrimaryBrown,
                fontWeight: FontWeight.w800,
                fontSize: 17, // Increased font size
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      // The padding is now on the outside of the `Container` for the box shadow
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: kPrimaryBrown.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
          16, 8, 16, 16), // Padding for the safe area bottom
      child: Container(
        height: 60, // Slightly reduced height to look sleeker
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
    // Show notification badge on notifications icon (index 1)
    if (index == 1 && user != null) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('notifications')
            .where('read', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          final unreadCount =
              snapshot.hasData ? snapshot.data!.docs.length : 0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  icon,
                  color: _selectedIndex == index
                      ? kLightCream
                      : kLightCream.withOpacity(0.6),
                  size: 30,
                ),
                onPressed: () => _onItemTapped(index),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index
            ? kLightCream // White is a better highlight
            : kLightCream.withOpacity(0.6),
        size: 30, // Slightly larger icon
      ),
      onPressed: () => _onItemTapped(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // needed for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      body: Container(
        // The main container now fills the entire screen
        decoration: BoxDecoration(
          image: DecorationImage(
            image: backgroundImage,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              kPrimaryBrown.withOpacity(0.8),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      24, 24, 24, 0), // Generous padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 30),
                      _buildSearchBar(),
                      const SizedBox(height: 30),

                      // Grid for main menu cards
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
                        childAspectRatio: 1.0, // Ensures square cards for menu
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
                                    builder: (_) => const RegistrationsPage()),
                              );
                            },
                          ),
                          _buildMenuCard(
                            context: context,
                            icon: Icons.description_outlined,
                            title: 'PREVIOUS PAPERS',
                            backgroundIcon: Icons.find_in_page,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PreviousPapersPage()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        'Your Activity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kLightCream,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Wide Card - Borrow History
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
                      const SizedBox(height: 30),

                      // Sign Out Button
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _signOut(context),
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text("SIGN OUT",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kLightCream.withOpacity(0.9),
                            foregroundColor: kPrimaryBrown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // Extra space above nav bar
                    ],
                  ),
                ),
              ),
              // Bottom Navigation Bar is now outside the SingleChildScrollView
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }
}
