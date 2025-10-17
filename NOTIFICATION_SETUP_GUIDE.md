# Notification System - Quick Setup Guide

## What's Been Added

### New Files Created:
1. `lib/services/notification_manager.dart` - Core notification service
2. `lib/services/notification_scheduler.dart` - Automated notification scheduler
3. `lib/screens/studenthomepage/notifications_page_enhanced.dart` - Enhanced notifications UI
4. `NOTIFICATION_SYSTEM.md` - Complete documentation

### Modified Files:
1. `lib/services/borrow_service.dart` - Integrated with notification manager
2. `lib/screens/studenthomepage/home_page.dart` - Added notification badge counter
3. `lib/main.dart` - Initialized notification scheduler

## Features Implemented

### ✅ 12 Notification Types
1. Due Date Reminders (3 days, 1 day, day of due date)
2. Overdue Book Alerts (daily after due date)
3. Borrow Success Notifications
4. Borrow Approved/Rejected Notifications
5. Book Renewed Notifications
6. Book Returned Notifications
7. Registration Approved/Rejected Notifications
8. New Book Available Notifications
9. Wishlist Book Available Notifications
10. Library Announcements

### ✅ UI Features
- **Notification Badge**: Red badge on home page navigation showing unread count
- **Swipe to Delete**: Swipe left on notifications to delete
- **Mark as Read**: Tap to mark individual notifications as read
- **Mark All as Read**: Button to mark all notifications as read
- **Delete All**: Option to delete all notifications
- **Notification Icons**: Different colored icons for each notification type
- **Relative Timestamps**: Shows "5m ago", "2h ago", etc.
- **Action Buttons**: Contextual actions like "Renew Book", "Borrow Now"

### ✅ Automated Scheduler
- Checks for due date reminders every 6 hours
- Checks for overdue books every 12 hours
- Runs initial check on app start
- Prevents duplicate notifications

## How It Works

### 1. Automatic Notifications (Already Working)
When students borrow, renew, or return books through the app, notifications are automatically sent via the `BorrowService`.

```dart
// Example: When a student borrows a book
await borrowService.borrowBook(
  bookId: 'book123',
  bookTitle: 'Clean Code',
  userId: 'user123',
  borrowDays: 14,
);
// ✅ Automatically sends "Book Borrowed Successfully" notification
```

### 2. Scheduled Notifications (Background)
The `NotificationScheduler` automatically checks for:
- Books due in 3 days → Sends reminder
- Books due in 1 day → Sends urgent reminder
- Books due today → Sends final reminder
- Books overdue → Sends overdue alert (daily)

### 3. Badge Counter (Real-time)
The home page navigation bar shows a red badge with the count of unread notifications. It updates in real-time as notifications are read or received.

## Testing the Notification System

### Test Scenario 1: Manual Notification
```dart
// Add this code temporarily in any page to test
import '../../services/notification_manager.dart';

final notificationManager = NotificationManager();

// Test button
ElevatedButton(
  onPressed: () async {
    await notificationManager.sendLibraryAnnouncementNotification(
      userId: FirebaseAuth.instance.currentUser!.uid,
      title: 'Test Notification',
      message: 'This is a test notification to verify the system is working!',
    );
  },
  child: const Text('Send Test Notification'),
)
```

### Test Scenario 2: Due Date Reminder
1. Create a borrowed book in Firestore with a due date 3 days from now:
```javascript
// In Firestore Console
users/{userId}/borrow_history
{
  "bookId": "test123",
  "bookTitle": "Test Book",
  "borrowDate": <today>,
  "dueDate": <3 days from now>,
  "status": "borrowed"
}
```
2. Wait for scheduler to run (6 hours) OR trigger manual check:
```dart
await NotificationScheduler().runManualCheck();
```
3. Check notifications page - should see due date reminder

### Test Scenario 3: Overdue Book
1. Create a borrowed book with past due date:
```javascript
users/{userId}/borrow_history
{
  "bookId": "test123",
  "bookTitle": "Overdue Test Book",
  "borrowDate": <10 days ago>,
  "dueDate": <3 days ago>,
  "status": "borrowed"
}
```
2. Trigger manual check or wait for scheduler
3. Should receive overdue notification

### Test Scenario 4: Badge Counter
1. Send multiple notifications (use test scenario 1)
2. Go to home page - check navigation bar
3. Badge should show count of unread notifications
4. Tap notifications icon, mark some as read
5. Badge count should decrease automatically

## Admin: Sending Bulk Notifications

To send announcements to all students:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_manager.dart';

