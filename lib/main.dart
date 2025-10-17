import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/logins/splash_screen.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore import
import 'services/notification_scheduler.dart'; // ✅ Notification scheduler

// ✅ Global Firestore instance
late FirebaseFirestore db;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Initialize Firestore
  db = FirebaseFirestore.instance;

  // ✅ Start notification scheduler for due date reminders
  NotificationScheduler.instance.start();

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
