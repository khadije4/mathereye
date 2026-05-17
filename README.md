# MotherEye — عين الأم

> Child digital safety platform for Arab and Mauritanian families  
> منصة حماية رقمية للأطفال للعائلات العربية والموريتانية

---

## Overview

MotherEye is a two-app system that protects children from online dangers — explicit content, grooming, and cyberbullying — while respecting family privacy. All detection runs **on-device**: no screenshots or personal data ever leave the phone.

| App | Who uses it | What it does |
|---|---|---|
| **Child app** | Runs on child's phone | Monitors screen silently in the background |
| **Parent app** | Runs on parent's phone | Receives alerts and AI-generated reports |

---

## Features

### Child App
- Screen capture every 3 seconds via Android MediaProjection
- On-device NSFW image detection (TensorFlow Lite — MobileNetV2, 5-class)
- On-device OCR via Google ML Kit (Latin + Franco-Arabic)
- 50+ danger keyword matching in Arabic, French, and Franco-Arabic
- Instant alert to parent via Firestore when threat is detected
- Parent PIN lock — child cannot deactivate without the code
- Simple pairing via 6-digit code

### Parent App
- Real-time push notifications (FCM) for every alert
- Live alert feed: NSFW images, danger phrases, specialist flags
- AI-generated behavioral reports powered by Groq (Llama 3.1)
  - Summary of what the child was doing
  - Psychological explanation of **why** a child would do it
  - Practical advice for the parent
  - Specialist referral with urgency level
  - Multi-session behavioral pattern detection

### AI Report Fields
```
riskLevel         → safe / monitor / alert / urgent
activityType      → homework / social / entertainment / risky / ...
summary_fr/ar     → plain-language summary for non-technical parents
whyTheyDoIt       → child psychology explanation (non-judgmental)
parentExplanation → what to know and do right now
specialistRecommendation → psychologist / school counselor / imam counselor / doctor
patternAlert      → isolation / grooming_victim / self_harm_risk / addiction / ...
recommendation    → one actionable step for the parent
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile framework | Flutter 3+ (Android) |
| Screen capture | Android MediaProjection API |
| NSFW detection | TensorFlow Lite (on-device, MobileNetV2) |
| OCR | Google ML Kit Text Recognition |
| AI analysis | Groq API — `llama-3.1-8b-instant` (free tier) |
| Real-time database | Firebase Firestore |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Local storage | SharedPreferences |

---

## Project Structure

```
mothereye/
├── lib/
│   ├── main_child.dart              # Child app entry point
│   ├── main_parent.dart             # Parent app entry point
│   ├── services/
│   │   ├── prefs_service.dart       # Local storage (PIN, IDs)
│   │   ├── firestore_service.dart   # Firestore read/write
│   │   ├── fcm_service.dart         # Push notifications
│   │   └── ai_agent_service.dart    # Groq API integration
│   ├── screens/
│   │   ├── child/
│   │   │   ├── pin_setup_screen.dart   # Parent PIN creation
│   │   │   ├── setup_screen.dart       # Pairing code display
│   │   │   └── home_screen.dart        # Monitoring toggle
│   │   └── parent/
│   │       ├── pairing_screen.dart     # Enter child's code
│   │       └── dashboard_screen.dart   # Alerts + AI reports
│   └── widgets/
│       ├── alert_card.dart          # Single alert display
│       └── report_card.dart         # Expandable AI report
├── android/app/src/main/
│   ├── kotlin/com/mothereye/app/
│   │   ├── MainActivity.kt          # Flutter ↔ Kotlin bridge
│   │   ├── ScreenCaptureService.kt  # Foreground capture service
│   │   ├── DetectionEngine.kt       # TFLite + ML Kit pipeline
│   │   ├── KeywordMatcher.kt        # Danger phrase matching
│   │   └── ActivityBuffer.kt        # Session text accumulator
│   ├── assets/
│   │   └── nsfw_model.tflite        # NSFW detection model
│   └── AndroidManifest.xml
└── pubspec.yaml
```

---

## Setup

### Prerequisites
- Flutter SDK 3.0+
- Android Studio / Android SDK (API 29+)
- Firebase project
- Groq API key (free at [console.groq.com](https://console.groq.com))

### 1. Clone and install dependencies
```bash
git clone <repo-url>
cd mothereye
flutter pub get
```

### 2. Firebase setup
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT
```

### 3. Add the NSFW model
Place `nsfw_model.tflite` at:
```
android/app/src/main/assets/nsfw_model.tflite
```
Compatible model: GantMan NSFW MobileNetV2 (5 classes: drawings, hentai, neutral, porn, sexy)

### 4. Firestore security rules
In Firebase Console → Firestore → Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /children/{childId} {
      allow read, write: if true;
      match /alerts/{alertId} { allow read, write: if true; }
      match /reports/{reportId} { allow read, write: if true; }
    }
  }
}
```

---

## Build

### Child APK
```bash
flutter build apk --debug -t lib/main_child.dart \
  --dart-define=GROQ_API_KEY=gsk_YOUR_KEY
cp build/app/outputs/flutter-apk/app-debug.apk mothereye-child.apk
```

### Parent APK
```bash
flutter build apk --debug -t lib/main_parent.dart \
  --dart-define=GROQ_API_KEY=gsk_YOUR_KEY
cp build/app/outputs/flutter-apk/app-debug.apk mothereye-parent.apk
```

> Both APKs share the same package name. Install each on a **separate device**.

---

## How to Use

### First-time child setup
1. Install `mothereye-child.apk` on child's phone
2. Create a 4-digit parent PIN (needed to deactivate the app)
3. Note the 6-digit pairing code shown on screen
4. Tap **Activate protection**

### Parent pairing
1. Install `mothereye-parent.apk` on parent's phone
2. Enter the 6-digit code from the child's phone
3. Dashboard opens — alerts and reports appear in real time

### Deactivating (parent only)
On the child app → tap the lock icon in the top bar → enter the PIN

---

## Privacy

| Data | Stays on device? |
|---|---|
| Screenshots | Never stored or sent |
| NSFW detection | 100% on-device (TFLite) |
| OCR text | Processed locally, only matched phrases sent |
| AI analysis input | Session text sent to Groq API only when parent requests it |
| Pairing codes | Stored in Firestore, no personal info |

---

## Detection Coverage

### Arabic
`أرسل صورتك` · `وين تسكن` · `لا تخبر أحد` · `أريد أن أموت` · `أكره نفسي` · and more

### French
`envoie ta photo` · `viens en privé` · `garde ça secret` · `je veux mourir` · and more

### Franco-Arabic
`3tini snap` · `3tini numero` · `wach nchufek` · `mach t9ol lwaldin` · and more

---

## Requirements

- Android 10+ (API 29) — required for MediaProjection foreground service
- Internet connection — for Firestore sync and AI analysis
- Screen capture permission — requested on first activation

---

## Built with

- [Flutter](https://flutter.dev)
- [Firebase](https://firebase.google.com)
- [Groq](https://groq.com) — free LLM inference
- [TensorFlow Lite](https://www.tensorflow.org/lite)
- [Google ML Kit](https://developers.google.com/ml-kit)

---

*Built during a hackathon to protect children in Arab and Mauritanian families.*  
*صُنع خلال هاكاثون لحماية أطفال العائلات العربية والموريتانية.*
