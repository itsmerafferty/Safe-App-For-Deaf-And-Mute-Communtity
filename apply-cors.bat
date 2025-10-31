@echo off
echo ========================================
echo Firebase Storage CORS Quick Fix
echo ========================================
echo.

echo Checking if Google Cloud SDK is installed...
where gcloud >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Google Cloud SDK is not installed!
    echo.
    echo Please install it first:
    echo 1. Download from: https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe
    echo 2. Run the installer
    echo 3. Check "Run 'gcloud init'" during installation
    echo 4. Close and reopen this terminal
    echo 5. Run this script again
    echo.
    pause
    exit /b 1
)

echo [OK] Google Cloud SDK found!
echo.

echo Setting Firebase project...
gcloud config set project safe-emergency-app-f4c17
echo.

echo Applying CORS configuration...
gsutil cors set cors.json gs://safe-emergency-app-f4c17.firebasestorage.app
echo.

if %errorlevel% equ 0 (
    echo ========================================
    echo [SUCCESS] CORS configuration applied!
    echo ========================================
    echo.
    echo Verifying configuration...
    gsutil cors get gs://safe-emergency-app-f4c17.firebasestorage.app
    echo.
    echo ========================================
    echo Next steps:
    echo 1. Wait 2-3 minutes for changes to take effect
    echo 2. Clear your browser cache (Ctrl+Shift+Delete)
    echo 3. Refresh admin dashboard (Ctrl+F5)
    echo 4. Images should load now!
    echo ========================================
) else (
    echo ========================================
    echo [ERROR] Failed to apply CORS configuration
    echo ========================================
    echo.
    echo Troubleshooting:
    echo 1. Make sure you're logged in: gcloud auth login
    echo 2. Check project: gcloud config get-value project
    echo 3. Verify permissions in Firebase Console
    echo ========================================
)

echo.
pause
