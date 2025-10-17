# 📱 Student Notification System

## Overview

This document describes the comprehensive notification system implemented for the LibraEase library management system. Students receive timely notifications for various library activities including due date reminders, borrow request updates, and overdue book alerts.

## ✨ Features

### 1. **Automated Due Date Reminders**
- Students receive a reminder **3 days before** the book due date
- Notifications include book title and exact due date
- Reminders are sent only once per borrowing period
- Icon: 🕐 Orange clock icon

### 2. **Overdue Book Notifications**
- Daily notifications for overdue books
- Shows number of days overdue
- Continues until book is returned
- Icon: ⚠️ Red warning icon

### 3. **Borrow Request Status Updates**
- **Request Submitted**: Confirmation when request is placed
- **Request Approved**: Notification with due date when admin approves
- **Request Rejected**: Notification with reason (if provided)
- Icons: ✅ Blue check (approved), ❌ Purple cancel (rejected)

### 4. **Book Renewal Notifications**
- Confirmation when book is renewed
- Shows new due date
- Resets the 3-day reminder
- Icon: 🔄 Cyan refresh icon

### 5. **Book Return Confirmation**
- Thank you message when book is returned
- Icon: 📚 Green book icon

### 6. **Visual Indicators**
- Unread notification badge on home page navigation
- Count shows up to 9+ unread notifications
- Color-coded icons for different notification types
- Bold text for unread notifications
- Red dot indicator for unread items

## 📋 Notification Types

| Type | Icon | Color | Trigger Event |
|------|------|-------|---------------|
| General | 🔔 Bell | Brown | General notifications |
| Borrow | 📚 Book | Green | Borrow request submitted |
| Approved | ✅ Check | Blue | Request approved by admin |
| Rejected | ❌ Cancel | Purple | Request rejected by admin |
| Due Date Reminder | 🕐 Clock | Orange | 3 days before due date |
| Overdue | ⚠️ Warning | Red | After due date passes |
| Renewed | 🔄 Refresh | Cyan | Book renewal confirmed |

## 🔧 Technical Implementation

### Services

#### 1. **NotificationService** (`lib/services/notificationservice.dart`)

Core service handling all notification operations:

**Key Methods:**
- `sendNotification()` - Send any type of notification
- `sendDueDateReminder()` - Send 3-day advance reminder
- `sendOverdueNotification()` - Send overdue alerts
- `sendBorrowApprovedNotification()` - Notify on approval
- `sendBorrowRejectedNotification()` - Notify on rejection
- `sendBookRenewedNotification()` - Confirm renewal
- `sendBookReturnedNotification()` - Confirm return
- `getUnreadCount()` - Get count of unread notifications
- `markAsRead()` - Mark single notification as read
- `markAllAsRead()` - Mark all notifications as read
- `checkAndSendDueDateReminders()` - Automated check for upcoming due dates
- `checkAndSendOverdueNotifications()` - Automated check for overdue books

**Notification Types Enum:**
```dart
enum NotificationType {
  borrow,
  return_reminder,
  overdue,
  approved,
  rejected,
  renewed,
  general,
}
```

#### 2. **NotificationScheduler** (`lib/services/notification_scheduler.dart`)

Automated scheduler that runs periodic checks:

**Features:**
- Runs every hour to check for notifications
- Checks for books due in 3 days
- Checks for overdue books
- Singleton pattern for app-wide access
- Manual trigger option for testing

**Usage:**
```dart
// Started automatically in main.dart
NotificationScheduler.instance.start();

// Manual trigger (for testing)
await NotificationScheduler.instance.triggerManualCheck();

// Stop scheduler
NotificationScheduler.instance.stop();
```

### Database Structure

**Notification Document** (`users/{userId}/notifications/{notificationId}`):
```json
{
  "title": "Due Date Reminder",
  "message": "Your borrowed book 'Clean Code' is due on 25/10/2025...",
  "type": "return_reminder",
  "timestamp": "2025-10-22T10:30:00Z",
  "read": false,
  "dueDate": "2025-10-25T23:59:59Z"
}
```

**Borrow Request Fields for Notifications**:
```json
{
  "bookId": "abc123",
  "bookTitle": "Clean Code",
  "userId": "user123",
  "status": "accepted",
  "dueDate": "2025-10-25T23:59:59Z",
  "reminderSent": false,
  "lastOverdueNotification": null,
  "rejectionReason": "Book is already reserved"
}
```

### UI Components

#### 1. **NotificationsPage** (`lib/screens/studenthomepage/notifications_page.dart`)

Full-screen notification center:
- Real-time updates with StreamBuilder
- Color-coded notification cards
- Type-specific icons and colors
- Tap to mark as read
- "Mark all as read" button
- Empty state message

#### 2. **Home Page Badge** (`lib/screens/studenthomepage/home_page.dart`)

Notification indicator on bottom navigation:
- Real-time unread count
- Red circular badge
- Shows "9+" for 10 or more unread
- Positioned on notification bell icon

#### 3. **Admin Manage Request** (`lib/screens/adminhomepage/managerequest.dart`)

Enhanced approval/rejection workflow:
- Accept button sends approval notification
- Reject button prompts for optional reason
- Notifications sent automatically
- Success confirmation messages

## 🚀 Usage Examples

### For Students

**Viewing Notifications:**
1. Tap notification bell icon in bottom navigation
2. See unread count badge if notifications exist
3. Tap any notification to mark as read
4. Use "Mark all as read" to clear all at once

**Notification Scenarios:**

