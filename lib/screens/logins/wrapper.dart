import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../studenthomepage/Home_page.dart';
import 'login_page_student.dart' as Login;

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is logged in
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const Login.LoginStudentScreen();
          }
        }

        // While checking auth state, show loading
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
