import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // Helper for decorative circles
  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // Success dialog
  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 70),
              const SizedBox(height: 20),
              const Text(
                'Link Sent!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'A password reset link has been sent to\n$email.\nPlease check your inbox.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Back to login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            const Text("Error", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  // Firebase password reset logic
  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: emailController.text.trim(),
        );

        setState(() => _isLoading = false);
        _showSuccessDialog(emailController.text.trim());
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.message ?? 'Failed to send reset email.');
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog('Something went wrong. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryBrown = Color.fromARGB(255, 87, 36, 14);
    const kLightCream = Color.fromARGB(255, 245, 235, 220);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: kLightCream,
          appBar: AppBar(
            backgroundColor: kPrimaryBrown,
            elevation: 0,
            title: const Text(
              'Forgot Password',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Stack(
            children: [
              // Background decorations
              Positioned(
                  left: -60,
                  top: -40,
                  child: _circle(220, const Color.fromARGB(25, 87, 36, 14))),
              Positioned(
                  right: -50,
                  bottom: -70,
                  child: _circle(200, const Color.fromARGB(40, 87, 36, 14))),

              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  child: Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Reset your password',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBrown,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Enter your registered email to receive a password reset link.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 30),

                          Image.asset(
                            'assets/images/forgot_password/library.png',
                            width: 140,
                            height: 100,
                            opacity: const AlwaysStoppedAnimation(0.8),
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.lock_reset,
                                    size: 80, color: Colors.brown),
                          ),
                          const SizedBox(height: 30),

                          // Email TextField
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              filled: true,
                              fillColor: kLightCream,
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your email';
                              }
                              if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                                  .hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 25),

                          // Send Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendResetLink,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryBrown,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Send Reset Link',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Back to login
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Back to Login',
                                  style: TextStyle(
                                    color: kPrimaryBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.arrow_right_alt,
                                    color: kPrimaryBrown),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.brown,
                strokeWidth: 4,
              ),
            ),
          ),
      ],
    );
  }
}
