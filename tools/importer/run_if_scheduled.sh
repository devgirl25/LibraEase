#!/bin/bash
# run_if_scheduled.sh
# Bash runner for the importer that respects the Firestore schedule
# Usage:
#   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
#   export GOOGLE_BOOKS_API_KEY="optional_key"
#   ./run_if_scheduled.sh
#!/bin/bash
set -e
cd "$(dirname "$0")"

# Load .env
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Ensure Node.js is installed
if ! command -v node &> /dev/null; then
  echo "❌ Node.js not found."
  exit 3
fi

# Ensure credentials are set
if [ -z "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  echo "❌ GOOGLE_APPLICATION_CREDENTIALS not set."
  exit 2
fi

# Run Node script
node check_and_run.js
EXIT_CODE=$?
echo "✅ Finished. Logs are saved in logs/ directory."
exit $EXIT_CODE
