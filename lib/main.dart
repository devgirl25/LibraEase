import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/Splash_screen.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore import

// ✅ Global Firestore instance
late FirebaseFirestore db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Initialize Firestore
  db = FirebaseFirestore.instance;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
