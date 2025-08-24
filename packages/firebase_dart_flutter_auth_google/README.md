

Provides a `firebase_dart` handler for sign in with Google using the native Google API.


## Usage


Initialize `FirebaseDartFlutter` with the auth handler. 

```dart
await FirebaseDartFlutter.setup(
    socialAuthHandlers: [
        GoogleAuthHandler(),
    ],
);
```

Start sign in process:

```dart
await auth.signInWithPopup(GoogleAuthProvider());
```

### iOS and MacOS integration


Make sure you provide a `iosClientId` when initializing the app. This can be copied from the GoogleService-Info.plist key CLIENT_ID. 

```dart
var app = await Firebase.initializeApp(options: FirebaseOptions(
    ...,
    iosClientId: '[YOUR IOS CLIENT ID]'
));
```

Add the `CFBundleURLTypes` to the `Info.plist` file in the `ios/Runner` or `macos/Runner` directory.

```plist
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>[YOUR REVERSED_CLIENT_ID FROM GoogleService-Info.plist]</string>
		</array>
	</dict>
</array>
```

See also: https://pub.dev/packages/google_sign_in_ios

### Android integration

No additional configuration required.

See also: https://pub.dev/packages/google_sign_in_android

### Web integration

On web, will fall back to default auth handler. 

