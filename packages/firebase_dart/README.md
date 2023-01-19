[:heart: sponsor](https://github.com/sponsors/rbellens)


A pure Dart implementation of the Firebase client

Currently supports the following firebase services:

* Authentication
* Realtime database
* Cloud storage

As this is a pure dart implementation, it supports all platforms supported by dart, e.g. command line apps, web applications and flutter apps for android, ios, web, macos, windows and linux.

## Getting started

Initialize firebase_dart with the directory where the library should store data that should persist between runs. The storage path can be null, in which case no data will be stored on disk.

```dart
FirebaseDart.setup(storagePath: 'path/to/persistent/storage');
```

In flutter apps, you can use the `firebase_dart_flutter` library instead and initialize as follows. This will select an appropriate directory to store application data.

```dart
await FirebaseDartFlutter.setup();
```

The firebase code can also run in a separate isolate. This ensures that the main thread can be used for rendering tasks. To do this, simply set the isolated argument of the setup method to true. As isolates are not supported on web, this has no effect in a web environment.


Once the library is initialized, a firebase app can be created by calling:


```dart
var app = await Firebase.initializeApp(
    options: FirebaseOptions.fromMap(json
        .decode(File('example/firebase-config.json').readAsStringSync())));
```

## Unit testing

Unlike the native firebase libraries, this library allows to write unit tests without an external firebase emulator. 

To setup testing, import the testing implementation:

```dart
import 'package:firebase_dart/implementation/testing.dart';
```

and set it up:

```dart
await FirebaseTesting.setup();
```

Now, you can create an app and an associated backend:

```dart
var options = FirebaseOptions(
      appId: 'my_app_id',
      apiKey: 'apiKey',
      projectId: 'my_project',
      messagingSenderId: 'ignore',
      authDomain: 'my_project.firebaseapp.com');

var app = await Firebase.initializeApp(options: options);

var backend = FirebaseTesting.getBackend(app.options);
```

The backend can be used to add test users and store test data. E.g.:

```dart
await backend.authBackend.storeUser(BackendUser('user1')
      ..createdAt = clock.now().millisecondsSinceEpoch.toString()
      ..lastLoginAt = clock.now().millisecondsSinceEpoch.toString()
      ..email = 'user@example.com'
      ..rawPassword = 'password'
      ..providerUserInfo = [
        UserInfoProviderUserInfo()..providerId = 'password',
        UserInfoProviderUserInfo()..providerId = 'google.com',
      ]);
```


## Authentication

To get access to a Firebase Auth instance, call: 

```dart
var auth = FirebaseAuth.instanceFor(app: app);
```

This implementation does not yet support all functionalities of the firebase authentication service. Here is a list of functionalities with the current support status:

| method | supported? |
| ------ | ---------- |
| FirebaseAuth.applyActionCode | ✅
| FirebaseAuth.authStateChanges | ✅
| FirebaseAuth.checkActionCode | ✅
| FirebaseAuth.confirmPasswordReset | ✅
| FirebaseAuth.createUserWithEmailAndPassword | ✅
| FirebaseAuth.fetchSignInMethodsForEmail | ✅
| FirebaseAuth.getRedirectResult | ❌
| FirebaseAuth.idTokenChanges | ✅
| FirebaseAuth.isSignInWithEmailLink | ✅
| FirebaseAuth.sendPasswordResetEmail | ✅
| FirebaseAuth.sendSignInLinkToEmail | ✅
| FirebaseAuth.setLanguageCode | ✅
| FirebaseAuth.setPersistence | ❌
| FirebaseAuth.signInAnonymously | ✅
| FirebaseAuth.signInWithCredential | ✅
| FirebaseAuth.signInWithCustomToken | ✅
| FirebaseAuth.signInWithEmailAndPassword | ✅
| FirebaseAuth.signInWithEmailLink | ✅
| FirebaseAuth.signInWithPhoneNumber | ✅
| FirebaseAuth.signInWithPopup | ❌
| FirebaseAuth.signInWithRedirect | ❌
| FirebaseAuth.signInWithAuthProvider | ❌
| FirebaseAuth.signOut | ✅
| FirebaseAuth.userChanges | ✅
| FirebaseAuth.verifyPasswordResetCode | ✅
| FirebaseAuth.verifyPhoneNumber | ✅
| User.delete | ✅
| User.getIdToken | ✅
| User.getIdTokenResult | ✅
| User.linkWithCredential | ❌
| User.linkWithPhoneNumber | ❌
| User.reauthenticateWithCredential | ✅
| User.reload | ✅
| User.sendEmailVerification | ✅
| User.unlink | ✅
| User.updateEmail | ✅
| User.updatePassword | ✅
| User.updatePhoneNumber | ❌
| User.updateProfile | ✅
| User.verifyBeforeUpdateEmail | ❌
| User.multiFactor | ✅


[Multi-tenancy](https://cloud.google.com/identity-platform/docs/multi-tenancy) is currently not supported.

## Realtime database

To get access to a Firebase Database instance, call: 

```dart
var db = FirebaseDatabase(app: app);
```

The following methods are supported:

| method | supported? |
| ------ | ---------- |
| FirebaseDatabase.reference | ✅
| FirebaseDatabase.goOnline | ✅
| FirebaseDatabase.goOffline | ✅
| FirebaseDatabase.purgeOutstandingWrites | ✅
| FirebaseDatabase.setPersistenceEnabled | query results are stored, writes not
| FirebaseDatabase.setPersistenceCacheSizeBytes | ✅
| DatabaseReference.* | ✅



### Local database

Besides connecting to a remote firebase database, you can also create and work with a local in memory database. Use a database url with a `mem` scheme for this:

```dart
var db = new FirebaseDatabase(app: app, databaseURL: 'mem://some.name/');
```

### Query optimizations

The following optimizations are applied to queries to reduce the amount of network traffic:

* a query is not send to the server if other active queries already contain the result of this query
* if there are active queries that did not receive a result from the server yet, but might contain the result of this query, we wait for the result before we send a new query to the server
* multiple queries that limit their result to overlapping intervals are grouped together

Note: this feature is not included in official firebase clients. Because queries might be altered before sending them to the server, it is possible that queries are refused by the security rules which would otherwise not be refused. This should only happen with very particular security rules.  This will be fixed in a future version of this library.

## Cloud storage

To get access to a Firebase Storage instance, call: 

```dart
var storage = FirebaseStorage.instanceFor(app: app);
```

The following methods are supported:

| method | supported? |
| ------ | ---------- |
| FirebaseStorage.ref | ✅
| FirebaseStorage.refFromURL | ✅
| FirebaseStorage.maxDownloadRetryTime | ❌
| FirebaseStorage.maxOperationRetryTime | ❌
| FirebaseStorage.maxUploadRetryTime | ❌
| FirebaseStorage.setMaxDownloadRetryTime | ❌
| FirebaseStorage.setMaxOperationRetryTime | ❌
| FirebaseStorage.setMaxOperationRetryTime | ❌
| Reference.delete | ✅
| Reference.getData | ✅
| Reference.getDownloadURL | ✅
| Reference.getMetadata | ✅
| Reference.list | ✅
| Reference.listAll | ✅
| Reference.putData | ✅
| Reference.putString | ✅
| Reference.updateMetadata | ✅


## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/appsup-dart/firebase_dart/issues

## Sponsor

Creating and maintaining this package takes a lot of time. If you like the result, please consider to [:heart: sponsor](https://github.com/sponsors/rbellens). 
With your support, I will be able to further improve and support this project.
Also, check out my other dart packages at [pub.dev](https://pub.dev/packages?q=publisher%3Aappsup.be).

Many thanks to [Tim Whiting](https://github.com/TimWhiting) for his support.
