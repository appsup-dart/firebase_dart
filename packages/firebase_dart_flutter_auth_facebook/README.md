[![Ceasefire Now](https://badge.techforpalestine.org/default)](https://techforpalestine.org/learn-more)



Provides a `firebase_dart` auth handler for sign in with Facebook using the native Facebook API.


## Usage


Initialize `FirebaseDartFlutter` with the auth handler. 

```dart
await FirebaseDartFlutter.setup(
    socialAuthHandlers: [
        FacebookAuthHandler(
            facebookAppIdForFirebaseApp: (app) => '[YOUR FACEBOOK APP ID]',
        ),
    ],
);
```

Start sign in process:

```dart
await auth.signInWithPopup(FacebookAuthProvider());
```

### integration

See: https://pub.dev/packages/flutter_facebook_auth