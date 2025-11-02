# Emergency Report Photo and Video Attachment Feature

## Overview
Ang mobile app ngayon ay sumusuporta ng parehong **photos at videos** para sa emergency report evidence attachment.

## Mga Features

### 📸 Photo Attachment
- **Maximum**: 3 photos per emergency report
- **Quality**: Optimized to 1024x1024 pixels, 85% quality
- **Source Options**:
  - Take Photo (Camera)
  - Choose from Gallery

### 🎥 Video Attachment
- **Maximum**: 2 videos per emergency report
- **Duration Limit**: 30 seconds per video
- **File Size Limit**: 50MB per video
- **Source Options**:
  - Record Video (Camera)
  - Choose from Gallery

## User Flow

### 1. Attach Evidence
Pag-click ng **"Add Photo or Video Evidence"** button:
1. Pipili ng media type: **Photo** o **Video**
2. Pipili ng source: **Camera** o **Gallery**
3. I-attach ang selected media

### 2. Preview Attached Media
- **Photos**: Thumbnail preview (100x100)
  - Shows actual image
  - Counter: "Photos (X/3)"
  
- **Videos**: Video placeholder icon
  - Play icon indicator
  - Counter: "Videos (X/2)"
  - Shows file size

### 3. Remove Attached Media
- Click red X button sa bawat attachment para i-remove

### 4. Send Emergency Report
Kasama sa confirmation dialog:
- ✓ Number of photos attached
- ✓ Number of videos attached
- ✓ Location sharing
- ✓ Medical ID & Emergency Contacts

## Firebase Storage Structure

### Photos
```
emergency_images/
  ├── {userId}/
      ├── {timestamp}_0.jpg
      ├── {timestamp}_1.jpg
      └── {timestamp}_2.jpg
```

### Videos
```
emergency_videos/
  ├── {userId}/
      ├── {timestamp}_0.mp4
      └── {timestamp}_1.mp4
```

## Firestore Document Structure

```javascript
emergency_reports/{reportId}
{
  userId: "user123",
  userEmail: "user@example.com",
  category: "Medical Emergency",
  subcategory: "Heart Attack",
  status: "pending",
  timestamp: Timestamp,
  location: {
    latitude: 14.5995,
    longitude: 120.9842,
    address: "Manila, Philippines"
  },
  imageUrls: [
    "https://firebasestorage.../image_0.jpg",
    "https://firebasestorage.../image_1.jpg"
  ],
  videoUrls: [
    "https://firebasestorage.../video_0.mp4"
  ],
  medicalData: {
    medicalId: {...},
    personalDetails: {...},
    emergencyContacts: {...}
  }
}
```

## Validation & Limits

### Photos
- ✅ Maximum 3 photos
- ✅ Auto-compressed to 1024x1024
- ✅ Quality reduced to 85%
- ❌ Exceeded limit shows warning

### Videos
- ✅ Maximum 2 videos
- ✅ 30-second duration limit
- ✅ 50MB file size limit
- ❌ File too large shows warning
- ❌ Exceeded limit shows warning

## Error Handling

### Camera/Gallery Access
```dart
try {
  // Pick image or video
} catch (e) {
  ScaffoldMessenger.showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}'))
  );
}
```

### Upload Failures
- Images at videos ay optional
- Upload error ay hindi mag-block ng emergency report
- Success message kahit may upload error (fail-safe approach)

## UI Components

### Attachment Button
```dart
OutlinedButton.icon(
  onPressed: _attachPhoto,
  icon: const Icon(Icons.add_a_photo),
  label: Text(
    _attachedImages.isEmpty && _attachedVideos.isEmpty
        ? 'Add Photo or Video Evidence'
        : 'Add More Evidence',
  ),
)
```

### Photo Preview
- Grid layout with thumbnails
- Remove button (red X) per image
- Shows actual photo preview

### Video Preview
- Black background container
- Play icon indicator
- "Video" label
- Remove button (red X)

## Success Messages

### Photo Attached
```
📸 Photo 1/3 attached successfully
```

### Video Attached
```
🎥 Video 1/2 attached successfully (15.5MB)
```

### Limit Warnings
```
⚠️ Maximum 3 photos allowed
⚠️ Maximum 2 videos allowed
⚠️ Video too large! Maximum 50MB per video
```

## Benefits para sa Emergency Response

1. **Visual Evidence**: Photos for injury, accident damage, fire location
2. **Live Documentation**: Videos for ongoing situations, movements
3. **Better Assessment**: Responders can prepare appropriate resources
4. **Faster Response**: Clear evidence = better preparation
5. **Multiple Angles**: Up to 3 photos + 2 videos = comprehensive documentation

## Technical Implementation

### Dependencies
- `image_picker: ^1.1.2` - Photo & video picker
- `firebase_storage: ^12.3.2` - File uploads
- `cloud_firestore: ^5.4.3` - Data storage

### Key Functions
- `_attachPhoto()` - Media selection dialog
- `_submitEmergencyReport()` - Upload & save
- Image/Video upload to Firebase Storage
- URL storage sa Firestore

## Future Enhancements

### Pwedeng idagdag:
1. Video compression before upload
2. Video thumbnail generation
3. In-app video playback
4. Image annotation (arrows, circles)
5. Voice recording attachment
6. Location photo tagging
7. Automatic evidence organization

---

**Date Created**: November 3, 2025  
**Version**: 1.0  
**Status**: ✅ Implemented & Tested
