import 'package:flutter/material.dart';

class AdminInfo extends StatelessWidget {
  const AdminInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      color: const Color(0xFFF0F0F0),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFF255A5A),
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Admin",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text("Welcome to Dashboard",
                  style: TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
