# Notification System Documentation

## Overview
The LibraEase notification system provides real-time notifications to students about due dates, overdue books, borrow requests, and library announcements. The system consists of multiple components working together to ensure timely and relevant notifications.

## Architecture

### Components

1. **NotificationManager** (`lib/services/notification_manager.dart`)
   - Core service for creating and managing notifications
   - Handles all notification types
   - Manages notification lifecycle (create, read, delete)

2. **NotificationScheduler** (`lib/services/notification_scheduler.dart`)
   - Automated background scheduler
   - Runs periodic checks for due dates and overdue books
   - Configurable check intervals

3. **BorrowService** (Updated)
   - Integrated with NotificationManager
   - Sends notifications on borrow, renew, and return actions

4. **NotificationsPage** (Enhanced)
   - Rich UI with notification type icons and colors
   - Swipe-to-delete functionality
   - Mark as read/unread
   - Notification badge counter

## Notification Types

### 1. Due Date Reminders
**Type**: `due_date_reminder`
**When**: 3 days, 1 day, and day of due date
**Icon**: Calendar (Orange)
**Example**:
```
Title: Due Date Reminder
Message: Reminder: "Clean Code" is due in 3 days (15/10/2024). Please return it on time.
```

### 2. Overdue Alerts
**Type**: `overdue`
**When**: Daily after due date passes
**Icon**: Warning (Red)
**Example**:
```
Title: Overdue Book Alert
Message: URGENT: "Clean Code" is 2 days overdue! Please return it immediately to avoid penalties.
```

### 3. Borrow Success
**Type**: `borrow_success`
**When**: After successful book borrowing
**Icon**: Check Circle (Green)
**Example**:
```
Title: Book Borrowed Successfully
Message: You have successfully borrowed "Clean Code". Please return it by 25/10/2024. Happy reading!
```

### 4. Borrow Approved
**Type**: `borrow_approved`
**When**: Admin approves borrow request
**Icon**: Check Circle (Green)
**Example**:
```
Title: Borrow Request Approved
Message: Your request to borrow "Clean Code" has been approved! Please collect the book from the library.
```

### 5. Borrow Rejected
**Type**: `borrow_rejected`
**When**: Admin rejects borrow request
**Icon**: Cancel (Red)
**Example**:
```
Title: Borrow Request Rejected
Message: Your request to borrow "Clean Code" has been rejected. Reason: Book already borrowed.
```

### 6. Book Renewed
**Type**: `book_renewed`
**When**: Book successfully renewed
**Icon**: Refresh (Blue)
**Example**:
```
Title: Book Renewed Successfully
Message: "Clean Code" has been renewed successfully! New due date: 08/11/2024.
```

### 7. Book Returned
**Type**: `book_returned`
**When**: Book successfully returned
**Icon**: Assignment Turned In (Teal)
**Example**:
```
Title: Book Returned
Message: Thank you for returning "Clean Code" on 25/10/2024. We hope you enjoyed reading it!
```

### 8. Registration Approved
**Type**: `registration_approved`
**When**: Student registration approved by admin
**Icon**: Verified (Green)
**Example**:
```
Title: Registration Approved
Message: Congratulations John! Your library registration has been approved.
```

### 9. Registration Rejected
**Type**: `registration_rejected`
**When**: Student registration needs attention
**Icon**: Info (Orange)
**Example**:
```
Title: Registration Update
Message: Your library registration needs attention. Reason: Invalid student ID.
```

### 10. New Book Available
**Type**: `new_book`
**When**: New book added to library
**Icon**: Book (Purple)
**Example**:
```
Title: New Book Available
Message: A new book "Python Crash Course" by Eric Matthes has been added. Check it out now!
```

### 11. Wishlist Book Available
**Type**: `wishlist_available`
**When**: Wishlisted book becomes available
**Icon**: Book (Purple)
**Example**:
```
Title: Wishlist Book Available
Message: Great news! "Clean Code" from your wishlist is now available for borrowing.
```