**Scenario 1: Borrowing a Book**
```
1. Student submits borrow request
   → Notification: "Borrow Request Submitted"
   
2. Admin approves request
   → Notification: "Borrow Request Approved - Due: 25/10/2025"
   
3. Three days before due date
   → Notification: "Due Date Reminder - Due: 25/10/2025"
   
4. If not returned on time
   → Notification: "Overdue Book - 1 day(s) overdue"
```

**Scenario 2: Book Renewal**
```
1. Student clicks "Renew" button
   → Notification: "Book Renewed - New due date: 08/11/2025"
   
2. Three days before new due date
   → Notification: "Due Date Reminder - Due: 08/11/2025"
```

### For Admins

**Approving Requests:**
1. Navigate to Borrow Requests
2. Tap "Manage" on a request
3. Click "Accept" button
4. Student receives approval notification automatically

**Rejecting Requests:**
1. Navigate to Borrow Requests
2. Tap "Manage" on a request
3. Click "Reject" button
4. Enter reason in dialog (optional)
5. Click "Reject" to confirm
6. Student receives rejection notification with reason

## ⚙️ Configuration

### Notification Check Interval

The scheduler runs every hour by default. To change:

```dart
// In lib/services/notification_scheduler.dart
_timer = Timer.periodic(const Duration(hours: 1), (timer) {
  _checkNotifications();
});

// Change to check every 30 minutes:
_timer = Timer.periodic(const Duration(minutes: 30), (timer) {
  _checkNotifications();
});
```

### Due Date Reminder Timing

Reminders are sent 3 days before due date by default. To change:

```dart
// In lib/services/notificationservice.dart
final threeDaysFromNow = now.add(const Duration(days: 3));

// Change to 5 days:
final fiveDaysFromNow = now.add(const Duration(days: 5));
```

### Overdue Notification Frequency

Overdue notifications are sent once per day. To change:

```dart
// In lib/services/notificationservice.dart
shouldSendNotification = daysSinceLastNotification >= 1;

// Change to twice per day (every 12 hours):
shouldSendNotification = 
    now.difference(lastNotificationDate).inHours >= 12;
```

## 🧪 Testing

### Manual Testing

**Test Due Date Reminders:**
```dart
// In your test code or debug screen
await NotificationScheduler.instance.triggerManualCheck();
```

**Create Test Notification:**
```dart
final notificationService = NotificationService();
await notificationService.sendNotification(
  userId: 'test_user_id',
  title: 'Test Notification',
  message: 'This is a test message',
  type: NotificationType.general,
);
```

**Test Scenarios:**

1. **Due Date Reminder Test:**
   - Create a borrow request with due date exactly 3 days from now
   - Trigger manual check
   - Verify notification appears

2. **Overdue Test:**
   - Create a borrow request with past due date
   - Trigger manual check
   - Verify overdue notification appears

3. **Approval/Rejection Test:**
   - Create borrow request as student
   - Approve/reject as admin
   - Check student's notifications

## 📊 Firestore Security Rules

Ensure your Firestore rules allow notification access:

```javascript
match /users/{userId}/notifications/{notificationId} {
  // Users can read and write their own notifications
  allow read, write: if request.auth != null && 
                        request.auth.uid == userId;
  
  // Admins can write to any user's notifications
  allow write: if request.auth != null && 
                  get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

## 🔮 Future Enhancements

Potential improvements to consider:

1. **Push Notifications**: Integrate Firebase Cloud Messaging for device notifications
2. **Email Notifications**: Send email for important notifications
3. **Notification Preferences**: Let users customize notification types
4. **Notification History**: Archive old notifications
5. **Rich Notifications**: Add images and action buttons
6. **Notification Scheduling**: Let admins schedule announcements
7. **Multi-language Support**: Translate notifications
8. **Custom Notification Sounds**: Different sounds for different types
9. **Notification Categories**: Filter by category
10. **Read Receipts**: Track when notifications are read

## 🐛 Troubleshooting

### Notifications Not Appearing

**Check:**
1. User is logged in (Firebase Auth)
2. Firestore permissions are correct
3. Notification scheduler is started in main.dart
4. No errors in console logs

**Debug:**
```dart
// Check unread count
final count = await NotificationService().getUnreadCount(userId);
print('Unread notifications: $count');

// Check Firestore directly
final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .get();
print('Total notifications: ${snapshot.docs.length}');
```

### Due Date Reminders Not Sending

**Check:**
1. Borrow request has `dueDate` field
2. Due date is exactly 3 days away
3. `reminderSent` field is false
4. Status is 'accepted'

**Debug:**
```dart
await NotificationScheduler.instance.triggerManualCheck();
```

### Badge Not Showing

**Check:**
1. StreamBuilder is properly configured
2. User ID is correct
3. Query filters are correct

**Debug:**
```dart
// Check StreamBuilder query
FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('notifications')
    .where('read', isEqualTo: false)
    .snapshots()
    .listen((snapshot) {
      print('Unread count: ${snapshot.docs.length}');
    });
```

## 📝 Change Log

### Version 1.0 (Current)
- ✅ Basic notification system with Firestore
- ✅ Due date reminders (3 days advance)
- ✅ Overdue notifications (daily)
- ✅ Borrow request status notifications
- ✅ Book renewal notifications
- ✅ Visual badge indicators
- ✅ Color-coded notification types
- ✅ Mark as read functionality
- ✅ Automated scheduler service
- ✅ Admin rejection with reason

---

**For questions or issues, please refer to the main README.md or contact the development team.**