Future<void> sendAnnouncementToAllStudents({
  required String title,
  required String message,
}) async {
  final notificationManager = NotificationManager();
  final firestore = FirebaseFirestore.instance;

  // Get all students
  final usersSnapshot = await firestore
      .collection('users')
      .where('role', isEqualTo: 'student')
      .get();

  // Send notification to each student
  for (var userDoc in usersSnapshot.docs) {
    await notificationManager.sendLibraryAnnouncementNotification(
      userId: userDoc.id,
      title: title,
      message: message,
    );
  }
}

// Usage:
await sendAnnouncementToAllStudents(
  title: 'Library Closed Tomorrow',
  message: 'The library will be closed tomorrow for maintenance.',
);
```

## Firestore Security Rules

Add these rules to your Firestore to secure notifications:

```javascript
// In Firebase Console > Firestore > Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... existing rules ...

    match /users/{userId}/notifications/{notificationId} {
      // Students can read and update their own notifications
      allow read, update: if request.auth.uid == userId;

      // System can create notifications (via admin SDK or Cloud Functions)
      allow create: if request.auth != null;

      // Students can delete their own notifications
      allow delete: if request.auth.uid == userId;
    }
  }
}
```

## Optional: Using the Enhanced Notifications Page

To use the enhanced notifications page with better UI:

1. Open `lib/screens/studenthomepage/home_page.dart`
2. Find the import for `notifications_page.dart`
3. Change it to:
```dart
import 'notifications_page_enhanced.dart';
```
4. Update the navigation:
```dart
case 1:
  nextPage = NotificationsPageEnhanced(); // Instead of NotificationsPage()
  break;
```

## Monitoring & Maintenance

### Check Notification Logs
The scheduler logs its activity to the console:
```
Starting notification scheduler...
Running initial notification check...
Checking for due date reminders...
Due date reminder check completed
```

### Manual Trigger for Testing
```dart
// Add a debug button in admin panel
ElevatedButton(
  onPressed: () async {
    await NotificationScheduler().runManualCheck();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual notification check completed')),
    );
  },
  child: const Text('Run Notification Check'),
)
```

### Stop Scheduler (if needed)
```dart
NotificationScheduler().stopScheduler();
```

### Check Scheduler Status
```dart
bool isRunning = NotificationScheduler().isRunning;
print('Scheduler running: $isRunning');
```

## Troubleshooting

### Problem: Notifications not showing up
**Solution:**
1. Check if user is logged in: `FirebaseAuth.instance.currentUser != null`
2. Verify Firestore rules allow reads
3. Check console for errors
4. Verify notification was created in Firestore Console

### Problem: Badge count not updating
**Solution:**
1. Restart the app to reinitialize listeners
2. Check if `_listenToNotifications()` is being called in `initState()`
3. Verify Firestore connection

### Problem: Duplicate notifications
**Solution:**
- The system prevents duplicates using `lastReminderSent` tracking
- If still occurring, check if scheduler is being started multiple times

### Problem: Scheduler not running
**Solution:**
1. Check `main.dart` has `NotificationScheduler().startScheduler()`
2. Verify Firebase is initialized before scheduler starts
3. Check console for error messages

## Production Recommendations

### 1. Use Cloud Functions
For production, implement the scheduler as Firebase Cloud Functions:
- More reliable than app-based scheduler
- Runs even when app is closed
- Better for battery life

### 2. Implement Push Notifications
Add Firebase Cloud Messaging (FCM) for:
- Notifications when app is closed
- Better user engagement
- Immediate delivery

### 3. Add Notification Preferences
Let users customize:
- Which notification types to receive
- Notification timing preferences
- Email vs in-app notifications

### 4. Analytics
Track notification engagement:
- Open rates
- Click-through rates
- Most effective notification types

## Summary

✅ **What's Working:**
- All 12 notification types implemented
- Automated scheduler for due dates and overdue books
- Real-time badge counter on home page
- Enhanced UI with swipe-to-delete and actions
- Integration with existing borrow service

🎯 **Next Steps:**
1. Test the notification system with real data
2. Adjust scheduler intervals if needed
3. Consider implementing Cloud Functions for production
4. Add push notifications for better reach
5. Gather user feedback and refine

📚 **Documentation:**
- Full API reference: `NOTIFICATION_SYSTEM.md`
- Firestore structure: `FIRESTORE_STRUCTURE.md`
- Student features: `STUDENT_FEATURES_SUMMARY.md`

The notification system is now fully functional and ready to use!
