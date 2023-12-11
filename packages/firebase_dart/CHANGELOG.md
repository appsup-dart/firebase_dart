## 1.1.2

 - **FIX**: when doing many listens and unlistens, sometimes a null was returned before the actual value. ([20f72d41](https://github.com/appsup-dart/firebase_dart/commit/20f72d41e2df6b4d2f0af20472d4fc3048577c23))

## 1.1.1

 - **FIX**(database): handle when persistent storage corrupt. ([804de4b7](https://github.com/appsup-dart/firebase_dart/commit/804de4b7d627dbdff03fe895cc68d8edacad5608))
 - **FIX**(database): running transactions throw error when app deleted. ([8e2055e9](https://github.com/appsup-dart/firebase_dart/commit/8e2055e9cd04c671e51422bae3ff68ad560e5101))
 - **FIX**(database): fix StateError `Should not call rerun when transactions are running`. ([1cfca21f](https://github.com/appsup-dart/firebase_dart/commit/1cfca21f96c20e93b1a895e15582c06b15c5b219))

## 1.1.0

 - **REFACTOR**(firebase_dart): support intl ^0.18.0. ([0daa8dbb](https://github.com/appsup-dart/firebase_dart/commit/0daa8dbbc1688c021b8bebba90e8521ebeaf6dca))
 - **REFACTOR**(firebase_dart): support http package ^1.0.0 (pull request [#47](https://github.com/appsup-dart/firebase_dart/issues/47) from xclud). ([c20f0cb6](https://github.com/appsup-dart/firebase_dart/commit/c20f0cb6b37bc18953a5476f6a2f859dc5dc7374))
 - **FIX**(database): SocketException when trying to connect without internet connection (issue [#39](https://github.com/appsup-dart/firebase_dart/issues/39)). ([db96095d](https://github.com/appsup-dart/firebase_dart/commit/db96095d79dab80fa69e66585c8e2de5f4ebf03e))
 - **FIX**(database): database looses connection when idling during 60 seconds (issue [#40](https://github.com/appsup-dart/firebase_dart/issues/40)). ([c6230aae](https://github.com/appsup-dart/firebase_dart/commit/c6230aae2e4e5184301b5db28938c6bafb0aef9d))
 - **FIX**(storage): ListResult.toJson writing items iso prefix (pull request [#46](https://github.com/appsup-dart/firebase_dart/issues/46) from tomassasovsky). ([d2962e2f](https://github.com/appsup-dart/firebase_dart/commit/d2962e2f0795c47bad616fef5ce01e8d73cae12c))
 - **FIX**: launchUrl throwing exception before redirecting (pull request [#42](https://github.com/appsup-dart/firebase_dart/issues/42) from TimWhiting). ([6ac91a55](https://github.com/appsup-dart/firebase_dart/commit/6ac91a55a0e5c74de066a856a70a977cd2b84c53))

 - **FIX**(database): writing an object with a null child did not reduce to nil. ([36f8bc1f](https://github.com/appsup-dart/firebase_dart/commit/36f8bc1fa778a5630f362eb8ad1448659a676919))
 - **FEAT**(firebase_dart_plus): Batch writes for realtime database. ([a11ee959](https://github.com/appsup-dart/firebase_dart/commit/a11ee959b0c51cdac4a4080aff0d03b1bd5cc78d))

 - **FIX**(database): Invalid argument(s): Mapping for QuerySpec exists. ([d7b4a41e](https://github.com/appsup-dart/firebase_dart/commit/d7b4a41e7dc28e3ee47b0f534985cc8b743b9ddd))

 - **REFACTOR**(database): create MasterView for default query when non limiting query. ([e087089f](https://github.com/appsup-dart/firebase_dart/commit/e087089fa90b20c3577f9d717939a166b2f8a0fd))
 - **REFACTOR**(database): refactor PrioritizedQueryRegistrar. ([d06a8c80](https://github.com/appsup-dart/firebase_dart/commit/d06a8c805e05df2d63d2d172cb78cf150757311f))
 - **PERF**(database): always send a hash on a listen request. ([7534afc1](https://github.com/appsup-dart/firebase_dart/commit/7534afc1b09124f26c5f24bad466a3dfb234608c))
 - **FIX**(database): fixed pruning of persistent cache. ([a14d84bc](https://github.com/appsup-dart/firebase_dart/commit/a14d84bcd39019499660e1b95ba19e8c5ab2c66c))

 - **FIX**(database): should throw permission denied error when permission changes while listening. ([b45a7a5e](https://github.com/appsup-dart/firebase_dart/commit/b45a7a5ec327b28871824515a41c5e23c42985f6))

 - **FIX**: query result not always correctly updated after receiving new data. ([12b2b283](https://github.com/appsup-dart/firebase_dart/commit/12b2b2831490a4d3f522df1cb5e0ec957181649b))

 - **FIX**(auth): sandbox for apns on release mode. ([ab1ced6c](https://github.com/appsup-dart/firebase_dart/commit/ab1ced6cc08476fd0baa1d9cb183e2caf0da2fe3))

 - **REFACTOR**(auth): refactor base application verifier. ([b842cbc2](https://github.com/appsup-dart/firebase_dart/commit/b842cbc295e8ffecbacf6b387cd77247be739941))
 - **FIX**(auth): sign out when getting token expired response. ([d8bfb9c5](https://github.com/appsup-dart/firebase_dart/commit/d8bfb9c5845dc2f00de8914598f06bb09eca5b7b))
 - **FEAT**(auth): application verification with silent APNs notifications on ios. ([82db724d](https://github.com/appsup-dart/firebase_dart/commit/82db724d3702324b8f442ec80202232f9ef29e3c))

 - **FEAT**(setup): Platform.current now returns a platform specific subclass. ([64e023a3](https://github.com/appsup-dart/firebase_dart/commit/64e023a37ee4de5d103621a605788f65d2f8f3c1))

 - **FIX**(auth): fix (token) updates on user not being stored in persistence memory. ([ca2f285b](https://github.com/appsup-dart/firebase_dart/commit/ca2f285bddb5e22dff4bb9f3072dec1c55af3e3c))

 - **BREAKING** **FIX**(database): `DataSnapshot.value` now returns a `List` when keys are integers ([#31](https://github.com/appsup-dart/firebase_dart/issues/31)). ([9016ae19](https://github.com/appsup-dart/firebase_dart/commit/9016ae19893fd1896f0026ce368447d26486cfc5))
- **FEAT**(auth): Implemented `FirebaseAuth.signInWithPhoneNumber` method.
- **FEAT**(auth): Implemented `FirebaseAuth.verifyPhoneNumber` method.
- **FEAT**(auth): Implemented `FirebaseUser.multiFactor` for mfa support.

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
