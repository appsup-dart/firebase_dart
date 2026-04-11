# firebase_dart_flutter_example

Demonstrates how to use the firebase_dart_flutter plugin.

## Firebase Auth URL schemes (iOS / macOS)

Firebase Auth on Apple platforms needs your app’s **custom URL scheme** in `Info.plist` for flows such as OAuth sign-in (for example Microsoft) and phone auth reCAPTCHA redirects. The scheme is derived from the Firebase iOS `GOOGLE_APP_ID` (`app-` plus the id with `:` replaced by `-`).

This example does not require you to maintain those entries by hand:

1. **Generate options in `package:_integration_testing`** so `allConfigs` includes your Firebase iOS app(s). From [`packages/_integration_testing`](../../_integration_testing), run:

   ```sh
   dart run tool/generate_firebase_web_config.dart
   ```

   See that package’s README for flags and API credentials.

2. **Build in Xcode or via Flutter** as usual. A **Run Script** build phase (already added in the iOS and macOS `Runner` targets) runs [`tool/add_firebase_auth_url_schemes.dart`](tool/add_firebase_auth_url_schemes.dart). It reads `allConfigs`, picks the `FirebaseOptions` for the current bundle id, and **merges the needed `CFBundleURLTypes` into the built app’s `Info.plist`** before codesigning.

Optional environment variables for the script are documented on `XcodeBuildEnvironment` in that Dart file (for example `FIREBASE_INTEGRATION_LOOKUP_BUNDLE_ID` when the Xcode bundle id differs from the one in generated options).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
