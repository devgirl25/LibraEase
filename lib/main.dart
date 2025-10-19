import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/logins/splash_screen.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/notification_service.dart';
import 'dart:async';

late FirebaseFirestore db;
Timer? _notificationTimer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  db = FirebaseFirestore.instance;

  // Start periodic notification checking every hour
  _notificationTimer = Timer.periodic(const Duration(hours: 1), (timer) {
    NotificationService().checkAndSendDueDateNotifications();
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
