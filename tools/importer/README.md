Local importer

Steps to run locally:

1. Install dependencies:

   npm install

2. Set environment variables:

   - GOOGLE_APPLICATION_CREDENTIALS: path to your Firebase service account JSON
   - (optional) GOOGLE_BOOKS_API_KEY: your Google Books API key

3. Run the importer:

   npm run import

Notes:
- This script writes directly to your Firestore. Use a development project or emulator when testing.
- It uses the same idempotency checks as the client: prefers `sourceId` then falls back to title+author.

Scheduled runs (no GCP scheduler required):

1. Install dependencies:

   npm install

2. Set environment variables (PowerShell example):

   $env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\service-account.json'
   $env:GOOGLE_BOOKS_API_KEY = 'optional_key'

3. Run the schedule-aware helper (it will check `schedules/import_ebooks.monthly` and run the importer only if enabled):

   npm run import:scheduled

Or use the provided PowerShell wrapper from the repository root:

   tools\importer\run_if_scheduled.ps1

Notes:
- The scheduled helper reads `schedules/import_ebooks` in Firestore and expects a boolean `monthly` field.
- This approach lets you run the importer from a VM or CI cron on your side without paying for Cloud Scheduler.
