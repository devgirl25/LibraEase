import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Call this after user login
  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    NotificationSettings settings = await _fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');

      // Get and save FCM token
      String? token = await _fcm.getToken();
      print('FCM Token: $token');
      if (token != null && FirebaseAuth.instance.currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'fcmToken': token});
        print('✅ FCM token saved to Firestore');
      }
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Foreground FCM received: ${message.notification?.title}');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save to Firestore for NotificationsPage
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': message.notification?.title ?? 'Notification',
        'message': message.notification?.body ?? '',
        'type': message.data['type'] ?? 'general',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Optional: show local toast/snackbar
      final context = navigatorKey.currentContext;
      if (context != null && message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${message.notification!.title}: ${message.notification!.body}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }
}