### 12. Library Announcement
**Type**: `announcement`
**When**: Admin sends announcement
**Icon**: Campaign (Indigo)
**Example**:
```
Title: Library Closed Tomorrow
Message: The library will be closed tomorrow for maintenance. Please plan accordingly.
```

## Features

### 1. Real-time Notifications
- Uses Firestore streams for instant notification delivery
- No page refresh needed
- Automatic UI updates

### 2. Badge Counter
- Shows unread notification count on home page navigation bar
- Red badge with number (99+ for >99 notifications)
- Real-time updates as notifications are read

### 3. Swipe to Delete
- Swipe left on any notification to delete
- Undo option available
- Smooth animation

### 4. Mark as Read/Unread
- Tap notification to mark as read
- Visual distinction between read/unread
- Mark all as read button

### 5. Notification Actions
- Context-sensitive action buttons
- "Renew Book" for due date reminders
- "Borrow Now" for wishlist available
- Direct navigation to relevant pages

### 6. Timestamp Display
- Relative time (Just now, 5m ago, 2h ago, 3d ago)
- Absolute date for older notifications
- Automatic formatting

## Usage

### Sending Notifications

#### From BorrowService
```dart
final borrowService = BorrowService();

// Borrow a book
await borrowService.borrowBook(
  bookId: 'book123',
  bookTitle: 'Clean Code',
  userId: 'user123',
  borrowDays: 14,
);
// Automatically sends borrow success notification
```

#### Direct Notification
```dart
final notificationManager = NotificationManager();

// Send custom notification
await notificationManager.sendDueDateReminderNotification(
  userId: 'user123',
  bookTitle: 'Clean Code',
  dueDate: DateTime.now().add(Duration(days: 3)),
);
```

### Scheduler Configuration

The NotificationScheduler runs automatically when the app starts:

```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Start notification scheduler
  NotificationScheduler().startScheduler();

  runApp(const MyApp());
}
```

**Default Schedule:**
- Due date reminders: Every 6 hours
- Overdue checks: Every 12 hours
- Initial check: Immediately on app start

**Manual Check:**
```dart
final scheduler = NotificationScheduler();
await scheduler.runManualCheck();
```

**Stop Scheduler:**
```dart
NotificationScheduler().stopScheduler();
```

## Firestore Structure

### Notification Document
```
users/{userId}/notifications/{notificationId}
├── title: string
├── message: string
├── timestamp: timestamp
├── read: boolean
├── type: string (notification type)
└── [additional fields based on type]
```

### Example Documents

**Due Date Reminder:**
```json
{
  "title": "Due Date Reminder",
  "message": "Reminder: \"Clean Code\" is due in 3 days...",
  "timestamp": "2024-10-12T10:30:00Z",
  "read": false,
  "type": "due_date_reminder",
  "bookTitle": "Clean Code",
  "dueDate": "2024-10-15T23:59:59Z"
}
```

**Overdue Alert:**
```json
{
  "title": "Overdue Book Alert",
  "message": "URGENT: \"Clean Code\" is 2 days overdue!",
  "timestamp": "2024-10-17T10:00:00Z",
  "read": false,
  "type": "overdue",
  "bookTitle": "Clean Code",
  "dueDate": "2024-10-15T23:59:59Z",
  "daysOverdue": 2
}
```

## API Reference

### NotificationManager Methods

#### sendDueDateReminderNotification
```dart
Future<void> sendDueDateReminderNotification({
  required String userId,
  required String bookTitle,
  required DateTime dueDate,
})
```

#### sendOverdueNotification
```dart
Future<void> sendOverdueNotification({
  required String userId,
  required String bookTitle,
  required DateTime dueDate,
})
```

#### sendBorrowSuccessNotification
```dart
Future<void> sendBorrowSuccessNotification({
  required String userId,
  required String bookTitle,
  required DateTime borrowDate,
  required DateTime dueDate,
})
```

#### sendBookRenewedNotification
```dart
Future<void> sendBookRenewedNotification({
  required String userId,
  required String bookTitle,
  required DateTime oldDueDate,
  required DateTime newDueDate,
})
```

