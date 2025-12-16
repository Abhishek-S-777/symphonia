# 💕 Symphonia

> **Your Love, Your Symphony**

An intimate companion app designed for couples to stay connected through heartbeats, messages, and shared memories.

![Flutter](https://img.shields.io/badge/Flutter-3.38.5-blue)
![Dart](https://img.shields.io/badge/Dart-3.8-blue)
![Platform](https://img.shields.io/badge/Platform-Android-green)
![License](https://img.shields.io/badge/License-Private-red)

---

## ✨ Features

### MVP Features (Implemented)
- **💓 Big Heart Button** - Central CTA with heartbeat vibration and elegant animations
- **💌 Quick Love Messages** - Predefined + custom messages with notifications
- **🎤 One-Tap Voice Notes** - Record 10-30 second audio notes
- **📸 Gallery / Timeline** - Photos + notes in chronological order
- **🔗 Device Pairing** - Secure pairing between two devices only

### Phase-1 Features (Coming Soon)
- Background Heartbeat Service
- Scheduled Surprises
- Geo-Triggered Greetings
- Countdowns & Events
- Emotional Journal

---

## 🏗️ Architecture

This app follows **Clean Architecture** with a **feature-first folder structure**:

```
lib/
├── core/           # Shared utilities, theme, constants
├── features/       # Feature modules (auth, home, messages, etc.)
├── shared/         # Reusable widgets and providers
└── database/       # Local database (Drift/SQLite)
```

### Tech Stack
- **State Management**: Riverpod
- **Navigation**: go_router
- **Local Database**: Drift (SQLite)
- **Backend**: Firebase (Auth, Firestore, Storage, FCM)
- **UI**: Material Design 3

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.38.5 or later
- Android Studio / VS Code
- An Android device or emulator (min SDK 24)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd "Dream App"
   ```

2. **Install dependencies**
   ```bash
   fvm flutter pub get
   ```

3. **Run the app**
   ```bash
   fvm flutter run
   ```

---

## 🔥 Firebase Setup

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project: `symphonia-app`
3. Disable Google Analytics (optional)

### Step 2: Register Android App
1. Click the Android icon to add an app
2. Package name: `com.symphonia.app`
3. Get SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

### Step 3: Enable Services
- **Authentication** → Email/Password
- **Firestore Database** → Create database
- **Storage** → Get started
- **Cloud Messaging** → Enabled by default

### Step 4: Update Code
1. Uncomment Firebase imports in `lib/main.dart`
2. Uncomment Google Services plugin in `android/app/build.gradle.kts`
3. Run `fvm flutter pub get`

---

## 📱 Permissions

The app requires the following permissions:
- **Notifications** - Receive partner's messages
- **Microphone** - Record voice notes
- **Storage** - Save photos and audio
- **Location** (optional) - Geo-triggered greetings
- **Background** - Heartbeat service

All permissions are requested upfront with clear explanations.

---

## 🎨 Design

### Color Palette
- **Primary**: Rose (#E85A7A)
- **Secondary**: Amber (#FFB347)
- **Accent**: Lavender (#B47ED8)

### Typography
- **Font**: Outfit (Google Fonts fallback)

### Design Principles
- Elegant & Premium
- Romantic but Minimal
- Emotionally Expressive

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp configuration
├── core/
│   ├── constants/               # App constants
│   ├── errors/                  # Failures and exceptions
│   ├── router/                  # Navigation routes
│   ├── theme/                   # Colors, typography, theme
│   ├── permissions/             # Permission manager
│   └── services/                # Vibration, notifications
├── features/
│   ├── auth/                    # Authentication & pairing
│   ├── home/                    # Home screen & heart button
│   ├── messages/                # Love messages
│   ├── voice_notes/             # Voice recordings
│   ├── gallery/                 # Photo timeline
│   ├── journal/                 # Emotional journal
│   ├── events/                  # Countdowns
│   └── settings/                # App settings
├── shared/
│   ├── widgets/                 # Reusable UI components
│   └── providers/               # Shared providers
└── database/                    # Local SQLite database
```

---

## 🔐 Security

- **Firestore Rules**: Strict couple-scoped access
- **No Global Feeds**: Data isolated per couple
- **Secure Storage**: Sensitive data encrypted
- **Device Verification**: Pairing code + device ID

---

## 📋 TODO Markers

Search for `TODO:` in the codebase to find:
- Firebase integration points
- Feature implementations
- Partner data connections

---

## 🚢 Deployment Checklist

### Before Release
- [ ] Add `google-services.json`
- [ ] Configure release signing (`android/app/build.gradle.kts`)
- [ ] Replace app icon
- [ ] Add privacy policy URL
- [ ] Test all permissions
- [ ] Test offline functionality
- [ ] Performance testing

### Play Store Requirements
- [ ] App icon (512x512)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone & tablet)
- [ ] Privacy policy
- [ ] App description

---

## 📄 License

This is a private application. All rights reserved.

---

## 💖 Made with Love

Built for a special someone. 💕
