import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/logins/splash_screen.dart';
import 'services/notification_service.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/push_notification_service.dart';
import 'screens/studenthomepage/home_page.dart';
import 'screens/studenthomepage/browse_books_page.dart';

late FirebaseFirestore db;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Firestore
  db = FirebaseFirestore.instance;

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();

    // Start periodic notification checking every hour
    _notificationTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      NotificationService().checkAndSendDueDateNotifications();
    });

    // Initialize push notifications with navigatorKey
    PushNotificationService().init(navigatorKey);
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey, // needed for SnackBars on FCM messages
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      // home: HomePage(),
      //home: const BrowseBooksPage(),
    );
  }
}
