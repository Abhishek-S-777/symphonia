# 💕 Symphonia

> **Your Love, Your Symphony**

A private, intimate companion app designed exclusively for couples to stay deeply connected through heartbeats, hugs, messages, voice notes, shared memories, and special events.

![Flutter](https://img.shields.io/badge/Flutter-3.38.5-blue)
![Dart](https://img.shields.io/badge/Dart-3.8-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![Firebase](https://img.shields.io/badge/Backend-Firebase-orange)
![License](https://img.shields.io/badge/License-Private-red)

---

## ✨ Features

### 💓 Heartbeat
- **One-tap heartbeat** - Send your heartbeat to your partner instantly
- **Custom vibration pattern** - Realistic lub-dub heartbeat feel
- **Real-time delivery** - Partner's phone vibrates immediately
- **Works in background** - Vibrates even when app is closed/killed
- **Firestore listener** - Real-time sync for foreground notifications

### 🤗 Hugs & Kisses
- **Long-press to hug** - Hold to build up hug duration (1-10 seconds)
- **Amber-themed UI** - Beautiful glowing button with particle animations
- **Custom vibration** - Long vibration (hug) + short vibration (kiss)
- **Visual feedback** - Growing animation, timer display, sparkle effects
- **Swipe to toggle** - Easily switch between heartbeat and hugs mode

### 💌 Love Messages
- **Quick messages** - Predefined romantic messages for fast sending
- **Custom messages** - Write your own love notes
- **Rich bubbles** - Beautiful message UI with sender info and timestamps
- **Read receipts** - Know when partner has seen your message
- **Unread count** - Badge showing unread messages

### 📝 Daily Love Note
- **Custom quotes** - Set a personalized love note for your partner
- **Real-time sync** - Both partners see the same quote instantly
- **Firestore-powered** - Synced across devices via StreamProvider
- **Default fallback** - "I love you infinity always" when no custom quote

### 🎤 Voice Notes
- **One-tap recording** - Hold to record, release to send
- **Waveform visualization** - See audio levels while recording
- **Duration display** - Shows recording length
- **Cloud storage** - Uploaded to Firebase Storage
- **Offline pending** - Records offline, uploads when connected

### 📸 Gallery / Memories
- **Photo timeline** - Share photos in chronological order
- **Multiple images** - Upload multiple photos per memory
- **Notes** - Add captions and notes to memories
- **Date picker** - Set specific dates for memories
- **Cloud sync** - Images stored in Firebase Storage

### 📅 Events & Countdowns
- **Special dates** - Track anniversaries, birthdays, and milestones
- **Countdown display** - See days remaining until each event
- **Recurring events** - Yearly, monthly, or one-time events
- **Dual notifications**:
  - **Cloud Function** - Sends reminders at 3:30 AM for 1, 3, 7, 30 days before
  - **Local notifications** - Fires at user-configured time
- **Today alerts** - Special notification on the day of the event

### 🔐 Biometric Lock
- **Fingerprint / Face ID** - Secure app with biometrics
- **Cold start protection** - Locks on app launch
- **Background lock** - Locks when returning from background
- **Graceful fallback** - Device PIN/pattern as backup
- **Cloud sync** - Biometric preference synced to Firestore

### 🔗 Partner Pairing
- **Secure pairing code** - 6-digit code valid for 24 hours
- **One-to-one only** - Exclusively for two devices
- **Automatic discovery** - Finds partner when code is entered
- **Anniversary setting** - Set your relationship start date

### ⚙️ Settings
- **Profile management** - Update display name and photo
- **Anniversary date** - Change relationship start date
- **Biometric toggle** - Enable/disable biometric lock
- **Logout** - Secure sign out with data cleanup

---

## 🔔 Notifications

### Push Notifications (FCM)
| Type | When Triggered | Behavior |
|------|----------------|----------|
| Heartbeat | Partner sends heartbeat | Data-only → Custom vibration + notification |
| Hugs | Partner sends hugs | Data-only → Custom vibration + notification |
| Message | Partner sends message | Standard notification with vibration |
| Voice Note | Partner sends voice note | Standard notification |
| Event Created | Partner creates event | Standard notification |
| Event Countdown | 1, 3, 7, 30 days before | Cloud Function at 3:30 AM IST |
| Event Today | On the event day | Cloud Function + Local notification |

### Local Notifications
- Scheduled at user-preferred times
- Work offline (no internet required)
- Persist across app restarts

---

## 🏗️ Architecture

### Clean Architecture + Feature-First Structure

```
lib/
├── main.dart                    # App entry point, Firebase init
├── app.dart                     # MaterialApp, global listeners
├── core/
│   ├── constants/               # Firebase collections, storage keys
│   ├── router/                  # go_router configuration
│   ├── theme/                   # Colors, gradients, typography
│   ├── permissions/             # Permission manager (all-at-once)
│   └── services/
│       ├── auth_service.dart    # Firebase Auth + user providers
│       ├── message_service.dart # Messages + heartbeat/hugs listeners
│       ├── audio_service.dart   # Voice note recording/playback
│       ├── gallery_service.dart # Memory CRUD operations
│       ├── event_service.dart   # Events + local notifications
│       ├── quote_service.dart   # Daily love note (StreamProvider)
│       ├── biometrics_service.dart # Biometric lock
│       ├── vibration_service.dart  # Custom vibration patterns
│       └── fcm_service.dart     # Push notifications + background handler
├── features/
│   ├── auth/                    # Login, pairing, splash, biometric lock
│   ├── home/                    # Heart button, hugs button, daily quote
│   ├── messages/                # Message list and bubbles
│   ├── voice_notes/             # Voice note player
│   ├── gallery/                 # Photo timeline, add memory
│   ├── events/                  # Event list, add/edit event
│   └── settings/                # Profile, preferences
├── shared/
│   └── widgets/                 # GradientCard, AppSnackbar, etc.
└── database/                    # Drift (SQLite) - offline support
```

### Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.38.5 |
| **Language** | Dart 3.8 |
| **State Management** | Riverpod (Async + Stream Providers) |
| **Navigation** | go_router |
| **Backend** | Firebase (Auth, Firestore, Storage, FCM) |
| **Cloud Functions** | Node.js (Firebase Functions v2) |
| **Local Database** | Drift (SQLite) |
| **Notifications** | flutter_local_notifications + FCM |
| **Biometrics** | local_auth |
| **Animations** | flutter_animate |

---

## 🔥 Firebase Services

### Authentication
- Email/Password sign-in
- Persistent session with SharedPreferences fallback
- User document in `/users/{userId}`

### Firestore Structure
```
users/{userId}
  ├── email, displayName, photoUrl
  ├── coupleId, fcmToken, deviceId
  ├── biometricsEnabled, isOnline, lastActive
  └── createdAt

couples/{coupleId}
  ├── user1Id, user2Id
  ├── user1Email, user2Email
  ├── anniversaryDate, pairedAt
  ├── customQuote: { quote, author, authorId, setAt }
  ├── messages/{messageId}
  │     └── senderId, content, type, sentAt, readAt
  ├── voiceNotes/{voiceNoteId}
  │     └── senderId, storageUrl, duration, createdAt
  ├── memories/{memoryId}
  │     └── creatorId, imageUrls, note, date
  └── events/{eventId}
        └── creatorId, title, eventDate, isRecurring

pairingCodes/{code}
  └── creatorId, createdAt, expiresAt
```

### Cloud Functions (`symphonia-functions/`)
| Function | Trigger | Purpose |
|----------|---------|---------|
| `onMessageCreated` | Firestore onCreate | Send FCM notification to partner |
| `onVoiceNoteCreated` | Firestore onCreate | Send voice note notification |
| `onEventCreated` | Firestore onCreate | Notify partner of new event |
| `sendEventReminders` | Scheduled (3:30 AM IST) | Daily countdown notifications |

### Required Firestore Indexes
```json
{
  "indexes": [
    { "collection": "messages", "fields": ["type", "senderId", "sentAt"] },
    { "collection": "messages", "fields": ["senderId", "readAt"] }
  ],
  "fieldOverrides": [
    { "collection": "voiceNotes", "field": "createdAt" },
    { "collection": "memories", "field": "date" },
    { "collection": "events", "field": "eventDate" }
  ]
}
```

---

## 📱 Permissions

| Permission | Usage | Required |
|------------|-------|----------|
| Notifications | Receive partner's messages/heartbeats | ✅ |
| Microphone | Record voice notes | ✅ |
| Storage | Save photos and audio | ✅ |
| Biometrics | App lock (fingerprint/face) | Optional |
| Internet | Cloud sync | ✅ |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.38.5+ (via FVM recommended)
- Android Studio / VS Code
- Android device/emulator (min SDK 24) or iOS device
- Firebase project

### Installation

```bash
# Clone repository
git clone <repository-url>
cd symphonia

# Install Flutter dependencies
fvm flutter pub get

# Run the app
fvm flutter run
```

### Firebase Setup

1. **Create Firebase Project** at [console.firebase.google.com](https://console.firebase.google.com)

2. **Register Android App**
   - Package: `com.symphonia.app`
   - Add SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey`
   - Download `google-services.json` → `android/app/`

3. **Enable Services**
   - Authentication → Email/Password
   - Firestore → Create database
   - Storage → Get started
   - Cloud Messaging → Enabled by default

4. **Deploy Cloud Functions**
   ```bash
   cd symphonia-functions
   npm install
   firebase deploy --only functions
   ```

5. **Deploy Firestore Indexes**
   ```bash
   firebase deploy --only firestore:indexes
   ```

---

## 🎨 Design System

### Color Palette
| Color | Hex | Usage |
|-------|-----|-------|
| Primary (Rose) | `#E85A7A` | Heartbeat, primary actions |
| Hugs (Amber) | `#FFB347` | Hugs button, warm accents |
| Accent (Lavender) | `#B47ED8` | Secondary actions |
| Background (Dark) | `#1A1418` | Main background |
| Surface (Dark) | `#2D2529` | Cards, dialogs |

### Typography
- **Display**: Lavishly Yours (cursive, branding)
- **Body**: Outfit (clean, modern)

### Design Principles
- 🌙 Dark mode first
- ✨ Glassmorphism & gradients
- 💫 Smooth micro-animations
- 💕 Romantic but minimal

---

## 🔐 Security

- **Firestore Rules**: Strict couple-scoped access
- **No Global Feeds**: Data isolated per couple
- **Biometric Lock**: Optional fingerprint/face protection
- **FCM Data-Only**: Sensitive messages use data-only for custom handling
- **Device Binding**: Pairing verified with device ID

---

## 📋 Development

### Run in Debug Mode
```bash
fvm flutter run --debug
```

### Build Release APK
```bash
fvm flutter build apk --release
```

### Analyze Code
```bash
fvm flutter analyze
```

### Deploy Cloud Functions
```bash
cd symphonia-functions
firebase deploy --only functions
```

---

## 🚢 Release Checklist

- [ ] Add production `google-services.json`
- [ ] Configure release signing key
- [ ] Update app icon (512x512)
- [ ] Add privacy policy URL
- [ ] Test all features on release build
- [ ] Test offline functionality
- [ ] Verify push notifications (background + killed)
- [ ] Check biometric lock on cold start
- [ ] Performance profiling

---

## 📄 License

This is a private application. All rights reserved.

---

## 💖 Made with Love

Built for a special someone. 💕

*Symphonia - Because every moment with you is music.* 🎵
