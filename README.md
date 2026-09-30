# 🛡️ Expiro — Smart Digital Warranty Vault

<p align="center">
  <img src="https://raw.githubusercontent.com/Manavmodi0807/Expiro/main/assets/banner.png" alt="Expiro Banner" width="100%" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>Never lose a receipt or miss a warranty expiration again.</b><br>
  Expiro is a modern, cross-platform mobile application built with Flutter and Firebase that centralizes your product warranties, invoices, repair records, and user manuals into an intelligent, secure digital vault.
</p>

<p align="center">
  <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-v3.13+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-v3.1+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://firebase.google.com/"><img src="https://img.shields.io/badge/Firebase-Auth%20|%20Firestore%20|%20Storage-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"></a>
  <a href="https://developers.google.com/ml-kit"><img src="https://img.shields.io/badge/ML%20Kit-OCR%20Text%20Recognition-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="ML Kit"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License"></a>
</p>

---

## 🌟 Key Features

### 📦 1. Product & Warranty Management
- **Centralized Inventory**: Track all your electronics, appliances, vehicles, and valuables in one place.
- **Dynamic Warranty Status**: Real-time status badges (*Active*, *Expiring Soon*, *Expired*) calculated dynamically based on warranty duration and purchase dates.
- **Detailed Product Records**: Store serial numbers, models, purchase prices, retailer details, extended warranty terms, and custom notes.

### 🤖 2. Smart OCR Bill & Receipt Scanner
- **Google ML Kit Integration**: On-device machine learning extracts key metadata directly from photos and scans of paper receipts.
- **Automatic Field Detection**: Automatically extracts and populates retailer name, invoice date, purchase amount, invoice/bill number, and warranty terms to eliminate manual typing.

### 📂 3. Digital Document Vault
- **Multi-Document Support**: Attach receipts, invoices, warranty cards, repair receipts, and PDF user manuals to any product.
- **Cloud Storage & Security**: Documents are securely uploaded to Firebase Storage with granular Firestore access rules per user.
- **Built-in PDF & Image Viewer**: Inspect documents and zoom in on high-resolution receipts directly within the app without third-party readers.

### 🔔 4. Proactive Expiry Notifications
- **Local Push Notifications**: Automated alerts scheduled via `flutter_local_notifications` and `timezone`.
- **Custom Alert Windows**: Get reminded 30 days before, 7 days before, and on the day of warranty expiration so you can claim service or buy extended warranties in time.

### 📊 5. Insightful Dashboard & Filtering
- **Analytics Overview**: Live counters showing total protected products, active warranties, items expiring soon, and estimated value of items under warranty.
- **Instant Search & Multi-Filters**: Filter by category (Electronics, Home Appliances, Gadgets, etc.), status, retailer, and sort by expiration or purchase date.

### 🎨 6. Premium Modern UI/UX
- **Sleek Aesthetic**: Crafted with curated color palettes, elegant cards, smooth transitions, and tactile feedback.
- **Responsive Layout**: Designed for seamless accessibility across phone and tablet screens of all sizes.

---

## 🏗️ Architecture & Tech Stack

```
lib/
├── firebase_options.dart      # Auto-generated Firebase configuration
├── main.dart                  # Application entry point & service initialization
├── models/                    # Immutable data models & JSON/Firestore serializers
│   ├── product_model.dart
│   ├── product_document_model.dart
│   └── product_filter_model.dart
├── screens/                   # UI Screens & Views
│   ├── auth/                  # Login & Registration flows
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── auth_wrapper.dart      # Dynamic Auth state router
│   ├── home_screen.dart       # Main dashboard, search & item listing
│   ├── products/              # Add / Edit product forms
│   │   └── product_form_screen.dart
│   └── documents/             # OCR scanner, document list & viewer
│       ├── ocr_scan_screen.dart
│       ├── product_documents_screen.dart
│       └── document_viewer_screen.dart
├── services/                  # Business logic, Cloud & Hardware integrations
│   ├── auth_service.dart          # Firebase Authentication
│   ├── product_service.dart       # Cloud Firestore CRUD for products
│   ├── document_service.dart      # Firebase Storage + Firestore for files
│   ├── ocr_service.dart           # Google ML Kit Text Recognition parser
│   └── notification_service.dart  # Scheduled local notifications
├── theme/                     # Design tokens, typography & app theme definitions
│   └── app_theme.dart
└── widgets/                   # Modular, reusable UI components
    ├── status_badge.dart
    └── empty_state_view.dart
```

### Core Technologies
- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.13.2`)
- **Backend / Cloud**:
  - **Firebase Authentication**: Secure user identity and session management
  - **Cloud Firestore**: Real-time NoSQL database with user-isolated queries
  - **Firebase Storage**: Cloud storage for document images and PDF manuals
- **On-Device Machine Learning**: `google_mlkit_text_recognition`
- **Notifications**: `flutter_local_notifications`, `timezone`
- **File & Media Handling**: `image_picker`, `file_picker`, `flutter_pdfview`, `path_provider`

---

## 🚀 Getting Started

### Prerequisites
Before running the application, make sure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.13.2`)
- [Dart SDK](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) / Xcode (for iOS)
- [Firebase CLI](https://firebase.google.com/docs/cli) & [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)

### 1. Clone the Repository
```bash
git clone https://github.com/Manavmodi0807/Expiro.git
cd Expiro
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Firebase
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** (Email/Password), **Cloud Firestore**, and **Firebase Storage**.
3. Run FlutterFire CLI to configure your app:
   ```bash
   flutterfire configure
   ```
4. Deploy the Firestore and Storage security rules provided in the root directory:
   ```bash
   firebase deploy --only firestore:rules,storage
   ```

### 4. Run the App
Launch on an emulator or a connected physical device:
```bash
flutter run
```

---

## 🔒 Security Rules

Expiro enforces strict per-user authorization rules so that users can only read and write their own documents and products:

<details>
<summary><b>View Firestore Security Rules</b></summary>

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
</details>

<details>
<summary><b>View Firebase Storage Security Rules</b></summary>

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
</details>

---

## 📱 Screenshots & Demo

| Dashboard & Overview | OCR Smart Scanner | Document Vault |
| :---: | :---: | :---: |
| *Active & Expiring Tracker* | *Receipt Auto-Extraction* | *Secure Multi-File Vault* |

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: add some amazing feature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ using Flutter & Firebase
</p>
