# Setup Guide for Miniature Paint Finder

## Completed Setup

1. Created new Flutter project named "Miniature Paint Finder"
2. Added Firebase dependencies in pubspec.yaml:
   - firebase_core
   - firebase_auth
   - cloud_firestore
   - firebase_storage
   - google_sign_in
3. Created basic app structure:
   - Models: Paint model
   - Repositories: PaintRepository for Firestore operations
   - Screens: SplashScreen, LoginScreen, and HomeScreen with tab navigation

## Next Steps

### Firebase Setup

1. Create a Firebase project at [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Set up Firebase for Flutter using FlutterFire CLI:
   ```
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   flutterfire configure --project=your-firebase-project-id
   ```
3. Enable Authentication in the Firebase console:
   - Email/Password authentication
   - Google Sign-In (optional)
4. Set up Firestore Database in the Firebase console
5. Configure Firebase Storage in the Firebase console

### Android-specific Setup

1. Install Android Studio: [https://developer.android.com/studio](https://developer.android.com/studio)
2. Configure Android SDK
3. Create an Android emulator or use a physical device

### iOS-specific Setup

1. Make sure Xcode is properly set up
2. Configure iOS signing certificates and provisioning profiles
3. Use an iOS simulator or a physical device for testing

## Running the App

After completing the setup steps above, you can run the app using:

```
flutter run
```

Or for specific platforms:

```
flutter run -d android
flutter run -d ios
``` 