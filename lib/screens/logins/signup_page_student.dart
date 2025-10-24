import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wrapper.dart'; // Navigate here after successful signup
import 'login_page_student.dart';

class SignupStudentScreen extends StatefulWidget {
  const SignupStudentScreen({super.key});

  @override
  State<SignupStudentScreen> createState() => _SignupStudentScreenState();
}

class _SignupStudentScreenState extends State<SignupStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    idController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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

  // Helper widget for stylized text input fields
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      validator: validator,
    );
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      try {
        // 1. Create user in Firebase Authentication
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        User? user = userCredential.user;

        // 2. Store extra user details in Firestore
        if (user != null) {
          // You might need to change the Firestore collection path depending on your security rules.
          // Using a general 'users' collection here.
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .set({
            "uid": user.uid,
            "name": nameController.text.trim(),
            "email": emailController.text.trim(),
            "studentId": idController.text.trim(),
            "role": "student",
            "createdAt": FieldValue.serverTimestamp(),
          });
        }

        // 3. Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created for ${nameController.text}!'),
            backgroundColor: Colors.green,
          ),
        );

        // 4. Navigate to the Wrapper/Home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Wrapper()),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Signup failed.';
        if (e.code == 'email-already-in-use') {
          message = 'This email is already in use.';
        } else if (e.code == 'weak-password') {
          message = 'The password is too weak.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is invalid.';
        } else {
          message = e.message ?? 'An unknown error occurred.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An unexpected error occurred: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 210, 189, 166),
      body: Stack(
        children: [
          // Background decorative circles
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

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 50),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'Signup Form',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 30),

                    // Student indicator box
                    Container(
                      height: 40,
                      width: 180,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.brown[900],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text('Student',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(height: 30),

                    // Input Fields
                    _inputField(
                        controller: nameController,
                        hint: 'Name',
                        icon: Icons.person,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter your name' : null),
                    const SizedBox(height: 20),
                    _inputField(
                        controller: emailController,
                        hint: 'Email',
                        icon: Icons.email,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter email';
                          if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")
                              .hasMatch(v)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        }),
                    const SizedBox(height: 20),
                    _inputField(
                        controller: idController,
                        hint: 'Student ID',
                        icon: Icons.badge,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter Student ID' : null),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password (min 6 characters)',
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6
                          ? 'Password must be 6+ characters'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Confirm your password'
                          : null,
                    ),
                    const SizedBox(height: 30),

                    // Sign Up Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[900],
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _signup,
                      child: const Text('Sign Up'),
                    ),
                    const SizedBox(height: 20),

                    // Login Link
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginStudentScreen()),
                        );
                      },
                      child: const Text(
                        'Already a member? Login now',
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
