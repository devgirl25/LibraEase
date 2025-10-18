# PowerShell runner for the importer that respects the Firestore schedule
# Usage (PowerShell):
#   $env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\sa.json'
#   $env:GOOGLE_BOOKS_API_KEY = 'optional_key'
#   .\run_if_scheduled.ps1

$here = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Push-Location $here
try {
    if (-not $env:GOOGLE_APPLICATION_CREDENTIALS) {
        Write-Error "Set the GOOGLE_APPLICATION_CREDENTIALS env var to your service account json path"
        exit 2
    }

    Write-Output "Checking schedule and running importer if enabled..."
    # run the Node helper which will check Firestore and run index.js if scheduled
    node check_and_run.js
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
