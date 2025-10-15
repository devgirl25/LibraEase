import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF255A5A),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Icon(Icons.home, color: Colors.white, size: 30),
    );
  }
}
