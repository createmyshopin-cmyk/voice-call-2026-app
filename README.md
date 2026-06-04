# Coin-Based Voice Calling App

A Flutter application with a virtual coin system for voice calls.

## Features
- Firebase Phone Authentication (OTP + ID token).
- Real-time Coin Balance management with Firestore.
- Voice calling using Agora RTC Engine.
- Automatic coin deduction (10 coins/min) during active calls.
- Automatic call termination when balance is insufficient.

## Setup Instructions

### 1. Firebase Setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Phone** sign-in provider.
3. Add your Android app SHA-1/SHA-256 fingerprints in Project settings (required for Phone Auth on Android).
4. Create a **Firestore Database** (if using client-side wallet sync).
5. Register your Android/iOS app and download:
   - `google-services.json` to `android/app/`
   - `GoogleService-Info.plist` to `ios/Runner/`
5. Set `JWT_SECRET` in `admin panel/backend/.env` (see `.env.example`).
6. Place Firebase Admin `service-account.json` at `admin panel/backend/config/firebase/service-account.json`.

### 2. Agora Setup
1. Create a project in the [Agora Console](https://console.agora.io/).
2. Set `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` in `admin panel/backend/.env`.
3. Replace `YOUR_AGORA_APP_ID` in `lib/services/agora_service.dart` with your public App ID.
4. Tokens are generated only on the backend via `POST /api/agora/token` — never in Flutter.

### 3. Permissions
The app uses `permission_handler` to request microphone access. Ensure you add the following to your platform-specific files:

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.BLUETOOTH" />
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for voice calls.</string>
```

## How it works
1. **Login:** Users sign in with phone OTP via Firebase; the app sends the Firebase ID token to `POST /api/auth/firebase-login` for an API JWT.
2. **Wallet:** Initial balance is set to 100 coins (see `coin_provider.dart`).
3. **Calling:** 
   - Enter a channel name and tap "Start Call".
   - 10 coins are deducted immediately for the first minute.
   - 10 coins are deducted every 60 seconds thereafter.
   - If balance drops below 10, the call is automatically ended.
