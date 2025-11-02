# SAFE Admin Mobile App - Quick Reference

## 🚀 Quick Start Commands

### Run Admin App
```bash
cd safe_admin_mobile_app
flutter pub get
flutter run
```

### Build Admin App APK
```bash
cd safe_admin_mobile_app
flutter build apk --release
```

---

## 📧 Admin Email Examples

### ✅ VALID
- `admin@safe.gov.ph`
- `pdao.admin@gmail.com`
- `administrator@safe.com`
- `staff.pdao@example.com`

### ❌ INVALID
- `user@gmail.com`
- `john@company.com`
- `test@example.com`

*Rule: Email must contain "admin" OR "pdao"*

---

## 📂 App Locations

| App | Directory | Theme |
|-----|-----------|-------|
| **User App** | `./` (root) | Purple 💜 |
| **Admin App** | `./safe_admin_mobile_app/` | Red ❤️ |

---

## 🎯 Key Features

### User App
- Emergency reporting
- Profile management
- Medical ID
- Emergency contacts
- GPS location

### Admin App
- User management
- Activity logs
- Statistics dashboard
- Admin authentication

---

## 📖 Documentation Files

| File | Purpose |
|------|---------|
| `ADMIN_APP_SEPARATION.md` | Complete separation guide |
| `safe_admin_mobile_app/README.md` | Admin app overview |
| `safe_admin_mobile_app/ADMIN_APP_SETUP.md` | Detailed setup instructions |
| This file | Quick reference |

---

## 🔧 Troubleshooting

### Admin app won't run?
```bash
cd safe_admin_mobile_app
flutter clean
flutter pub get
flutter run
```

### Can't login?
- Check email contains "admin" or "pdao"
- Verify internet connection
- Check Firebase Authentication is enabled

### Build errors?
- Ensure `google-services.json` exists in `android/app/`
- Run `flutter doctor`
- Check Flutter SDK is up to date

---

## ✅ Post-Separation Checklist

- [x] Admin app created in `safe_admin_mobile_app/`
- [x] All admin screens copied
- [x] Firebase configured
- [x] Dependencies installed
- [x] Admin folder removed from user app
- [x] Admin login button removed from user app
- [x] Documentation complete
- [ ] Test admin app
- [ ] Test user app
- [ ] Build production APKs
- [ ] Deploy both apps

---

## 🎉 You're All Set!

The admin app is ready to use. Run the commands above to get started!
