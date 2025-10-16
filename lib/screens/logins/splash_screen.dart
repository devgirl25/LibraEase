import 'package:flutter/material.dart';
import 'select_user_type.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SelectUserTypeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B2A23),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(14, 0),
              child: Image.asset(
                'assets/images/splash_screen/library_icon.png',
                height: 100,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "LibraEase",
              style: TextStyle(
                fontFamily: 'InknutAntiqua',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Bringing the Library to your Fingertips.",
              style: TextStyle(
                fontFamily: 'InknutAntiqua',
                fontSize: 14,
                color: Colors.white70,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
