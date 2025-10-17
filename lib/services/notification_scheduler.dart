import 'dart:async';
import 'package:flutter/foundation.dart';
import 'notification_manager.dart';

class NotificationScheduler {
  static final NotificationScheduler _instance =
      NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final NotificationManager _notificationManager = NotificationManager();
  Timer? _reminderTimer;
  Timer? _overdueTimer;
  bool _isRunning = false;

  void startScheduler() {
    if (_isRunning) {
      debugPrint('Notification scheduler is already running');
      return;
    }

    _isRunning = true;
    debugPrint('Starting notification scheduler...');

    _checkImmediately();

    _reminderTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => _checkDueDateReminders(),
    );

    _overdueTimer = Timer.periodic(
      const Duration(hours: 12),
      (_) => _checkOverdueBooks(),
    );

    debugPrint('Notification scheduler started successfully');
  }

  void stopScheduler() {
    if (!_isRunning) {
      debugPrint('Notification scheduler is not running');
      return;
    }

    _reminderTimer?.cancel();
    _overdueTimer?.cancel();
    _reminderTimer = null;
    _overdueTimer = null;
    _isRunning = false;

    debugPrint('Notification scheduler stopped');
  }

  void _checkImmediately() {
    debugPrint('Running initial notification check...');
    _checkDueDateReminders();
    _checkOverdueBooks();
  }

  Future<void> _checkDueDateReminders() async {
    try {
      debugPrint('Checking for due date reminders...');
      await _notificationManager.checkAndSendDueDateReminders();
      debugPrint('Due date reminder check completed');
    } catch (e) {
      debugPrint('Error checking due date reminders: $e');
    }
  }

  Future<void> _checkOverdueBooks() async {
    try {
      debugPrint('Checking for overdue books...');
      await _notificationManager.checkAndSendOverdueNotifications();
      debugPrint('Overdue book check completed');
    } catch (e) {
      debugPrint('Error checking overdue books: $e');
    }
  }

  Future<void> runManualCheck() async {
    debugPrint('Running manual notification check...');
    await _checkDueDateReminders();
    await _checkOverdueBooks();
    debugPrint('Manual check completed');
  }

  bool get isRunning => _isRunning;
}
