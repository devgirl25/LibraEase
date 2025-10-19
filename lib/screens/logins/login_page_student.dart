import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Signup_page_student.dart';
import 'Forgot_password.dart';
import '../studenthomepage/Home_page.dart';
import 'Select_user_type.dart';

class LoginStudentScreen extends StatefulWidget {
  const LoginStudentScreen({super.key});

  @override
  State<LoginStudentScreen> createState() => _LoginStudentScreenState();
}

class _LoginStudentScreenState extends State<LoginStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 🌟 Custom Styled SnackBar
  void showCustomSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    final color = isError ? const Color(0xFFB71C1C) : const Color(0xFF255A5A);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError
                  ? [const Color(0xFFD32F2F), const Color(0xFFB71C1C)]
                  : [const Color(0xFF4E7D7D), const Color(0xFF255A5A)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 🔐 Login function
  void _login() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.brown),
        ),
      );

      try {
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pop(context);

        if (credential.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );

          showCustomSnackBar(
              context, '🎉 Login successful! Welcome back to LibraEase.');
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        Navigator.pop(context);

        String message;
        switch (e.code) {
          case 'network-request-failed':
            message = 'No Internet connection. Please check your network.';
            break;
          case 'user-not-found':
            message = 'No user found for that email.';
            break;
          case 'wrong-password':
            message = 'Wrong password provided.';
            break;
          case 'invalid-email':
            message = 'Invalid email format.';
            break;
          case 'user-disabled':
            message = 'This account has been disabled.';
            break;
          default:
            message = e.message ?? 'Login failed. Please try again.';
        }

        showCustomSnackBar(context, message, isError: true);
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);

        String errorMessage;
        if (e.toString().contains('network') ||
            e.toString().contains('SocketException')) {
          errorMessage = 'No Internet connection. Please check your network.';
        } else {
          errorMessage = 'Unexpected error occurred: $e';
        }

        showCustomSnackBar(context, errorMessage, isError: true);
      }
    }
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 210, 189, 166),
      body: Stack(
        children: [
          // Decorative circles
          Positioned(
              left: -50,
              top: -30,
              child: _circle(250, const Color.fromARGB(30, 129, 69, 17))),
          Positioned(right: 85, top: 90, child: _circle(50, Colors.white)),
          Positioned(
              right: 80,
              top: 80,
              child: _circle(80, const Color.fromARGB(110, 105, 56, 12))),
          Positioned(
              right: -50,
              bottom: -80,
              child: _circle(200, const Color.fromARGB(90, 129, 69, 17))),
          Positioned(left: -35, bottom: 60, child: _circle(70, Colors.white)),
          Positioned(
              left: -45,
              bottom: 50,
              child: _circle(100, const Color.fromARGB(90, 129, 69, 17))),

          // Back arrow
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 28, color: Colors.brown),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SelectUserTypeScreen()),
                );
              },
            ),
          ),

          // Main login form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Login Form',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Student label
                    Container(
                      height: 40,
                      width: 180,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.brown[900],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Student',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email field
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter email';
                        }
                        if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                            .hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter password'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style:
                              TextStyle(color: Color.fromARGB(255, 87, 36, 14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Login button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[900],
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 20),

                    // Signup link
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const SignupStudentScreen()),
                        );
                      },
                      child: const Text(
                        'Not a member? Signup now',
                        style: TextStyle(
                          color: Color.fromARGB(255, 87, 36, 14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