#### sendBookReturnedNotification
```dart
Future<void> sendBookReturnedNotification({
  required String userId,
  required String bookTitle,
  required DateTime returnDate,
})
```

#### sendRegistrationApprovedNotification
```dart
Future<void> sendRegistrationApprovedNotification({
  required String userId,
  required String studentName,
})
```

#### sendLibraryAnnouncementNotification
```dart
Future<void> sendLibraryAnnouncementNotification({
  required String userId,
  required String title,
  required String message,
})
```

#### getUnreadNotificationCount
```dart
Future<int> getUnreadNotificationCount(String userId)
```

#### markAllAsRead
```dart
Future<void> markAllAsRead(String userId)
```

#### deleteNotification
```dart
Future<void> deleteNotification(String userId, String notificationId)
```

#### deleteAllNotifications
```dart
Future<void> deleteAllNotifications(String userId)
```

## Best Practices

### 1. Notification Frequency
- Don't spam users with notifications
- Use the scheduler's default intervals
- Implement notification throttling for repeated events

### 2. Message Content
- Keep messages concise and actionable
- Include relevant dates and book titles
- Use clear, friendly language

### 3. Error Handling
```dart
try {
  await notificationManager.sendDueDateReminderNotification(
    userId: userId,
    bookTitle: bookTitle,
    dueDate: dueDate,
  );
} catch (e) {
  debugPrint('Error sending notification: $e');
  // Handle error appropriately
}
```

### 4. Performance
- Use batch operations for multiple notifications
- Implement pagination for notification lists
- Clean up old notifications periodically

### 5. Testing
```dart
// Test notification creation
final notificationManager = NotificationManager();
await notificationManager.sendLibraryAnnouncementNotification(
  userId: 'test_user',
  title: 'Test Notification',
  message: 'This is a test message',
);

// Verify notification was created
final count = await notificationManager.getUnreadNotificationCount('test_user');
assert(count > 0);
```

## Future Enhancements

### Planned Features
1. **Push Notifications**: Firebase Cloud Messaging integration
2. **Email Notifications**: Send important notifications via email
3. **Notification Preferences**: Let users customize notification types
4. **Notification History**: Archive and search past notifications
5. **Rich Notifications**: Add images and attachments
6. **Notification Groups**: Group related notifications
7. **Smart Timing**: AI-based optimal notification timing
8. **Multi-language Support**: Localized notification messages

### Cloud Functions Alternative
For production environments, consider implementing the scheduler as Firebase Cloud Functions:

```javascript
// Cloud Function for scheduled notifications
exports.checkDueDates = functions.pubsub
  .schedule('every 6 hours')
  .onRun(async (context) => {
    // Run notification checks
  });
```

## Troubleshooting

### Notifications Not Appearing
1. Check Firestore security rules allow read access
2. Verify user is authenticated
3. Check notification stream is active
4. Verify scheduler is running

### Badge Count Not Updating
1. Check Firestore listener is active
2. Verify 'read' field is being updated
3. Check component is mounted when updating state

### Scheduler Not Running
1. Verify `NotificationScheduler().startScheduler()` is called in main.dart
2. Check for console errors
3. Ensure Firebase is initialized before scheduler

### Duplicate Notifications
1. Check if scheduler is started multiple times
2. Implement notification deduplication
3. Use lastNotificationSent tracking

## Security Considerations

### Firestore Security Rules
```javascript
match /users/{userId}/notifications/{notificationId} {
  // Users can only read their own notifications
  allow read: if request.auth.uid == userId;

  // Only system/admin can write notifications
  allow write: if request.auth.uid == userId ||
                  get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

### Data Privacy
- Never include sensitive information in notifications
- Use generic messages when possible
- Implement notification encryption for sensitive data

## Support
For issues or questions about the notification system, please refer to:
- Firebase documentation: https://firebase.google.com/docs
- Firestore queries: https://firebase.google.com/docs/firestore/query-data/queries
- Flutter best practices: https://flutter.dev/docs/development/best-practices
