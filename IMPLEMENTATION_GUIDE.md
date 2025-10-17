# 🚀 Notification System - Quick Implementation Guide

## What Was Implemented

A comprehensive notification system that automatically sends students notifications for:

1. ✅ **Due Date Reminders** - 3 days before book due date
2. ✅ **Overdue Alerts** - Daily notifications for overdue books
3. ✅ **Borrow Request Updates** - When admin approves/rejects
4. ✅ **Book Renewals** - Confirmation when book is renewed
5. ✅ **Visual Indicators** - Badge showing unread count on home page

## Files Modified/Created

### New Files Created:
1. `lib/services/notification_scheduler.dart` - Automated notification checker
2. `NOTIFICATION_SYSTEM.md` - Complete documentation
3. `IMPLEMENTATION_GUIDE.md` - This file

### Files Modified:
1. `lib/services/notificationservice.dart` - Enhanced with all notification types
2. `lib/services/borrow_service.dart` - Integrated notifications
3. `lib/main.dart` - Added scheduler initialization
4. `lib/screens/studenthomepage/home_page.dart` - Added notification badge
5. `lib/screens/studenthomepage/notifications_page.dart` - Enhanced UI with types
6. `lib/screens/studenthomepage/borrow_history_page.dart` - Added renewal notifications
7. `lib/screens/adminhomepage/managerequest.dart` - Added approval/rejection notifications

## How It Works

### 1. Automatic Checks (Every Hour)
```
NotificationScheduler (runs every hour)
    ↓
Checks for books due in 3 days
    → Sends due date reminders
    
Checks for overdue books
    → Sends overdue notifications
```

### 2. Event-Based Notifications

**When Admin Approves Request:**
```
Admin clicks "Accept"
    ↓
ManageRequestPage.dart
    ↓
NotificationService.sendBorrowApprovedNotification()
    ↓
Student sees "Borrow Request Approved" notification
```

**When Admin Rejects Request:**
```
Admin clicks "Reject" → Enters reason
    ↓
ManageRequestPage.dart
    ↓
NotificationService.sendBorrowRejectedNotification()
    ↓
Student sees "Borrow Request Rejected" notification with reason
```

**When Student Renews Book:**
```
Student clicks "Renew"
    ↓
BorrowHistoryPage.dart
    ↓
NotificationService.sendBookRenewedNotification()
    ↓
Student sees "Book Renewed" notification
```

## Key Features

### 1. Smart Reminders
- Sends reminder only once (tracks with `reminderSent` field)
- Resets when book is renewed
- Checks every hour automatically

### 2. Overdue Management
- Daily notifications for overdue books
- Shows number of days overdue
- Tracks last notification to avoid spam

### 3. Visual Feedback
- Red badge on notification bell icon
- Shows unread count (e.g., "5" or "9+")
- Color-coded notification types
- Different icons for each type

### 4. User-Friendly UI
- Tap notification to mark as read
- "Mark all as read" button
- Unread notifications highlighted
- Type-specific colors and icons

## Testing the System

### 1. Test Borrow Request Notifications

**As Student:**
```
1. Browse books
2. Click "Borrow" on a book
3. Check notifications
   → Should see "Borrow Request Submitted"
```

**As Admin:**
```
1. Go to Borrow Requests
2. Click "Manage" on a request
3. Click "Accept"
4. Switch to student account
5. Check notifications
   → Should see "Borrow Request Approved"
```

### 2. Test Due Date Reminder

**Setup:**
```dart
// In Firestore, create a borrow_request with:
{
  "status": "accepted",
  "dueDate": Timestamp(3 days from now),
  "reminderSent": false,
  "userId": "student_uid",
  "bookTitle": "Test Book"
}
```

**Trigger:**
```dart
// Option 1: Wait for hourly check
// Option 2: Trigger manually (add this to a debug screen)
await NotificationScheduler.instance.triggerManualCheck();
```

**Verify:**
- Check student's notifications
- Should see "Due Date Reminder" notification

### 3. Test Overdue Notification

**Setup:**
```dart
// In Firestore, create a borrow_request with:
{
  "status": "accepted",
  "dueDate": Timestamp(yesterday),
  "userId": "student_uid",
  "bookTitle": "Test Book"
}
```

**Trigger:**
```dart
await NotificationScheduler.instance.triggerManualCheck();
```

**Verify:**
- Check student's notifications
- Should see "Overdue Book" notification with days overdue

