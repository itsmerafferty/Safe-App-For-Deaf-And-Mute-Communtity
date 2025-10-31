# Firebase Storage CORS Configuration Script
# This script sets up CORS for Firebase Storage to allow web access to images

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Firebase Storage CORS Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if gsutil is installed
Write-Host "Checking for gsutil..." -ForegroundColor Yellow
$gsutilCheck = Get-Command gsutil -ErrorAction SilentlyContinue

if (-not $gsutilCheck) {
    Write-Host "❌ gsutil not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Google Cloud SDK first:" -ForegroundColor Yellow
    Write-Host "1. Visit: https://cloud.google.com/sdk/docs/install" -ForegroundColor White
    Write-Host "2. Download and install Google Cloud SDK" -ForegroundColor White
    Write-Host "3. Run: gcloud init" -ForegroundColor White
    Write-Host "4. Run this script again" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ gsutil found!" -ForegroundColor Green
Write-Host ""

# Your Firebase Storage bucket
$bucketName = "safe-emergency-app-f4c17.firebasestorage.app"
Write-Host "Firebase Storage Bucket: $bucketName" -ForegroundColor Cyan
Write-Host ""

# Check if cors.json exists
if (-not (Test-Path "cors.json")) {
    Write-Host "❌ cors.json file not found!" -ForegroundColor Red
    Write-Host "Please make sure cors.json exists in the current directory." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ cors.json found!" -ForegroundColor Green
Write-Host ""

# Display CORS configuration
Write-Host "CORS Configuration:" -ForegroundColor Yellow
Get-Content cors.json | Write-Host -ForegroundColor White
Write-Host ""

# Apply CORS configuration
Write-Host "Applying CORS configuration to Firebase Storage..." -ForegroundColor Yellow
Write-Host ""

try {
    $result = gsutil cors set cors.json "gs://$bucketName" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "✅ SUCCESS!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "CORS configuration has been applied to Firebase Storage!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Refresh your admin dashboard" -ForegroundColor White
        Write-Host "2. Try loading the images again" -ForegroundColor White
        Write-Host "3. Images should now load properly!" -ForegroundColor White
        Write-Host ""
        Write-Host "Note: It may take a few minutes for changes to propagate." -ForegroundColor Yellow
    } else {
        throw "gsutil command failed"
    }
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "❌ ERROR" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Failed to apply CORS configuration." -ForegroundColor Red
    Write-Host ""
    Write-Host "Error details:" -ForegroundColor Yellow
    Write-Host $result -ForegroundColor White
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure you're logged in: gcloud auth login" -ForegroundColor White
    Write-Host "2. Set project: gcloud config set project safe-emergency-app-f4c17" -ForegroundColor White
    Write-Host "3. Make sure you have Storage Admin permissions" -ForegroundColor White
    Write-Host ""
}

Write-Host ""
Read-Host "Press Enter to exit"
