// check_and_run.js
// Checks schedules/import_ebooks.monthly in Firestore and runs the importer if enabled.
// Usage: node check_and_run.js

const admin = require('firebase-admin');
const { spawn } = require('child_process');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS to your service account json path');
  process.exit(2);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function main() {
  const doc = await db.collection('schedules').doc('import_ebooks').get();
  const data = doc.exists ? doc.data() : {};
  const enabled = !!data && data.monthly === true;
  if (!enabled) {
    console.log('Schedule disabled; exiting.');
    process.exit(0);
  }

  console.log('Schedule enabled; running importer...');
  const child = spawn('node', ['index.js'], { stdio: 'inherit', cwd: __dirname });
  child.on('close', (code) => {
    process.exit(code);
  });
}

main().catch((err) => { console.error(err); process.exit(1); });
