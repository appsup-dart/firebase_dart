## 1.1.0-dev.9

 - **REFACTOR**(database): create MasterView for default query when non limiting query. ([e087089f](https://github.com/appsup-dart/firebase_dart/commit/e087089fa90b20c3577f9d717939a166b2f8a0fd))
 - **REFACTOR**(database): refactor PrioritizedQueryRegistrar. ([d06a8c80](https://github.com/appsup-dart/firebase_dart/commit/d06a8c805e05df2d63d2d172cb78cf150757311f))
 - **PERF**(database): always send a hash on a listen request. ([7534afc1](https://github.com/appsup-dart/firebase_dart/commit/7534afc1b09124f26c5f24bad466a3dfb234608c))
 - **FIX**(database): fixed pruning of persistent cache. ([a14d84bc](https://github.com/appsup-dart/firebase_dart/commit/a14d84bcd39019499660e1b95ba19e8c5ab2c66c))

## 1.1.0-dev.8

 - **FIX**(database): should throw permission denied error when permission changes while listening. ([b45a7a5e](https://github.com/appsup-dart/firebase_dart/commit/b45a7a5ec327b28871824515a41c5e23c42985f6))

## 1.1.0-dev.7

 - **FIX**: query result not always correctly updated after receiving new data. ([12b2b283](https://github.com/appsup-dart/firebase_dart/commit/12b2b2831490a4d3f522df1cb5e0ec957181649b))

## 1.1.0-dev.6

 - **FIX**(auth): sandbox for apns on release mode. ([ab1ced6c](https://github.com/appsup-dart/firebase_dart/commit/ab1ced6cc08476fd0baa1d9cb183e2caf0da2fe3))

## 1.1.0-dev.5

 - **REFACTOR**(auth): refactor base application verifier. ([b842cbc2](https://github.com/appsup-dart/firebase_dart/commit/b842cbc295e8ffecbacf6b387cd77247be739941))
 - **FIX**(auth): sign out when getting token expired response. ([d8bfb9c5](https://github.com/appsup-dart/firebase_dart/commit/d8bfb9c5845dc2f00de8914598f06bb09eca5b7b))
 - **FEAT**(auth): application verification with silent APNs notifications on ios. ([82db724d](https://github.com/appsup-dart/firebase_dart/commit/82db724d3702324b8f442ec80202232f9ef29e3c))

## 1.1.0-dev.4

 - **FEAT**(setup): Platform.current now returns a platform specific subclass. ([64e023a3](https://github.com/appsup-dart/firebase_dart/commit/64e023a37ee4de5d103621a605788f65d2f8f3c1))

## 1.1.0-dev.3

 - **FIX**(auth): fix (token) updates on user not being stored in persistence memory. ([ca2f285b](https://github.com/appsup-dart/firebase_dart/commit/ca2f285bddb5e22dff4bb9f3072dec1c55af3e3c))

## 1.1.0-dev.2


 - **BREAKING** **FIX**(database): `DataSnapshot.value` now returns a `List` when keys are integers ([#31](https://github.com/appsup-dart/firebase_dart/issues/31)). ([9016ae19](https://github.com/appsup-dart/firebase_dart/commit/9016ae19893fd1896f0026ce368447d26486cfc5))
- **FEAT**(auth): Implemented `FirebaseAuth.signInWithPhoneNumber` method.
- **FEAT**(auth): Implemented `FirebaseAuth.verifyPhoneNumber` method.
- **FEAT**(auth): Implemented `FirebaseUser.multiFactor` for mfa support.


## 1.1.0-dev.1

- **FEAT**(auth): Implemented `FirebaseUser.reauthenticateWithCredential` method.
- **FIX**(database): Fix issue where database transaction on a path are no longer executed once a transaction has failed 
- **FIX**(database): Fix issue where a database query never received a value

## 1.0.11

- Fix incompatibility with `http` version 0.13.5
- Merge pull request #25 from IgoKom/fix_custom_metadata
- Merge pull request #23 from TimWhiting/develop

## 1.0.10

- Upgrade dependencies
- Basic support for sign in with phone number

## 1.0.9

- bugfix: properly close persistence storage when deleting app

## 1.0.8

- bugfixes and performance improvements on realtime database


## 1.0.7

- add `DatabaseReference.path` getter
- fix key ordering in case of integers overflowing 32-bit


## 1.0.6

- fix some realtime database queries not sent to server because of optimization error
- improve memory usage

## 1.0.5

- when calling `startAt` or `endAt` with the `key` parameter equal to null, we now handle this the same as not passing the `key` parameter

## 1.0.4

- bugfix: null check operator

## 1.0.3

- Performance improvements

## 1.0.2

- Immediately try reconnecting when calling goOnline

## 1.0.1

- Performance improvements

## 1.0.0

- Added support for firebase auth service
- Added support for firebase storage service
- Rework of the API in line with flutterfire packages 
- `.info` location with `connected`, `authenticated` and `serverTimeOffset`
- Firebase database now supports persistence storage (use `setPersistenceEnabled`)
- Null safety

## 0.7.15

- support more authentication methods: firebase secret, id token, access token 
- deprecate use of `Firebase` object, replaced by `Reference` object
- dart sdk 2.5+ compatibility

## 0.7.14

- fixed crash when receiving a merge in some situations

## 0.7.13

- Now works with firebase emulators, e.g. `new Firebase("http://localhost:9000?ns=my-project")`

## 0.7.12

- Fix recovering from broken connection and reset messages

## 0.7.11

- Support Dart 2 in `pubspec.yaml`


## 0.7.10

- Dart 2 pre-release compatibility

## 0.7.9

- add FirebaseApp and FirebaseDatabase classes
- performance improvements
- recover from connection closed by peer

## 0.7.8

- Remove dart 2 only things

## 0.7.7

- Fix issue ack making view incomplete

## 0.7.6 

- Remove delay on write operations with in-memory database

## 0.7.5

- Fix bug concurrent modification with transactions

## 0.7.4

- Fix order by grandchild
- Resolve strong mode analysis warnings

## 0.7.3

- Fix `The method 'operationForChild' was called on null.`

## 0.7.2

- Fix not able to authenticate with database secret

## 0.7.1

- Fix bug saving lists

## 0.7.0

- Local memory database
- bugfixes

## 0.6.0

- improved performance by only listening to the most general query
- bugfixes


## 0.5.7

- fix handling merge when some new children are nil

## 0.5.6

- fix child of empty datasnapshot

## 0.5.5

- implement onChildChanged, onChildMoved, onChildRemoved and onChildAdded

## 0.5.4

- fix hash of null in transactions

## 0.5.3

- fix signature check when padded

## 0.5.2

- fix decoding tokens not padded with =

## 0.5.1

- fix redirects to host with port

## 0.5.0

- **Breaking** signature of startAt/endAt
- reconnect when connection broken
- bugfixes
- FirebaseToken class

## 0.4.1

- handle messages split in multiple frames (issue #8)

## 0.4.0

- browser support
- strong mode

## 0.3.0

- implement transactions
- implement onDisconnect
- bug fixes 

## 0.2.1

- relax dependency on crypto library to '>=0.9.2 <3.0.0'


## 0.2.0

- implement auth revoke and listen revoke
- implement startAt and endAt
- remove failed operations

## 0.1.0

- Initial version
