# Quick API Key Update Instructions 🗝️

## After You Get Your API Key:

### Step 1: Copy Your New API Key
From Google Cloud Console, copy the API key (starts with `AIza...`)

### Step 2: Update index.html

**File Location:**
```
d:\Safe Mobile app system\safe_application_for_deafandmute\safe_admin_web\web\index.html
```

**Find this line (around line 34):**
```html
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBxJQz7xVzR9pCKXf8KZ7vZ3nVhF7Ql8gM"></script>
```

**Replace with:**
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_NEW_KEY_HERE"></script>
```

### Step 3: Save and Rebuild

**PowerShell Commands:**
```powershell
cd "d:\Safe Mobile app system\safe_application_for_deafandmute\safe_admin_web"
flutter clean
flutter pub get
flutter run -d chrome
```

## ✅ Done!

Map should load perfectly now! 🎉

---

## 🆘 If You Need Help:

Just paste your new API key here and I'll update the file for you!

Example:
```
My new API key is: AIzaSyC_abc123xyz...
```

Then I'll automatically update the index.html file! ✨
