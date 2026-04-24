# NextStore

A modern e-commerce application.

## Features

- **User Authentication**: Secure login and signup with Firebase Auth.
- **Product Browsing**: Explore categories and products with ease.
- **Cart & Checkout**: Seamless shopping experience with cart management and coupon support.
- **Admin Dashboard**: Manage products, categories, coupons, and orders.
- **Order History**: Track and view past orders.
- **Profile Management**: Update user profile and manage addresses.

## Project Structure

```text
lib/
├── core/           # Core constants, themes, and models
│   ├── models/     # Data models for products, orders, etc.
│   └── utils/      # Helper functions and utilities
├── providers/      # State management using Provider
└── ui/             # UI layer
    ├── admin/      # Screens for the admin dashboard
    ├── auth/       # Authentication screens (Login, Signup)
    ├── customer/   # Customer-facing screens (Home, Cart, Profile)
    └── widgets/    # Reusable UI components
```

## Getting Started

Follow these steps to set up the project locally and connect it to your own Firebase instance.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10.8 or higher)
- [Node.js](https://nodejs.org/) (required for Firebase CLI)
- [Firebase CLI](https://firebase.google.com/docs/cli#install_the_firebase_cli) installed and logged in:
  ```bash
  npm install -g firebase-tools
  firebase login
  ```
- [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup?platform=ios#install-visual-studio-code) installed:
  ```bash
  dart pub global activate flutterfire_cli
  ```

### Installation & Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-username/nextstore.git
   cd nextstore
   ```

2. **Install dependencies:**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   Run the following command and follow the prompts to create a new Firebase project or select an existing one:

   ```bash
   flutterfire configure
   ```

   This will automatically update your `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and generate `lib/firebase_options.dart`.

4. **Enable Firebase Services:**
   Go to the [Firebase Console](https://console.firebase.google.com/) and enable:
   - **Authentication**: Enable the **Email/Password** provider.
   - **Cloud Firestore**: Create a database in **Test Mode** or with appropriate rules.
   - **Firebase Storage**: Create a default bucket for product images.

5. **Generate Assets (Optional):**
   If you change the icons or splash screen, regenerate them:

   ```bash
   flutter pub run flutter_launcher_icons
   flutter pub run flutter_native_splash:create
   ```

6. **Run the application:**
   ```bash
   flutter run
   ```

## Built With

- [Flutter](https://flutter.dev/) - The framework used.
- [Firebase](https://firebase.google.com/) - Backend services.
- [Provider](https://pub.dev/packages/provider) - State management.
