// const admin = require('firebase-admin');
// const db = admin.firestore();

// /**
//  * Send due-date reminder notifications to students
//  */
// async function sendDueDateNotifications() {
//   const today = new Date();
//   const snapshot = await db.collection('borrow_requests')
//     .where('status', '==', 'accepted')
//     .get();

//   const messages = [];

//   snapshot.forEach(doc => {
//     const data = doc.data();
//     const dueDate = data.dueDate.toDate ? data.dueDate.toDate() : new Date(data.dueDate);
//     const diff = Math.floor((dueDate - today) / (1000 * 60 * 60 * 24)); // days remaining

//     if (diff <= 3 && diff >= 0) { // send reminder 3 days before due date
//       const fcmToken = data.fcmToken;
//       if (fcmToken) {
//         messages.push({
//           token: fcmToken,
//           notification: {
//             title: 'LibraEase Reminder',
//             body: `Your book "${data.bookTitle}" is due on ${dueDate.toDateString()}.`,
//           },
//           data: {
//             bookId: doc.id,
//           },
//         });
//       }
//     }
//   });

//   if (messages.length === 0) return 'No notifications to send today.';

//   const response = await admin.messaging().sendAll(messages);
//   console.log(`✅ Sent ${response.successCount} notifications`);
//   return `Sent ${response.successCount} notifications`;
// }

// module.exports = { sendDueDateNotifications };
