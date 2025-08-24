

Provides a `firebase_dart` auth handler for sign in with Apple using the native Apple API.


## Usage


Initialize `FirebaseDartFlutter` with the auth handler. 

```dart
await FirebaseDartFlutter.setup(
    socialAuthHandlers: [
        AppleAuthHandler(),
    ],
);
```

Start sign in process:

```dart
await auth.signInWithPopup(OAuthProvider('apple.com'));
```

### integration

See: https://pub.dev/packages/sign_in_with_apple