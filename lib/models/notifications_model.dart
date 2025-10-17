import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool read;
  final String type;
  final DateTime? timestamp;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      read: map['read'] ?? false,
      type: map['type'] ?? 'general',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      data: map,
    );
  }
}
