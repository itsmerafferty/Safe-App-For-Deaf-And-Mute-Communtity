# Quick Start: Test Emergency System NOW!

**5-Minute Testing Guide**

---

## 🎯 What You'll Test

Mobile app sends emergency → Admin dashboard receives it in real-time

---

## 📱 STEP 1: Start Mobile App (2 minutes)

### Option A: Android Emulator
```bash
cd "d:\Safe Mobile app system\safe_application_for_deafandmute"
flutter run
```

### Option B: Physical Device (RECOMMENDED for GPS)
```bash
cd "d:\Safe Mobile app system\safe_application_for_deafandmute"
flutter run -d <device-id>
```

**Login:**
- Use existing test account OR
- Register new account with phone number

**Wait for:**
- ✅ "Location Tracking Active" green indicator
- ✅ Coordinates appear (Latitude/Longitude)

---

## 💻 STEP 2: Start Admin Dashboard (1 minute)

### New Terminal:
```bash
cd "d:\Safe Mobile app system\safe_application_for_deafandmute\safe_admin_web"
flutter run -d chrome
```

**Login:**
- Email: admin@test.com
- Password: (your admin password)

**Navigate:**
1. Click "View Emergency Reports" card
2. You should see the Emergency Reports screen with:
   - Filter tabs at top
   - Empty list (no reports yet)
   - Map on right side (desktop)

---

## 🚨 STEP 3: Send Test Emergency (1 minute)

### On Mobile App:

1. **Select Category:**
   - Scroll down to "Select Emergency Category"
   - Tap "🏥 Medical"
   - Card should highlight with red border

2. **Select Subcategory:**
   - Subcategory buttons appear below
   - Tap "Heart Attack"

3. **(Optional) Attach Photo:**
   - Tap "📷 Attach Evidence Photo"
   - Choose any image
   - Photo preview appears

4. **Send:**
   - Scroll to bottom
   - Tap big red button: "🚨 SEND EMERGENCY REPORT"
   - Confirmation dialog appears
   - Review details
   - Tap "Send Alert"

5. **Success:**
   - Loading spinner appears
   - After 2-5 seconds: Green success message
   - "🚨 Medical emergency reported! Help is on the way."

---

## ✅ STEP 4: Verify in Admin Dashboard (30 seconds)

### On Admin Dashboard:

**Should automatically appear (NO REFRESH NEEDED):**

1. **Report List:**
   - New report card appears at top
   - "🚨 Medical Emergency"
   - Shows time (e.g., "2 seconds ago")
   - Status badge: "PENDING" (orange)

2. **Map (Right Side):**
   - Orange marker appears
   - Marker location = user's GPS coordinates
   - Map auto-zooms to show marker

3. **Click Marker:**
   - Info panel appears at bottom
   - Shows: Category, Address, Status
   - Map zooms to marker location

4. **Expand Report Card (Left Side):**
   - Click the card to expand details
   - See:
     - Category: Medical
     - Type: Heart Attack
     - User email
     - GPS coordinates
     - Address
     - Attached photo (if uploaded)
     - Medical ID (if medical emergency)

---

## 🎉 SUCCESS INDICATORS

### Mobile App ✅
- [x] Category selected (red highlight)
- [x] GPS coordinates showing
- [x] Success message appeared
- [x] Form reset after submission

### Admin Dashboard ✅
- [x] Report appeared within 2 seconds
- [x] Orange marker on map
- [x] Report shows in Pending tab
- [x] All details visible (category, location, etc.)
- [x] Dashboard pending count increased

---

## 🧪 Quick Test Workflow

### Test #1: Basic Medical Emergency
```
Mobile: Medical → Heart Attack → Send
Admin: ✅ Report appears with orange marker
```

### Test #2: Crime with Photo
```
Mobile: Crime → Robbery → Attach Photo → Send
Admin: ✅ Report shows with photo, can view image
```

### Test #3: Status Change
```
Admin: Click report → "Mark as Ongoing" → Confirm
Result: ✅ Marker turns red, moves to Ongoing tab
Admin: "Mark as Resolved" → Confirm
Result: ✅ Marker turns green, moves to Resolved tab
```

---

## 🐛 Troubleshooting

### Mobile: "Location access denied"
**Fix:** 
- Android: Settings → Apps → SAFE → Permissions → Location → Allow
- Restart app

### Admin: Report not appearing
**Fix:**
- Check if logged in
- Refresh browser (F5)
- Check browser console for errors (F12)

### Admin: Map not showing
**Fix:**
- Add Google Maps API key in `safe_admin_web/web/index.html`
- Replace `YOUR_API_KEY_HERE` with actual key

### Photo upload fails
**Fix:**
- Check internet connection
- Try smaller image
- Report still submits without photo

---

## 📊 What to Look For

### Timing
- Mobile send → Admin receive: **< 2 seconds**
- GPS lock time: **2-10 seconds**
- Photo upload: **2-5 seconds**

### Data Accuracy
- GPS coordinates match mobile location
- Geocoded address is readable
- Category/subcategory correct
- User email correct
- Timestamp accurate

### Real-time Updates
- No page refresh needed
- StreamBuilder auto-updates
- Marker appears instantly
- Count increments live

---

## 🚀 Advanced Testing

### Multiple Reports
1. Send 3 emergencies from mobile:
   - Medical
   - Crime  
   - Fire
2. Admin should see all 3 reports
3. Map shows 3 orange markers
4. Can filter by status

### Filter Testing
1. Admin: Mark one report as Ongoing
2. Mark one as Resolved
3. Test filters:
   - Pending → shows 1 report
   - Ongoing → shows 1 report
   - Resolved → shows 1 report
   - All → shows 3 reports

### Map Interaction
1. Click each marker
2. Verify info panel shows
3. Click "Open in Google Maps"
4. Should open correct location

---

## ✅ Success Criteria

**System is working if:**
- ✅ Mobile can submit emergency
- ✅ Admin receives in < 2 seconds
- ✅ GPS coordinates accurate
- ✅ Photo uploads successfully
- ✅ Map markers appear correctly
- ✅ Status workflow works (pending→ongoing→resolved)
- ✅ Real-time updates (no refresh needed)

---

## 📝 Test Results Log

**Date:** _______________

**Mobile App:**
- [ ] Emergency submission works
- [ ] GPS tracking accurate
- [ ] Photo upload successful
- [ ] Success message shows

**Admin Dashboard:**
- [ ] Report appears in < 2 seconds
- [ ] Map marker shows
- [ ] All data correct
- [ ] Status change works

**Issues Found:**
```
1. ___________________________
2. ___________________________
3. ___________________________
```

**Overall Status:** ⬜ PASS  ⬜ FAIL  ⬜ NEEDS WORK

---

**Ready to test? Start with STEP 1! 🚀**
