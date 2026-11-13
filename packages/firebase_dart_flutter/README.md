[![Ceasefire Now](https://badge.techforpalestine.org/default)](https://techforpalestine.org/learn-more)


[:heart: sponsor](https://github.com/sponsors/rbellens)

A pure Dart implementation of the Firebase client with some Flutter specific extensions.

See [firebase_dart](https://pub.dev/packages/firebase_dart) package for more details on Authentication, Realtime Database, Cloud Storage, and App Check.

## App Check on Flutter

Import `package:firebase_dart/app_check.dart` and `package:firebase_dart_flutter/firebase_dart_flutter.dart`, then activate with `FlutterAppCheckProviders`. It builds an ordered provider list for the current platform:

| Platform | Default providers (when enabled) |
| -------- | -------------------------------- |
| **Android** | `PlayIntegrityAppCheckProvider` |
| **iOS** | `AppAttestAppCheckProvider`, `DeviceCheckAppCheckProvider` |
| **macOS** | `AppAttestAppCheckProvider`, `DeviceCheckAppCheckProvider` |
| **Web** | `ReCaptchaV3Provider` / `ReCaptchaEnterpriseProvider` from site keys |
| **Fallback** | `RecaptchaWebViewAppCheckProvider` when `recaptchaWebDomain`, `recaptchaWebAppId`, and `getBuildContext` are set |

```dart
import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart_flutter/firebase_dart_flutter.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// In main(), after FirebaseDartFlutter.setup() and Firebase.initializeApp():
await FirebaseAppCheck.instance.activate(
  provider: FlutterAppCheckProviders(
    recaptchaV3SiteKey: '6Le...', // from Firebase Console → App Check
    recaptchaEnterpriseSiteKey: '6Le...', // optional
    recaptchaWebDomain: 'my-project.firebaseapp.com',
    recaptchaWebAppId: DefaultFirebaseOptions.currentPlatform.appId,
    getBuildContext: () => navigatorKey.currentContext,
    // usePlayIntegrity: true,
    // useAppAttest: true,
    // useDeviceCheck: true,
  ),
);
```

For a single native provider in tests or minimal apps:

```dart
await FirebaseAppCheck.instance.activate(
  provider: const PlayIntegrityAppCheckProvider(),
);
```

On iOS and macOS, `AppAttestAppCheckProvider.isSupported()` indicates whether App Attest is available (iOS 14+ or macOS 11+ on a supported device). For local development on any platform, use `AppCheckProvider.debug` from `firebase_dart` and register the debug token in the Firebase Console.

Auth, Storage, and Realtime Database pick up App Check tokens automatically once activated; see the [firebase_dart App Check section](https://github.com/appsup-dart/firebase_dart/blob/main/packages/firebase_dart/README.md#app-check).

## Sponsor

Creating and maintaining this package takes a lot of time. If you like the result, please consider to [:heart: sponsor](https://github.com/sponsors/rbellens). 
With your support, I will be able to further improve and support this project.
Also, check out my other dart packages at [pub.dev](https://pub.dev/packages?q=publisher%3Aappsup.be).

Many thanks to [Tim Whiting](https://github.com/TimWhiting) for his support.
