import 'package:flutter/material.dart';
import 'login_page_student.dart';
import 'login_page_admin.dart';

class SelectUserTypeScreen extends StatelessWidget {
  const SelectUserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 210, 189, 166),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                Transform.translate(
                  offset: const Offset(-80, -100),
                  child: const Text(
                    'Select User Type',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Student
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginStudentScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: _buildUserTypeBox(
                    imagePath: 'assets/images/select_user_type/student.png',
                    label: 'Student',
                  ),
                ),
                const SizedBox(height: 30),
                // Admin
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginAdminScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: _buildUserTypeBox(
                    imagePath: 'assets/images/select_user_type/admin.png',
                    label: 'Admin',
                  ),
                ),
              ],
            ),
          ),

          // Background circles
          Positioned(
            left: -50,
            top: -30,
            child: _circle(250, const Color.fromARGB(30, 129, 69, 17)),
          ),
          Positioned(
            right: 85,
            top: 90,
            child: _circle(50, const Color.fromARGB(255, 249, 249, 249)),
          ),
          Positioned(
            right: 80,
            top: 80,
            child: _circle(80, const Color.fromARGB(110, 105, 56, 12)),
          ),
          Positioned(
            right: -50,
            bottom: -80,
            child: _circle(200, const Color.fromARGB(90, 129, 69, 17)),
          ),
          Positioned(
            left: -35,
            bottom: 60,
            child: _circle(70, const Color.fromARGB(255, 250, 250, 250)),
          ),
          Positioned(
            left: -45,
            bottom: 50,
            child: _circle(100, const Color.fromARGB(90, 129, 69, 17)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeBox({required String imagePath, required String label}) {
    return Container(
      height: 150.0,
      width: 350.0,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: const Color.fromARGB(93, 129, 69, 17),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-80, 0),
            child: Image.asset(
              imagePath,
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
          Transform.translate(
            offset: const Offset(-20, 0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                color: Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
} 