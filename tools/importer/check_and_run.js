// check_and_run.js
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const { spawn } = require('child_process');

// Prepare logs directory
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) fs.mkdirSync(logsDir);

// Timestamped log file
const timestamp = new Date().toISOString().replace(/:/g, '-'); // safe filename
const logFile = path.join(logsDir, `importer-${timestamp}.log`);

// Redirect console output to log file
const logStream = fs.createWriteStream(logFile, { flags: 'a' });
console.log = (...args) => { logStream.write(args.join(' ') + '\n'); process.stdout.write(args.join(' ') + '\n'); };
console.error = (...args) => { logStream.write(args.join(' ') + '\n'); process.stderr.write(args.join(' ') + '\n'); };

console.log('==============================');
console.log(`Starting check_and_run.js at ${new Date().toLocaleString()}`);
console.log('==============================');

// Ensure credentials env var is set
if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('❌ GOOGLE_APPLICATION_CREDENTIALS is not set.');
  process.exit(2);
}

// Initialize Firebase only once
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(require(process.env.GOOGLE_APPLICATION_CREDENTIALS)),
  });
  console.log('✅ Firebase Admin initialized');
}

const db = admin.firestore();

async function main() {
  try {
    const doc = await db.collection('schedules').doc('import_ebooks').get();
    if (!doc.exists) {
      console.log('⚠️ No schedule document found.');
      process.exit(0);
    }

    const data = doc.data();
    const enabled = data?.monthly === true;

    if (!enabled) {
      console.log('⏹ Schedule disabled; exiting.');
      process.exit(0);
    }

    console.log('🟢 Schedule enabled; running importer...');
    const child = spawn('node', ['index.js'], { stdio: 'inherit', cwd: __dirname });

    child.on('close', (code) => {
      console.log(`Importer exited with code ${code}`);
      console.log('==============================\n');
      logStream.end();
      process.exit(code);
    });
  } catch (err) {
    console.error('❌ Error running check_and_run.js:', err);
    logStream.end();
    process.exit(1);
  }
}

main();
