# StreetSync Vendor Portal 🚀

A professional QR-based street food ordering system built with Flutter and Firebase.

## 🛠 Features
- **Vendor App:** Manage menu, real-time order tracking (Accept/Reject/Prepare), and live sales analytics.
- **Customer Web Menu:** Instant access via QR code, real-time stock sync, and live order progress tracking.
- **Automated Workflow:** Digital tokens, estimated wait times, and automated earnings calculation.

## 🚀 Setup Instructions for Collaborators

### 1. Prerequisites
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Install [Node.js](https://nodejs.org/) (required for Firebase CLI)
- Install [Firebase CLI](https://firebase.google.com/docs/cli#install_the_firebase_cli): `npm install -g firebase-tools`

### 2. Getting Started
1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/quickbite_vendor.git
   cd quickbite_vendor
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Authentication:**
   ```bash
   firebase login
   ```

### 3. Running the Project
- **Vendor App (Android/iOS):**
  ```bash
  flutter run
  ```
- **Customer Web Menu:**
  ```bash
  flutter run -d chrome --web-renderer canvaskit
  ```

### 4. Deployment (Web Only)
To update the live customer menu:
```bash
flutter build web --release
firebase deploy --only hosting
```

## 📂 Project Structure
- `lib/screens/auth`: Login, Signup, and OTP flow.
- `lib/screens/dashboard`: Home, Menu, Orders, and Sales screens.
- `lib/screens/customer`: Customer-facing web ordering page.
- `lib/services`: Firebase and Notification logic.
