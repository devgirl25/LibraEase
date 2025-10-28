// // notifications.js
// // Node.js script to send due-date reminders via Firebase Cloud Messaging

// const admin = require('firebase-admin');
// const fs = require('fs');
// const path = require('path');
// require('dotenv').config();

// // ----------- Logs setup -----------
// const logsDir = path.join(__dirname, 'logs');
// if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir);

// const timestamp = new Date().toISOString().replace(/:/g, '-'); // safe filename
// const logFile = path.join(logsDir, `notifications-${timestamp}.log`);
// const logStream = fs.createWriteStream(logFile, { flags: 'a' });

// const log = (...args) => {
//   logStream.write(args.join(' ') + '\n');
//   console.log(...args);
// };

// // ----------- Firebase Admin init -----------
// // Use relative path to your serviceAccountKey.json
// const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
// if (!fs.existsSync(serviceAccountPath)) {
//   log(`❌ serviceAccountKey.json not found at ${serviceAccountPath}. Exiting.`);
//   process.exit(1);
// }

// if (!admin.apps.length) {
//   admin.initializeApp({
//     credential: admin.credential.cert(require(serviceAccountPath)),
//   });
//   log('✅ Firebase Admin initialized.');
// }

// const db = admin.firestore();
// const messaging = admin.messaging();

// // ----------- Main notification function -----------
// async function sendDueDateNotifications() {
//   try {
//     const today = new Date();

//     const borrowSnap = await db.collection('borrow_requests')
//       .where('status', 'in', ['accepted', 'borrowed'])
//       .get();

//     if (borrowSnap.empty) {
//       log('⚠️ No active borrow requests found.');
//       return;
//     }

//     const notifications = [];

//     borrowSnap.forEach(doc => {
//       const data = doc.data();
//       if (!data.dueDate || !data.userId || !data.bookTitle) return;

//       const dueDate = data.dueDate.toDate();
//       const diffDays = Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));

//       // 2-day reminder
//       if (diffDays <= 2 && diffDays >= 0) {
//         notifications.push({
//           uid: data.userId,
//           message: `Your borrowed book "${data.bookTitle}" is due on ${dueDate.toDateString()}`,
//         });
//       }

//       // Overdue notification
//       if (diffDays < 0) {
//         notifications.push({
//           uid: data.userId,
//           message: `Your borrowed book "${data.bookTitle}" is overdue by ${Math.abs(diffDays)} day(s). Please return it on time to avoid late fees.`,
//         });
//       }
//     });

//     log(`Found ${notifications.length} notifications to send.`);

//     for (const n of notifications) {
//       const userDoc = await db.collection('users').doc(n.uid).get();
//       if (!userDoc.exists) continue;

//       const fcmToken = userDoc.data()?.fcmToken;
//       if (!fcmToken) {
//         log(`⚠️ No FCM token for user ${n.uid}, skipping.`);
//         continue;
//       }

//     await messaging.send({
//   token: fcmToken,
//   notification: {
//     title: 'LibraEase Reminder',
//     body: n.message,
//   },
//   android: {
//     priority: 'high',
//     notification: {
//       icon: 'ic_launcher',  // optional: your drawable icon in Android
//       color: '#3B2715',     // optional: icon color
//     },
//   },
//   apns: { headers: { 'apns-priority': '10' } },
// });


//       log(`✅ Notification sent to user: ${n.uid}`);
//     }

//     log('🎉 All notifications processed.');
//   } catch (err) {
//     log('❌ Error sending notifications:', err);
//   } finally {
//     logStream.end();
//   }
// }

// // ----------- Run the script -----------
// sendDueDateNotifications();








// notifications.js
// Node.js script to send due-date reminders via Firebase Cloud Messaging using .env
// notifications.js
// Node.js script to send due-date reminders via Firebase Cloud Messaging using .env

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

//console.log('🔍 Loaded .env keys:', Object.keys(process.env));


// ----------- Logs setup -----------
const logsDir = path.join(__dirname, process.env.LOG_DIR || 'logs');
if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir);

const timestamp = new Date().toISOString().replace(/:/g, '-'); // safe filename
const logFile = path.join(logsDir, `notifications-${timestamp}.log`);
const logStream = fs.createWriteStream(logFile, { flags: 'a' });

const log = (...args) => {
  logStream.write(args.join(' ') + '\n');
  console.log(...args);
};

// ----------- Firebase Admin init -----------
if (!admin.apps.length) {
  // Construct service account object from env vars
  const serviceAccount = {
    type: process.env.TYPE,
    project_id: process.env.PROJECT_ID,
    private_key_id: process.env.PRIVATE_KEY_ID,
    private_key: process.env.PRIVATE_KEY.replace(/\\n/g, '\n'),
    client_email: process.env.CLIENT_EMAIL,
    client_id: process.env.CLIENT_ID,
    auth_uri: process.env.AUTH_URI,
    token_uri: process.env.TOKEN_URI,
    auth_provider_x509_cert_url: process.env.AUTH_PROVIDER_X509_CERT_URL,
    client_x509_cert_url: process.env.CLIENT_X509_CERT_URL,
    universe_domain: process.env.UNIVERSE_DOMAIN, // ✅ added this line
  };

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  log('✅ Firebase Admin initialized via .env credentials.');
}

const db = admin.firestore();
const messaging = admin.messaging();

// ----------- Main notification function -----------
async function sendDueDateNotifications() {
  try {
    const today = new Date();

    const borrowSnap = await db.collection('borrow_requests')
      .where('status', 'in', ['accepted', 'borrowed'])
      .get();

    if (borrowSnap.empty) {
      log('⚠️ No active borrow requests found.');
      return;
    }

    const notifications = [];

    borrowSnap.forEach(doc => {
      const data = doc.data();
      if (!data.dueDate || !data.userId || !data.bookTitle) return;

      const dueDate = data.dueDate.toDate();
      const diffDays = Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));

      // 2-day reminder
      if (diffDays <= 2 && diffDays >= 0) {
        notifications.push({
          uid: data.userId,
          message: `Your borrowed book "${data.bookTitle}" is due on ${dueDate.toDateString()}`,
        });
      }

      // Overdue notification
      if (diffDays < 0) {
        notifications.push({
          uid: data.userId,
          message: `Your borrowed book "${data.bookTitle}" is overdue by ${Math.abs(diffDays)} day(s). Please return it on time to avoid late fees.`,
        });
      }
    });

    log(`Found ${notifications.length} notifications to send.`);

    for (const n of notifications) {
      const userDoc = await db.collection('users').doc(n.uid).get();
      if (!userDoc.exists) continue;

      const fcmToken = userDoc.data()?.fcmToken;
      if (!fcmToken) {
        log(`⚠️ No FCM token for user ${n.uid}, skipping.`);
        continue;
      }

      await messaging.send({
        token: fcmToken,
        notification: {
          title: 'LibraEase Reminder',
          body: n.message,
        },
        android: {
          priority: 'high',
          notification: {
            icon: 'ic_launcher',
            color: '#3B2715',
          },
        },
        apns: { headers: { 'apns-priority': '10' } },
      });

      log(`✅ Notification sent to user: ${n.uid}`);
    }

    log('🎉 All notifications processed.');
  } catch (err) {
    log('❌ Error sending notifications:', err);
  } finally {
    logStream.end();
  }
}

// ----------- Run the script -----------
sendDueDateNotifications();
