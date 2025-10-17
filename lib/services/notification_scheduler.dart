import 'dart:async';
import 'notificationservice.dart';

/// Service to schedule and check for notifications
/// This runs periodic checks for due dates and overdue books
class NotificationScheduler {
  static NotificationScheduler? _instance;
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();

  // Singleton pattern
  NotificationScheduler._();

  static NotificationScheduler get instance {
    _instance ??= NotificationScheduler._();
    return _instance!;
  }

  /// Start the notification scheduler
  /// Checks every hour for due date reminders and overdue books
  void start() {
    // Initial check
    _checkNotifications();

    // Schedule periodic checks every hour
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkNotifications();
    });

    print('✅ Notification scheduler started');
  }

  /// Stop the notification scheduler
  void stop() {
    _timer?.cancel();
    _timer = null;
    print('🛑 Notification scheduler stopped');
  }

  /// Check for notifications that need to be sent
  Future<void> _checkNotifications() async {
    try {
      print('🔔 Checking for notifications...');

      // Check for due date reminders (3 days before due)
      await _notificationService.checkAndSendDueDateReminders();

      // Check for overdue books
      await _notificationService.checkAndSendOverdueNotifications();

      print('✅ Notification check completed');
    } catch (e) {
      print('❌ Error checking notifications: $e');
    }
  }

  /// Manually trigger a notification check (useful for testing)
  Future<void> triggerManualCheck() async {
    await _checkNotifications();
  }
}
