import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Note: Email_verification.dart is no longer needed as Firebase handles
// sending the reset link directly to the user's email.

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // Helper widget for background circles
  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // Send password reset link using Firebase
  void _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: emailController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Password reset link sent to ${emailController.text.trim()}. Check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      } on FirebaseAuthException catch (e) {
        String message = e.message ?? 'Failed to send reset email. Ensure the email is registered.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 210, 189, 166),
      appBar: AppBar(
        // Styled AppBar
        backgroundColor: const Color.fromARGB(255, 180, 150, 120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Decorative circles (Styled background)
          Positioned(left: -50, top: -30, child: _circle(250, const Color.fromARGB(30, 129, 69, 17))),
          Positioned(right: 85, top: 90, child: _circle(50, Colors.white)),
          Positioned(right: 80, top: 80, child: _circle(80, const Color.fromARGB(110, 105, 56, 12))),
          Positioned(right: -50, bottom: -80, child: _circle(200, const Color.fromARGB(90, 129, 69, 17))),
          Positioned(left: -35, bottom: 60, child: _circle(70, Colors.white)),
          Positioned(left: -45, bottom: 50, child: _circle(100, const Color.fromARGB(90, 129, 69, 17))),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Enter your email address associated\nwith your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 30),

                    // Placeholder image (using Opacity for styling)
                    Opacity(
                      opacity: 0.2,
                      child: Image.asset(
                        // NOTE: This asset path must be valid in your project setup
                        'assets/images/forgot_password/library.png',
                        width: 200,
                        height: 150,
                        fit: BoxFit.contain,
                        // Providing a fallback if the image is not found
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.lock_reset, size: 100, color: Colors.brown);
                        },
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email field
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter email';
                        if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Send OTP Button (Triggers Firebase reset link)
                    ElevatedButton(
                      onPressed: _sendResetLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[900],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Send OTP'),
                    ),
                    const SizedBox(height: 20),

                    // Back to Login link
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Back to Login',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_right_alt, color: Colors.black87),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
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