### 4. Test Book Renewal

**As Student:**
```
1. Go to Borrow History
2. Find a borrowed book
3. Click "Renew"
4. Check notifications
   → Should see "Book Renewed" notification
```

### 5. Test Rejection with Reason

**As Admin:**
```
1. Go to Borrow Requests
2. Click "Manage" on a request
3. Click "Reject"
4. Enter reason: "Book is currently reserved"
5. Click "Reject" in dialog
6. Switch to student account
7. Check notifications
   → Should see "Borrow Request Rejected" with reason
```

### 6. Test Notification Badge

**As Student:**
```
1. Have some unread notifications
2. Go to Home page
3. Look at notification bell icon in bottom nav
   → Should see red badge with count
4. Tap notification bell
5. Tap a notification
6. Go back to Home
   → Badge count should decrease
```

## Configuration Options

### Change Reminder Timing

In `lib/services/notificationservice.dart`, line ~80:
```dart
// Current: 3 days before
final threeDaysFromNow = now.add(const Duration(days: 3));

// Change to 5 days before:
final fiveDaysFromNow = now.add(const Duration(days: 5));
```

### Change Check Frequency

In `lib/services/notification_scheduler.dart`, line ~26:
```dart
// Current: every hour
_timer = Timer.periodic(const Duration(hours: 1), (timer) {

// Change to every 30 minutes:
_timer = Timer.periodic(const Duration(minutes: 30), (timer) {
```

### Change Overdue Notification Frequency

In `lib/services/notificationservice.dart`, line ~155:
```dart
// Current: once per day
shouldSendNotification = daysSinceLastNotification >= 1;

// Change to twice per day:
shouldSendNotification = 
    now.difference(lastNotificationDate).inHours >= 12;
```

## Notification Types Reference

| Type | When Triggered | Icon | Color |
|------|---------------|------|-------|
| General | General messages | 🔔 | Brown |
| Borrow | Request submitted | 📚 | Green |
| Approved | Admin approves | ✅ | Blue |
| Rejected | Admin rejects | ❌ | Purple |
| Due Date Reminder | 3 days before due | 🕐 | Orange |
| Overdue | After due date | ⚠️ | Red |
| Renewed | Book renewed | 🔄 | Cyan |

## Database Fields Reference

### Notification Document
```javascript
users/{userId}/notifications/{notificationId}
{
  title: string,           // "Due Date Reminder"
  message: string,         // Full message text
  type: string,            // "return_reminder", "overdue", etc.
  timestamp: Timestamp,    // When notification was created
  read: boolean,           // Whether user has read it
  dueDate: Timestamp,      // (optional) Associated due date
  daysOverdue: number      // (optional) For overdue notifications
}
```

### Borrow Request Fields (for notifications)
```javascript
borrow_requests/{requestId}
{
  // ... existing fields ...
  reminderSent: boolean,              // Has 3-day reminder been sent?
  lastOverdueNotification: Timestamp, // When was last overdue notification sent?
  rejectionReason: string             // (optional) Why was it rejected?
}
```

## Common Issues and Solutions

### Issue: Notifications Not Showing

**Solution:**
1. Check user is logged in
2. Verify Firestore permissions
3. Check console for errors
4. Verify scheduler is started in main.dart

### Issue: Badge Not Updating

**Solution:**
1. Ensure StreamBuilder is in HomePage
2. Check user ID is correct
3. Verify notifications collection exists
4. Check 'read' field is boolean

### Issue: Reminders Sent Multiple Times

**Solution:**
1. Check `reminderSent` field is being set to true
2. Verify field is being updated in Firestore
3. Check scheduler isn't started multiple times

### Issue: Overdue Notifications Every Hour

**Solution:**
1. Check `lastOverdueNotification` field is being updated
2. Verify the 24-hour check logic
3. Ensure Timestamp is being saved correctly

## Next Steps

1. **Test All Scenarios** - Go through each test case above
2. **Customize Timing** - Adjust reminder/check frequencies if needed
3. **Add Push Notifications** - Integrate Firebase Cloud Messaging
4. **Monitor Performance** - Check Firestore read/write usage
5. **Gather Feedback** - Get user feedback on notification content

## Support

For detailed information, see:
- `NOTIFICATION_SYSTEM.md` - Complete technical documentation
- `FIRESTORE_STRUCTURE.md` - Database structure
- Individual file comments - Implementation details

---

**System Status: ✅ Fully Implemented and Ready to Test**
