# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2026-11-13

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v2.0.0-dev.9`](#firebase_dart---v200-dev9)
 - [`firebase_dart_flutter` - `v1.4.0-dev.9`](#firebase_dart_flutter---v140-dev9)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.9`](#firebase_dart_flutter_auth_google---v010-dev9)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.9`](#firebase_dart_flutter_auth_facebook---v001-dev9)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.9`](#firebase_dart_flutter_auth_apple---v001-dev9)
 - [`firebase_dart_plus` - `v0.1.1-dev.9`](#firebase_dart_plus---v011-dev9)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.9`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.9`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.9`
 - `firebase_dart_plus` - `v0.1.1-dev.9`

---

#### `firebase_dart` - `v2.0.0-dev.9`

 - **REFACTOR**(app-check): replace AppCheckProviders with a sealed provider. ([3810c5ca](https://github.com/appsup-dart/firebase_dart/commit/3810c5ca5626d458e7fa5b5ea2a6ba23a8e5ba07))
 - **REFACTOR**(app-check): Flutter provider, WebView reCAPTCHA, non-blocking activate. ([127019d4](https://github.com/appsup-dart/firebase_dart/commit/127019d479e57058c59c495501171a850428921d))
 - **REFACTOR**(app-check): attestation types and centralized token exchange. ([ad7d2ecd](https://github.com/appsup-dart/firebase_dart/commit/ad7d2ecd5880ab89fba5d7b2627a6c8ff4e2642d))
 - **REFACTOR**(app-check): provider-based activate and Flutter composite. ([cc8b7a46](https://github.com/appsup-dart/firebase_dart/commit/cc8b7a466a5bd2c98dc90eb31d52a1ac4d038b62))
 - **REFACTOR**(app-check): use googleapis for App Check token exchange. ([f38a133a](https://github.com/appsup-dart/firebase_dart/commit/f38a133aaf9127c255081ea9a5616de1f3d4c918))
 - **FIX**(app-check): connect Realtime Database when the App Check token fails. ([fa799537](https://github.com/appsup-dart/firebase_dart/commit/fa79953780178a3e526b67d70880addb2b8e8057))
 - **FIX**: scope persisted data by app id and app name. ([51153cc6](https://github.com/appsup-dart/firebase_dart/commit/51153cc6af5fd97d3e8e11a0ea1cb4fe22abe977))
 - **FIX**(app-check): reconnect Realtime Database with a fresh token after revoke. ([cc5f042d](https://github.com/appsup-dart/firebase_dart/commit/cc5f042dfe5e4d8bece907b2bd4eeb308a5eef47))
 - **FIX**(app-check): retry Auth and Storage after a rejected token. ([fc62729b](https://github.com/appsup-dart/firebase_dart/commit/fc62729bc79211028e8e55195ac37a5d519e4e3e))
 - **FIX**(app-check): reuse a stored token after restart. ([656dfe63](https://github.com/appsup-dart/firebase_dart/commit/656dfe63b7fffc78c15908f2f053a98bf8b67bb2))
 - **FIX**(app-check): recover when a token fetch fails. ([ee6be5e9](https://github.com/appsup-dart/firebase_dart/commit/ee6be5e932d581baa27f958a650a8a702b791ccf))
 - **FEAT**(app-check): send App Check token on Cloud Storage HTTP requests. ([2a0023ea](https://github.com/appsup-dart/firebase_dart/commit/2a0023eafc21dda4b93d31e4a42f6f8acf5b3f6e))
 - **FEAT**(app-check): send App Check token on Firebase Auth HTTP requests. ([d90e284e](https://github.com/appsup-dart/firebase_dart/commit/d90e284efac0eb04fded7604d155eb7e83656ef5))
 - **FEAT**(app-check): wire App Check through the Firebase worker isolate. ([9cec76f6](https://github.com/appsup-dart/firebase_dart/commit/9cec76f6838be0a56c920dec2871a9edbe9e9f66))
 - **FEAT**(app-check): core debug provider and integration smoke test. ([433eba67](https://github.com/appsup-dart/firebase_dart/commit/433eba67e315eb8b26abb5479907aa5283d71572))
 - **FEAT**(app-check): multi-provider activate with Flutter provider split. ([fd776e1f](https://github.com/appsup-dart/firebase_dart/commit/fd776e1f27e657f0bee0abd864b403ddc8a41e58))
 - **FEAT**(app-check): App Attest on iOS. ([8a722f04](https://github.com/appsup-dart/firebase_dart/commit/8a722f045420d5349ddf2590bd4d8101d8117f98))
 - **FEAT**(app-check): native Device Check on iOS and macOS. ([22021359](https://github.com/appsup-dart/firebase_dart/commit/22021359bb5b69e3f20fc1cf5f0f045a6e50f12a))
 - **FEAT**(app-check): implement Android Play Integrity provider for Flutter. ([3bafb135](https://github.com/appsup-dart/firebase_dart/commit/3bafb13516c548785281a6265fec4c359544240b))
 - **FEAT**(app-check): token refresh, onTokenChange, and RTDB token updates. ([971671b6](https://github.com/appsup-dart/firebase_dart/commit/971671b69a80a23388d1719ed649dc06973514d6))
 - **FEAT**(database): send App Check tokens on Realtime Database connections. ([654e8b63](https://github.com/appsup-dart/firebase_dart/commit/654e8b63e0f4f4465050bb003cdef9526e74d022))
 - **FEAT**(app-check): implementation of app-check api. ([82ae0264](https://github.com/appsup-dart/firebase_dart/commit/82ae0264e2558675e34e663b3bda49d7ec9cb1ab))
 - **DOCS**: describe Flutter App Check providers in try order. ([094b1797](https://github.com/appsup-dart/firebase_dart/commit/094b1797753dc17b09c1bcdf349343e784b7fb31))
 - **DOCS**: document App Check in README files. ([49aaa397](https://github.com/appsup-dart/firebase_dart/commit/49aaa3973ddd341ad59c4a969804570ca7f32a09))

#### `firebase_dart_flutter` - `v1.4.0-dev.9`

 - **REFACTOR**(app-check): replace AppCheckProviders with a sealed provider. ([3810c5ca](https://github.com/appsup-dart/firebase_dart/commit/3810c5ca5626d458e7fa5b5ea2a6ba23a8e5ba07))
 - **REFACTOR**(app-check): Flutter provider, WebView reCAPTCHA, non-blocking activate. ([127019d4](https://github.com/appsup-dart/firebase_dart/commit/127019d479e57058c59c495501171a850428921d))
 - **REFACTOR**(app-check): attestation types and centralized token exchange. ([ad7d2ecd](https://github.com/appsup-dart/firebase_dart/commit/ad7d2ecd5880ab89fba5d7b2627a6c8ff4e2642d))
 - **REFACTOR**(app-check): provider-based activate and Flutter composite. ([cc8b7a46](https://github.com/appsup-dart/firebase_dart/commit/cc8b7a466a5bd2c98dc90eb31d52a1ac4d038b62))
 - **FEAT**(app-check): add native reCAPTCHA Enterprise on Flutter. ([1b54fdbe](https://github.com/appsup-dart/firebase_dart/commit/1b54fdbea357b6845ca4d2bcb81dece7d51305ee))
 - **FEAT**(app-check): offer App Attest on macOS. ([d6d0c604](https://github.com/appsup-dart/firebase_dart/commit/d6d0c604a3e4742dec82c436f2f6f3a9f6528459))
 - **FEAT**(app-check): core debug provider and integration smoke test. ([433eba67](https://github.com/appsup-dart/firebase_dart/commit/433eba67e315eb8b26abb5479907aa5283d71572))
 - **FEAT**(app-check): multi-provider activate with Flutter provider split. ([fd776e1f](https://github.com/appsup-dart/firebase_dart/commit/fd776e1f27e657f0bee0abd864b403ddc8a41e58))
 - **FEAT**(app-check): App Attest on iOS. ([8a722f04](https://github.com/appsup-dart/firebase_dart/commit/8a722f045420d5349ddf2590bd4d8101d8117f98))
 - **FEAT**(app-check): native Device Check on iOS and macOS. ([22021359](https://github.com/appsup-dart/firebase_dart/commit/22021359bb5b69e3f20fc1cf5f0f045a6e50f12a))
 - **FEAT**(app-check): implement Android Play Integrity provider for Flutter. ([3bafb135](https://github.com/appsup-dart/firebase_dart/commit/3bafb13516c548785281a6265fec4c359544240b))
 - **DOCS**: describe Flutter App Check providers in try order. ([094b1797](https://github.com/appsup-dart/firebase_dart/commit/094b1797753dc17b09c1bcdf349343e784b7fb31))
 - **DOCS**: document App Check in README files. ([49aaa397](https://github.com/appsup-dart/firebase_dart/commit/49aaa3973ddd341ad59c4a969804570ca7f32a09))


## 2026-11-13

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v2.0.0-dev.8`](#firebase_dart---v200-dev8)
 - [`firebase_dart_flutter` - `v1.4.0-dev.8`](#firebase_dart_flutter---v140-dev8)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.8`](#firebase_dart_flutter_auth_google---v010-dev8)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.8`](#firebase_dart_flutter_auth_facebook---v001-dev8)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.8`](#firebase_dart_flutter_auth_apple---v001-dev8)
 - [`firebase_dart_plus` - `v0.1.1-dev.8`](#firebase_dart_plus---v011-dev8)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.4.0-dev.8`
 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.8`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.8`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.8`
 - `firebase_dart_plus` - `v0.1.1-dev.8`

---

#### `firebase_dart` - `v2.0.0-dev.8`

 - **FIX**: avoid remote registration for uncontained keep-alive queries. ([68b26787](https://github.com/appsup-dart/firebase_dart/commit/68b26787e244d0334d8a7a3f063aaeb8b981f6c3))


## 2026-11-11

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v2.0.0-dev.7`](#firebase_dart---v200-dev7)
 - [`firebase_dart_flutter` - `v1.4.0-dev.7`](#firebase_dart_flutter---v140-dev7)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.7`](#firebase_dart_flutter_auth_google---v010-dev7)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.7`](#firebase_dart_flutter_auth_facebook---v001-dev7)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.7`](#firebase_dart_flutter_auth_apple---v001-dev7)
 - [`firebase_dart_plus` - `v0.1.1-dev.7`](#firebase_dart_plus---v011-dev7)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.4.0-dev.7`
 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.7`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.7`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.7`
 - `firebase_dart_plus` - `v0.1.1-dev.7`

---

#### `firebase_dart` - `v2.0.0-dev.7`

 - **PERF**: use the query index when updating the server cache. ([5f101544](https://github.com/appsup-dart/firebase_dart/commit/5f1015441aea1dddf33c59857c1af7a8d7576f2f))
 - **PERF**: serve cache queries from a sorted child index. ([5803a6e5](https://github.com/appsup-dart/firebase_dart/commit/5803a6e5be348f61420e6383363e037e094fc37f))
 - **PERF**: serve an indexed withFilter from a sorted child map. ([c05fe0c8](https://github.com/appsup-dart/firebase_dart/commit/c05fe0c88ce35a9f1010a5676311d729818ee194))
 - **FIX**: load Wasm benchmarks with the current dart2wasm loader. ([6196a91a](https://github.com/appsup-dart/firebase_dart/commit/6196a91a3aed524a55f1e16a959cc89d5755f50c))


## 2026-11-04

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v2.0.0-dev.6`](#firebase_dart---v200-dev6)
 - [`firebase_dart_flutter` - `v1.4.0-dev.6`](#firebase_dart_flutter---v140-dev6)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.6`](#firebase_dart_flutter_auth_google---v010-dev6)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.6`](#firebase_dart_flutter_auth_facebook---v001-dev6)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.6`](#firebase_dart_flutter_auth_apple---v001-dev6)
 - [`firebase_dart_plus` - `v0.1.1-dev.6`](#firebase_dart_plus---v011-dev6)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.4.0-dev.6`
 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.6`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.6`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.6`
 - `firebase_dart_plus` - `v0.1.1-dev.6`

---

#### `firebase_dart` - `v2.0.0-dev.6`

 - **FIX**: measure the persistence cache after the current frame. ([2408106d](https://github.com/appsup-dart/firebase_dart/commit/2408106d3d906b0e54e75fd511884d1d004291f9))
 - **FIX**: reuse the encoded size of an unchanged cache node. ([bf84dd28](https://github.com/appsup-dart/firebase_dart/commit/bf84dd28f4234ad00bafc066a161de9ab8aa44d5))
 - **FIX**: prune limited queries from one ordered child list. ([42033d07](https://github.com/appsup-dart/firebase_dart/commit/42033d0791951f419e8818819f42830694e793cf))


## 2026-11-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v2.0.0-dev.5`](#firebase_dart---v200-dev5)
 - [`firebase_dart_flutter` - `v1.4.0-dev.5`](#firebase_dart_flutter---v140-dev5)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.5`](#firebase_dart_flutter_auth_google---v010-dev5)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.5`](#firebase_dart_flutter_auth_facebook---v001-dev5)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.5`](#firebase_dart_flutter_auth_apple---v001-dev5)
 - [`firebase_dart_plus` - `v0.1.1-dev.5`](#firebase_dart_plus---v011-dev5)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.4.0-dev.5`
 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.5`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.5`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.5`
 - `firebase_dart_plus` - `v0.1.1-dev.5`

---

#### `firebase_dart` - `v2.0.0-dev.5`

 - **FIX**: defer persistence cache prune off the server update. ([c7277470](https://github.com/appsup-dart/firebase_dart/commit/c72774709645d71867a333361ca528ae44ffe45b))
 - **FIX**: prune the persistence cache in one pass. ([2bde8e41](https://github.com/appsup-dart/firebase_dart/commit/2bde8e41d1c6b147f1905e8225117938012ced33))
 - **FIX**: delete stored cache keys without scanning the box. ([3bc114d8](https://github.com/appsup-dart/firebase_dart/commit/3bc114d866fbe957919d8dc5cefe562f8a857bb2))


## 2026-11-01

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v2.0.0-dev.4`](#firebase_dart---v200-dev4)
 - [`firebase_dart_flutter` - `v1.4.0-dev.4`](#firebase_dart_flutter---v140-dev4)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.4`](#firebase_dart_flutter_auth_google---v010-dev4)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.4`](#firebase_dart_flutter_auth_facebook---v001-dev4)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.4`](#firebase_dart_flutter_auth_apple---v001-dev4)
 - [`firebase_dart_plus` - `v0.1.1-dev.4`](#firebase_dart_plus---v011-dev4)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.4.0-dev.4`
 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.4`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.4`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.4`
 - `firebase_dart_plus` - `v0.1.1-dev.4`

---

#### `firebase_dart` - `v2.0.0-dev.4`

 - **FIX**: settle DelayedCancellableFuture when it is cancelled. ([1fc286a9](https://github.com/appsup-dart/firebase_dart/commit/1fc286a9747d9555690bae39a5b282f027e6bddf))
 - **FIX**: clear the pending sync update when the tree is destroyed. ([ffbc9adb](https://github.com/appsup-dart/firebase_dart/commit/ffbc9adbab740d32a436e621a77594a0d7ac4549))
 - **FIX**: drop uncovered persistence cache once when the database opens. ([87720c62](https://github.com/appsup-dart/firebase_dart/commit/87720c62907597c67b087622717306dc0927f7a9))
 - **FIX**: prune persistence cache without dropping the pending update or sibling query data. ([9877f138](https://github.com/appsup-dart/firebase_dart/commit/9877f138c2f8c522b2e757eb60561fce8a2ef49b))


## 2026-10-26

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v2.0.0-dev.3`](#firebase_dart---v200-dev3)
 - [`firebase_dart_flutter` - `v1.4.0-dev.3`](#firebase_dart_flutter---v140-dev3)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.3`](#firebase_dart_flutter_auth_google---v010-dev3)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.3`](#firebase_dart_flutter_auth_facebook---v001-dev3)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.3`](#firebase_dart_flutter_auth_apple---v001-dev3)
 - [`firebase_dart_plus` - `v0.1.1-dev.3`](#firebase_dart_plus---v011-dev3)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.4.0-dev.3`
 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.3`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.3`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.3`
 - `firebase_dart_plus` - `v0.1.1-dev.3`

---

#### `firebase_dart` - `v2.0.0-dev.3`

 - **FIX**: drop empty unregistered sync views so uncovered children register again. ([d75d7a2d](https://github.com/appsup-dart/firebase_dart/commit/d75d7a2d2f982f2cb71e93cd3a359a04a4f604bd))
 - **FIX**: rethrow database update failures after reverting pending write. ([2ad06a3d](https://github.com/appsup-dart/firebase_dart/commit/2ad06a3df06016da2fc8b79a7aa13fb21a3b4026))
 - **FEAT**: expose the HTTP client used after FirebaseDart.setup. ([2c49f47d](https://github.com/appsup-dart/firebase_dart/commit/2c49f47dd733ed6eb63684474ab39979a149e6d0))


## 2026-06-23

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v2.0.0-dev.2`](#firebase_dart---v200-dev2)
 - [`firebase_dart_plus` - `v0.1.1-dev.2`](#firebase_dart_plus---v011-dev2)
 - [`firebase_dart_flutter` - `v1.4.0-dev.2`](#firebase_dart_flutter---v140-dev2)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.2`](#firebase_dart_flutter_auth_google---v010-dev2)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.2`](#firebase_dart_flutter_auth_facebook---v001-dev2)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.2`](#firebase_dart_flutter_auth_apple---v001-dev2)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.4.0-dev.2`
 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.2`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.2`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.2`

---

#### `firebase_dart` - `v2.0.0-dev.2`

 - **FIX**: retry http requests on network errors. ([33409e21](https://github.com/appsup-dart/firebase_dart/commit/33409e2131275a0e7e814a2452376d19c72d76f3))

#### `firebase_dart_plus` - `v0.1.1-dev.2`

 - **PERF**: use TreeMap iso SortedMap/HashMap for fast cloning. ([5bb274c8](https://github.com/appsup-dart/firebase_dart/commit/5bb274c8e0c7bf73d6a21af13b464887cc7d61aa))
 - **PERF**: avoid creating new IncompleteData instances on no-ops. ([d68e2e61](https://github.com/appsup-dart/firebase_dart/commit/d68e2e61b43ca7c532f91f958c7049419732e263))


## 2026-06-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v2.0.0-dev.1`](#firebase_dart---v200-dev1)
 - [`firebase_dart_plus` - `v0.1.0-dev.1`](#firebase_dart_plus---v010-dev1)
 - [`firebase_dart_flutter` - `v1.4.0-dev.1`](#firebase_dart_flutter---v140-dev1)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.1`](#firebase_dart_flutter_auth_google---v010-dev1)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.1`](#firebase_dart_flutter_auth_facebook---v001-dev1)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.1`](#firebase_dart_flutter_auth_apple---v001-dev1)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.4.0-dev.1`
 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.1`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.1`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.1`

---

#### `firebase_dart` - `v2.0.0-dev.1`

 - **PERF**: use TreeMap for children of WriteTree and HashMap for other ModifiableTreeNodes. ([3b455cc0](https://github.com/appsup-dart/firebase_dart/commit/3b455cc07fa90ad682b3a1771a4c8a49218aa384))
 - **PERF**: avoid double lookup (operator[] after containsKey) in ModifiableTreeNode.subtree. ([3d86f2d1](https://github.com/appsup-dart/firebase_dart/commit/3d86f2d11afb27a5a23dc6c22dd4fb1cd866919b))
 - **PERF**: speed up operationForChild for Merge operations. ([618727d6](https://github.com/appsup-dart/firebase_dart/commit/618727d61d3d3659dfc4f56c954880efb14eb083))
 - **PERF**: use TreeMap iso SortedMap/HashMap for fast cloning. ([5bb274c8](https://github.com/appsup-dart/firebase_dart/commit/5bb274c8e0c7bf73d6a21af13b464887cc7d61aa))
 - **PERF**: avoid creating new IncompleteData instances on no-ops. ([d68e2e61](https://github.com/appsup-dart/firebase_dart/commit/d68e2e61b43ca7c532f91f958c7049419732e263))
 - **PERF**: increase speed of IncompleteData.applyOperation. ([d78d26e5](https://github.com/appsup-dart/firebase_dart/commit/d78d26e58a9786a5c92ae98a15b4cc32ab30e455))
 - **PERF**: prune observers on reconnect. ([35035b69](https://github.com/appsup-dart/firebase_dart/commit/35035b6935dbbced32dcb47e74d4fc239125efcc))
 - **FIX**: revoking one query should keep other active filters and avoid duplicate registration. ([d5a4ec9b](https://github.com/appsup-dart/firebase_dart/commit/d5a4ec9bb5585ad9ef2ef122df288671e2905b84))
 - **FIX**: preparing operationForChild on Merge. ([57f2ca63](https://github.com/appsup-dart/firebase_dart/commit/57f2ca6399b46a7cd0b470283cf8c45b6210aa34))
 - **FIX**: cast children of TransactionsNode and SparseSnapshotTree. ([3c281091](https://github.com/appsup-dart/firebase_dart/commit/3c2810919d127fa4f44613a9f40f663165504ee2))
 - **FIX**: observers not notified when state of view changes. ([0a01bf75](https://github.com/appsup-dart/firebase_dart/commit/0a01bf7537b56270649df1c686ec90064d2128cf))

#### `firebase_dart_plus` - `v0.1.0-dev.1`

 - **PERF**: use TreeMap iso SortedMap/HashMap for fast cloning. ([5bb274c8](https://github.com/appsup-dart/firebase_dart/commit/5bb274c8e0c7bf73d6a21af13b464887cc7d61aa))
 - **PERF**: avoid creating new IncompleteData instances on no-ops. ([d68e2e61](https://github.com/appsup-dart/firebase_dart/commit/d68e2e61b43ca7c532f91f958c7049419732e263))


## 2026-04-13

### Changes

---

Packages with breaking changes:

 - [`firebase_dart` - `v2.0.0-dev.0`](#firebase_dart---v200-dev0)

Packages with other changes:

 - [`firebase_dart_flutter` - `v1.4.0-dev.0`](#firebase_dart_flutter---v140-dev0)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0-dev.0+12`](#firebase_dart_flutter_auth_google---v010-dev012)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.0+12`](#firebase_dart_flutter_auth_facebook---v001-dev012)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1-dev.0+12`](#firebase_dart_flutter_auth_apple---v001-dev012)
 - [`firebase_dart_plus` - `v0.1.0-dev.0+32`](#firebase_dart_plus---v010-dev032)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter_auth_google` - `v0.1.0-dev.0+12`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1-dev.0+12`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1-dev.0+12`
 - `firebase_dart_plus` - `v0.1.0-dev.0+32`

---

#### `firebase_dart` - `v2.0.0-dev.0`

 - **REFACTOR**: restructure ApplicationVerifier implementations. ([e9a5aad6](https://github.com/appsup-dart/firebase_dart/commit/e9a5aad6b48b2889dc2ba52f23f63a5e31de5526))
 - **REFACTOR**: use RequestWithVerification common mixin for identity toolkit requests. ([aa9009ab](https://github.com/appsup-dart/firebase_dart/commit/aa9009ab4469f79ab364daed45c9f912d83c622c))
 - **REFACTOR**: use recaptcha.enterprise js sdk. ([9155ff0f](https://github.com/appsup-dart/firebase_dart/commit/9155ff0f08039766b29fcbde05f46d2cc0beebbf))
 - **REFACTOR**: replace firebaseapis with googleapis. ([4ff5581a](https://github.com/appsup-dart/firebase_dart/commit/4ff5581ad25d5c2e5ad11afa3eefa9e5530e9f52))
 - **FEAT**(auth): reCAPTCHA SMS defense for SMS-based authentication. ([961ea305](https://github.com/appsup-dart/firebase_dart/commit/961ea3052cd8bf1fda326fe5ec6147d55e8a81bb))
 - **BREAKING** **REFACTOR**(auth): remove `verifier` argument from `signInWithPhoneNumber` and `verifyPhoneNumber`. ([f90f4c14](https://github.com/appsup-dart/firebase_dart/commit/f90f4c1419372a982bdd2263f6111f0c1c3bf8d8))

#### `firebase_dart_flutter` - `v1.4.0-dev.0`

 - **REFACTOR**: restructure ApplicationVerifier implementations. ([e9a5aad6](https://github.com/appsup-dart/firebase_dart/commit/e9a5aad6b48b2889dc2ba52f23f63a5e31de5526))
 - **FEAT**(auth): reCAPTCHA SMS defense for SMS-based authentication. ([961ea305](https://github.com/appsup-dart/firebase_dart/commit/961ea3052cd8bf1fda326fe5ec6147d55e8a81bb))


## 2026-03-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.6.2`](#firebase_dart---v162)
 - [`firebase_dart_flutter` - `v1.3.10`](#firebase_dart_flutter---v1310)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+11`](#firebase_dart_flutter_auth_google---v01011)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+11`](#firebase_dart_flutter_auth_facebook---v00111)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+11`](#firebase_dart_flutter_auth_apple---v00111)
 - [`firebase_dart_plus` - `v0.1.0+31`](#firebase_dart_plus---v01031)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.3.10`
 - `firebase_dart_flutter_auth_google` - `v0.1.0+11`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1+11`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1+11`
 - `firebase_dart_plus` - `v0.1.0+31`

---

#### `firebase_dart` - `v1.6.2`

 - **REFACTOR**: upgrade jose dependency. ([595dd24c](https://github.com/appsup-dart/firebase_dart/commit/595dd24c98281de05a736d8441cf3bbdff19c6cf))


## 2026-03-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.6.1`](#firebase_dart---v161)
 - [`firebase_dart_flutter` - `v1.3.9`](#firebase_dart_flutter---v139)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+10`](#firebase_dart_flutter_auth_google---v01010)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+10`](#firebase_dart_flutter_auth_facebook---v00110)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+10`](#firebase_dart_flutter_auth_apple---v00110)
 - [`firebase_dart_plus` - `v0.1.0+30`](#firebase_dart_plus---v01030)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.3.9`
 - `firebase_dart_flutter_auth_google` - `v0.1.0+10`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1+10`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1+10`
 - `firebase_dart_plus` - `v0.1.0+30`

---

#### `firebase_dart` - `v1.6.1`

 - **REFACTOR**: reduce log level for sent and received rtdb messages. ([92ccb553](https://github.com/appsup-dart/firebase_dart/commit/92ccb553b3926f98e8ba320fd672126c2d0901b0))
 - **FIX**: `Null check operator used on a null value` when listeners revoked. ([23e24aad](https://github.com/appsup-dart/firebase_dart/commit/23e24aad059489bbc13c6096b56ecbcc7ffd248f))
 - **FIX**: readable children not loaded after listen revoked on parent. ([494ea70e](https://github.com/appsup-dart/firebase_dart/commit/494ea70e5748105c2c8ab59fe8889c4e22fda1ba))


## 2026-02-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.6.0`](#firebase_dart---v160)
 - [`firebase_dart_flutter` - `v1.3.8`](#firebase_dart_flutter---v138)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+9`](#firebase_dart_flutter_auth_google---v0109)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+9`](#firebase_dart_flutter_auth_facebook---v0019)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+9`](#firebase_dart_flutter_auth_apple---v0019)
 - [`firebase_dart_plus` - `v0.1.0+29`](#firebase_dart_plus---v01029)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.3.8`
 - `firebase_dart_flutter_auth_google` - `v0.1.0+9`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1+9`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1+9`
 - `firebase_dart_plus` - `v0.1.0+29`

---

#### `firebase_dart` - `v1.6.0`

 - **FEAT**: add clear method to AuthBackend for testing purposes. ([bd438568](https://github.com/appsup-dart/firebase_dart/commit/bd438568dc9e2b386adf8a4df92e43c0dfb206d9))


## 2026-01-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.5.5`](#firebase_dart---v155)
 - [`firebase_dart_flutter` - `v1.3.7`](#firebase_dart_flutter---v137)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+8`](#firebase_dart_flutter_auth_google---v0108)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+8`](#firebase_dart_flutter_auth_facebook---v0018)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+8`](#firebase_dart_flutter_auth_apple---v0018)
 - [`firebase_dart_plus` - `v0.1.0+28`](#firebase_dart_plus---v01028)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.3.7`
 - `firebase_dart_flutter_auth_google` - `v0.1.0+8`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1+8`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1+8`
 - `firebase_dart_plus` - `v0.1.0+28`

---

#### `firebase_dart` - `v1.5.5`

 - **FIX**: bug in version 1.5.4 in RTDB preventing certain queries to receive data. ([53a11277](https://github.com/appsup-dart/firebase_dart/commit/53a112777d4fe2806aad73dc081750784810b29b))


## 2026-01-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.5.4`](#firebase_dart---v154)
 - [`firebase_dart_flutter` - `v1.3.6`](#firebase_dart_flutter---v136)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+7`](#firebase_dart_flutter_auth_google---v0107)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+7`](#firebase_dart_flutter_auth_facebook---v0017)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+7`](#firebase_dart_flutter_auth_apple---v0017)
 - [`firebase_dart_plus` - `v0.1.0+27`](#firebase_dart_plus---v01027)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.3.6`
 - `firebase_dart_flutter_auth_google` - `v0.1.0+7`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1+7`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1+7`
 - `firebase_dart_plus` - `v0.1.0+27`

---

#### `firebase_dart` - `v1.5.4`

 - **PERF**: better performance when many queries on sibling paths. ([4515957c](https://github.com/appsup-dart/firebase_dart/commit/4515957cba6f22ce27d4a17f9d53f5ca5beca0d0))
 - **FIX**: avoid notifying observers when not in-sync and persistence disabled. ([6cc3ea32](https://github.com/appsup-dart/firebase_dart/commit/6cc3ea329fbc3bc0ad549c861a3e1de44d50be4a))


## 2025-10-07

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.5.3`](#firebase_dart---v153)
 - [`firebase_dart_flutter` - `v1.3.5`](#firebase_dart_flutter---v135)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+6`](#firebase_dart_flutter_auth_google---v0106)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+6`](#firebase_dart_flutter_auth_facebook---v0016)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+6`](#firebase_dart_flutter_auth_apple---v0016)
 - [`firebase_dart_plus` - `v0.1.0+26`](#firebase_dart_plus---v01026)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.3.5`
 - `firebase_dart_flutter_auth_google` - `v0.1.0+6`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1+6`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1+6`
 - `firebase_dart_plus` - `v0.1.0+26`

---

#### `firebase_dart` - `v1.5.3`

 - **REFACTOR**: migrate to dart:js_interop. ([e19c0b09](https://github.com/appsup-dart/firebase_dart/commit/e19c0b09e26b76d170dec0df68a5983778de12d5))
 - **FIX**(database): unlisten when not connected prevents subsequent listens for same query. ([6821849f](https://github.com/appsup-dart/firebase_dart/commit/6821849ff7727f9e9f4688aba8947a986f3729a6))


## 2025-09-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.5.2`](#firebase_dart---v152)
 - [`firebase_dart_flutter` - `v1.3.4`](#firebase_dart_flutter---v134)
 - [`firebase_dart_plus` - `v0.1.0+25`](#firebase_dart_plus---v01025)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+5`](#firebase_dart_flutter_auth_google---v0105)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+5`](#firebase_dart_flutter_auth_facebook---v0015)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+5`](#firebase_dart_flutter_auth_apple---v0015)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter_auth_google` - `v0.1.0+5`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1+5`
 - `firebase_dart_flutter_auth_apple` - `v0.0.1+5`

---

#### `firebase_dart` - `v1.5.2`

 - **REFACTOR**: set min sdk version to 3.5.0. ([cf833367](https://github.com/appsup-dart/firebase_dart/commit/cf8333679d4dfd2fd0686f1df6f8bccf70f5af18))

#### `firebase_dart_flutter` - `v1.3.4`

 - **REFACTOR**: set min sdk version to 3.5.0. ([cf833367](https://github.com/appsup-dart/firebase_dart/commit/cf8333679d4dfd2fd0686f1df6f8bccf70f5af18))

#### `firebase_dart_plus` - `v0.1.0+25`

 - **REFACTOR**: set min sdk version to 3.5.0. ([cf833367](https://github.com/appsup-dart/firebase_dart/commit/cf8333679d4dfd2fd0686f1df6f8bccf70f5af18))


## 2025-09-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.5.1`](#firebase_dart---v151)
 - [`firebase_dart_flutter` - `v1.3.3`](#firebase_dart_flutter---v133)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+4`](#firebase_dart_flutter_auth_apple---v0014)
 - [`firebase_dart_plus` - `v0.1.0+24`](#firebase_dart_plus---v01024)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+4`](#firebase_dart_flutter_auth_facebook---v0014)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+4`](#firebase_dart_flutter_auth_google---v0104)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter_auth_facebook` - `v0.0.1+4`
 - `firebase_dart_flutter_auth_google` - `v0.1.0+4`

---

#### `firebase_dart` - `v1.5.1`

 - **REFACTOR**: set min sdk to 3.0.0. ([8ec08cdb](https://github.com/appsup-dart/firebase_dart/commit/8ec08cdb01f285d79ca5ea32638159b839e9091a))

#### `firebase_dart_flutter` - `v1.3.3`

 - **REFACTOR**: support for package_info_plus ^9.0.0. ([ffe6ed62](https://github.com/appsup-dart/firebase_dart/commit/ffe6ed6211f48bd07d355127d01a458234bdc86b))
 - **REFACTOR**: set min sdk to 3.0.0. ([8ec08cdb](https://github.com/appsup-dart/firebase_dart/commit/8ec08cdb01f285d79ca5ea32638159b839e9091a))

#### `firebase_dart_flutter_auth_apple` - `v0.0.1+4`

 - **REFACTOR**: support for sign_in_with_apple ^7.0.0. ([eb05194e](https://github.com/appsup-dart/firebase_dart/commit/eb05194e726eafe7e1d0f8c566f48a52816d08d5))

#### `firebase_dart_plus` - `v0.1.0+24`

 - **REFACTOR**: set min sdk to 3.0.0. ([8ec08cdb](https://github.com/appsup-dart/firebase_dart/commit/8ec08cdb01f285d79ca5ea32638159b839e9091a))


## 2025-09-05

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.5.0`](#firebase_dart---v150)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+3`](#firebase_dart_flutter_auth_apple---v0013)
 - [`firebase_dart_plus` - `v0.1.0+23`](#firebase_dart_plus---v01023)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+3`](#firebase_dart_flutter_auth_google---v0103)
 - [`firebase_dart_flutter` - `v1.3.2`](#firebase_dart_flutter---v132)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+3`](#firebase_dart_flutter_auth_facebook---v0013)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter_auth_apple` - `v0.0.1+3`
 - `firebase_dart_plus` - `v0.1.0+23`
 - `firebase_dart_flutter_auth_google` - `v0.1.0+3`
 - `firebase_dart_flutter` - `v1.3.2`
 - `firebase_dart_flutter_auth_facebook` - `v0.0.1+3`

---

#### `firebase_dart` - `v1.5.0`

 - **FEAT**(auth): support for multi tenancy. ([b941d543](https://github.com/appsup-dart/firebase_dart/commit/b941d5433d55093591128e401e5a3b09d6815c4a))


## 2025-08-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.4.5`](#firebase_dart---v145)
 - [`firebase_dart_flutter` - `v1.3.1`](#firebase_dart_flutter---v131)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+2`](#firebase_dart_flutter_auth_facebook---v0012)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+2`](#firebase_dart_flutter_auth_apple---v0012)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+2`](#firebase_dart_flutter_auth_google---v0102)
 - [`firebase_dart_plus` - `v0.1.0+22`](#firebase_dart_plus---v01022)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter_auth_apple` - `v0.0.1+2`
 - `firebase_dart_flutter_auth_google` - `v0.1.0+2`
 - `firebase_dart_plus` - `v0.1.0+22`

---

#### `firebase_dart` - `v1.4.5`

 - **FIX**: recaptcha when running in isolate. ([951eb1f4](https://github.com/appsup-dart/firebase_dart/commit/951eb1f471a714c37b346698aaa3da6049200578))

#### `firebase_dart_flutter` - `v1.3.1`

 - **FIX**: recaptcha when running in isolate. ([951eb1f4](https://github.com/appsup-dart/firebase_dart/commit/951eb1f471a714c37b346698aaa3da6049200578))

#### `firebase_dart_flutter_auth_facebook` - `v0.0.1+2`

 - **DOCS**: fix LICENSE. ([bdf073a9](https://github.com/appsup-dart/firebase_dart/commit/bdf073a954c93992cc8fbed943dcd90158f4ea8c))


## 2025-08-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.4.4`](#firebase_dart---v144)
 - [`firebase_dart_flutter` - `v1.3.0`](#firebase_dart_flutter---v130)
 - [`firebase_dart_flutter_auth_apple` - `v0.0.1+1`](#firebase_dart_flutter_auth_apple---v0011)
 - [`firebase_dart_flutter_auth_facebook` - `v0.0.1+1`](#firebase_dart_flutter_auth_facebook---v0011)
 - [`firebase_dart_flutter_auth_google` - `v0.1.0+1`](#firebase_dart_flutter_auth_google---v0101)
 - [`firebase_dart_plus` - `v0.1.0+21`](#firebase_dart_plus---v01021)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+21`

---

#### `firebase_dart` - `v1.4.4`

 - **REFACTOR**(firebase_dart_flutter): move social auth providers to separate packages. ([db2ef04b](https://github.com/appsup-dart/firebase_dart/commit/db2ef04b6c1879fced845731f45d2eceb25a9a70))
 - **FIX**: several fixes for app verification with recaptcha. ([8890f308](https://github.com/appsup-dart/firebase_dart/commit/8890f308d06ef9f96f52925a464d4e630b6c8609))
 - **FIX**: use 127.0.0.1 as host instead of localhost for recaptcha when running on vm. ([f129ab5f](https://github.com/appsup-dart/firebase_dart/commit/f129ab5f63debc52ff0d802a47d8d425a6979185))
 - **FIX**: imports of dart:isolate on web caused issues with webdev. ([984e8b5d](https://github.com/appsup-dart/firebase_dart/commit/984e8b5dd78e50bb4a45f2f5f67b2e6ac9da12a3))
 - **FIX**: executing recaptcha challenge twice. ([5101fbe5](https://github.com/appsup-dart/firebase_dart/commit/5101fbe5ad88f69fd893e15a58520e5347f22057))

#### `firebase_dart_flutter` - `v1.3.0`

 - **REFACTOR**(firebase_dart_flutter): move social auth providers to separate packages. ([db2ef04b](https://github.com/appsup-dart/firebase_dart/commit/db2ef04b6c1879fced845731f45d2eceb25a9a70))
 - **FIX**: several fixes for app verification with recaptcha. ([8890f308](https://github.com/appsup-dart/firebase_dart/commit/8890f308d06ef9f96f52925a464d4e630b6c8609))
 - **FEAT**: use in app recaptcha as fallback for app verification. ([1ea6d495](https://github.com/appsup-dart/firebase_dart/commit/1ea6d495114a736044c1a3e1049e514ad1bdf058))

#### `firebase_dart_flutter_auth_apple` - `v0.0.1+1`

 - **REFACTOR**(firebase_dart_flutter): move social auth providers to separate packages. ([db2ef04b](https://github.com/appsup-dart/firebase_dart/commit/db2ef04b6c1879fced845731f45d2eceb25a9a70))

#### `firebase_dart_flutter_auth_facebook` - `v0.0.1+1`

 - **REFACTOR**(firebase_dart_flutter): move social auth providers to separate packages. ([db2ef04b](https://github.com/appsup-dart/firebase_dart/commit/db2ef04b6c1879fced845731f45d2eceb25a9a70))

#### `firebase_dart_flutter_auth_google` - `v0.1.0+1`

 - **REFACTOR**(firebase_dart_flutter): move social auth providers to separate packages. ([db2ef04b](https://github.com/appsup-dart/firebase_dart/commit/db2ef04b6c1879fced845731f45d2eceb25a9a70))


## 2025-07-01

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.4.3`](#firebase_dart---v143)
 - [`firebase_dart_plus` - `v0.1.0+20`](#firebase_dart_plus---v01020)
 - [`firebase_dart_flutter` - `v1.2.3`](#firebase_dart_flutter---v123)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+20`
 - `firebase_dart_flutter` - `v1.2.3`

---

#### `firebase_dart` - `v1.4.3`

 - **FIX**(database): error `Invalid argument(s): Mapping for ... exists` (in bimap.dart). ([a8893eb4](https://github.com/appsup-dart/firebase_dart/commit/a8893eb453b0b774a30607ccc5b0479de025def8))
 - **FIX**: error when accessing MemoryBackend without first calling FirebaseDart.setup(). ([c679731a](https://github.com/appsup-dart/firebase_dart/commit/c679731a896c72973788b357a9355e3154cdcc51))


## 2025-06-08

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.4.2`](#firebase_dart---v142)
 - [`firebase_dart_plus` - `v0.1.0+19`](#firebase_dart_plus---v01019)
 - [`firebase_dart_flutter` - `v1.2.2`](#firebase_dart_flutter---v122)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+19`
 - `firebase_dart_flutter` - `v1.2.2`

---

#### `firebase_dart` - `v1.4.2`

 - **FIX**: ensure permission denied errors are not propagated to other queries. ([cc79863c](https://github.com/appsup-dart/firebase_dart/commit/cc79863c3bb0ee7a1ab41290c9eadb46ee029547))
 - **FIX**: ensure permission denied errors are properly propagated on subsequent listens. ([9bd85cb6](https://github.com/appsup-dart/firebase_dart/commit/9bd85cb6498a0b3e74302cae28d9af2138fed924))


## 2025-06-03

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.4.1`](#firebase_dart---v141)
 - [`firebase_dart_plus` - `v0.1.0+18`](#firebase_dart_plus---v01018)
 - [`firebase_dart_flutter` - `v1.2.1`](#firebase_dart_flutter---v121)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+18`
 - `firebase_dart_flutter` - `v1.2.1`

---

#### `firebase_dart` - `v1.4.1`

 - **REFACTOR**: added support for intl 0.20. ([9bacf020](https://github.com/appsup-dart/firebase_dart/commit/9bacf0204eb6ce572166b150c719beb5f26adf0f))
 - **REFACTOR**(database): keep track of parent registration state in MasterView. ([4dfbc6d7](https://github.com/appsup-dart/firebase_dart/commit/4dfbc6d7ca43072bc2fa42c63da30317078abb1a))
 - **REFACTOR**(database): keep track of registration state in MasterView. ([9524aa85](https://github.com/appsup-dart/firebase_dart/commit/9524aa858d76bcb5deb0ab3fb303fc65d9dd2708))
 - **FIX**(database): write ack should update server version when not in sync. ([508f83ad](https://github.com/appsup-dart/firebase_dart/commit/508f83ad2b7a9523ca54c9b2c5c1f76664ab818b))
 - **FIX**(database): unacknowledged user operations not always visible in new queries. ([6bb78960](https://github.com/appsup-dart/firebase_dart/commit/6bb789609948f212a393a5354435c96f933aa4a9))
 - **FIX**(database): server version out of sync in particular cases. ([eb0f6b1e](https://github.com/appsup-dart/firebase_dart/commit/eb0f6b1e182babcaaa960166dc62e1e00bce7d70))


## 2025-05-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.4.0`](#firebase_dart---v140)
 - [`firebase_dart_flutter` - `v1.2.0`](#firebase_dart_flutter---v120)
 - [`firebase_dart_plus` - `v0.1.0+17`](#firebase_dart_plus---v01017)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+17`

---

#### `firebase_dart` - `v1.4.0`

 - **REFACTOR**(database): move SyncTreeRecording to package code. ([3bcc9f88](https://github.com/appsup-dart/firebase_dart/commit/3bcc9f88a6d911f6b602adbf3c4f681dae679084))
 - **FIX**: Null check operator used on a null value, when reconnecting with a query that gets upgraded. ([b1618b3c](https://github.com/appsup-dart/firebase_dart/commit/b1618b3c28151f5901e29e87ca94e8103cbfdfd8))
 - **FEAT**: allow custom application verifier in FirebaseDartFlutter.setup. ([5f36c2c2](https://github.com/appsup-dart/firebase_dart/commit/5f36c2c2ded139517024fd1d3e8385bb876f659b))

#### `firebase_dart_flutter` - `v1.2.0`

 - **REFACTOR**: log problems verifying app with apns on ios. ([deb7a355](https://github.com/appsup-dart/firebase_dart/commit/deb7a355d26bf48408bb45d92fa0d14b5377ca4b))
 - **FIX**: app not moved to foreground after interacting with recaptcha. ([740d3162](https://github.com/appsup-dart/firebase_dart/commit/740d316243ffec84707c02ac6e673702a68a3803))
 - **FEAT**: allow custom application verifier in FirebaseDartFlutter.setup. ([5f36c2c2](https://github.com/appsup-dart/firebase_dart/commit/5f36c2c2ded139517024fd1d3e8385bb876f659b))


## 2025-04-13

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.3.6`](#firebase_dart---v136)
 - [`firebase_dart_plus` - `v0.1.0+16`](#firebase_dart_plus---v01016)
 - [`firebase_dart_flutter` - `v1.1.19`](#firebase_dart_flutter---v1119)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.1.19`

---

#### `firebase_dart` - `v1.3.6`

 - **FIX**(database): previously complete query should not notify new targets. ([d3339749](https://github.com/appsup-dart/firebase_dart/commit/d3339749115656cbcaf079ad264556a3a5b93a4c))

#### `firebase_dart_plus` - `v0.1.0+16`

 - **FIX**(firebase_dart_plus): allow recursive write batches. ([1e50d8ad](https://github.com/appsup-dart/firebase_dart/commit/1e50d8adeb283b3ad8156648d25d5c13bcff4a0e))


## 2025-04-09

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.3.5`](#firebase_dart---v135)
 - [`firebase_dart_flutter` - `v1.1.18`](#firebase_dart_flutter---v1118)
 - [`firebase_dart_plus` - `v0.1.0+15`](#firebase_dart_plus---v01015)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.1.18`
 - `firebase_dart_plus` - `v0.1.0+15`

---

#### `firebase_dart` - `v1.3.5`

 - **FIX**: timeouts when using `withClock`. ([31801ed9](https://github.com/appsup-dart/firebase_dart/commit/31801ed9fe8b9792b3749ae38544d865ac63666d))


## 2025-03-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.3.4`](#firebase_dart---v134)
 - [`firebase_dart_plus` - `v0.1.0+14`](#firebase_dart_plus---v01014)
 - [`firebase_dart_flutter` - `v1.1.17`](#firebase_dart_flutter---v1117)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+14`
 - `firebase_dart_flutter` - `v1.1.17`

---

#### `firebase_dart` - `v1.3.4`

 - **FIX**(database): writing some invalid (not-json-serializable) data will throw immediately. ([554a249b](https://github.com/appsup-dart/firebase_dart/commit/554a249b9c7f1df9d460455d272e7b57eb8de71c))
 - **FIX**(database): never consider a limiting query complete as it may contain a priority. ([8cf55c07](https://github.com/appsup-dart/firebase_dart/commit/8cf55c07337cd14a48a4cacd5a7326c1a2f4c805))
 - **FIX**(database): getting outdated result from persistent storage. ([689e160e](https://github.com/appsup-dart/firebase_dart/commit/689e160eaad0acb25a3a81b1853daae62126db13))
 - **FIX**(database): persistent storage data lost when multiple operations in short time. ([b109feff](https://github.com/appsup-dart/firebase_dart/commit/b109feff724f3a66abd49bd62b3e69c4a262e6fe))


## 2025-02-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.3.3`](#firebase_dart---v133)
 - [`firebase_dart_plus` - `v0.1.0+13`](#firebase_dart_plus---v01013)
 - [`firebase_dart_flutter` - `v1.1.16`](#firebase_dart_flutter---v1116)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+13`
 - `firebase_dart_flutter` - `v1.1.16`

---

#### `firebase_dart` - `v1.3.3`

 - **FIX**: auth requests throwing HttpException: Unexpected response (unsolicited response without request). ([3a2bb44b](https://github.com/appsup-dart/firebase_dart/commit/3a2bb44beeb11199158e82babb37f55661989f2e))


## 2025-02-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart_flutter` - `v1.1.15`](#firebase_dart_flutter---v1115)

---

#### `firebase_dart_flutter` - `v1.1.15`

 - **FIX**(firebase_dart_flutter): fixes error for phone auth and mfa. ([e7717754](https://github.com/appsup-dart/firebase_dart/commit/e771775412c410688b9df842f4013420c48f5754))


## 2025-02-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.3.2`](#firebase_dart---v132)
 - [`firebase_dart_plus` - `v0.1.0+12`](#firebase_dart_plus---v01012)
 - [`firebase_dart_flutter` - `v1.1.14`](#firebase_dart_flutter---v1114)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+12`
 - `firebase_dart_flutter` - `v1.1.14`

---

#### `firebase_dart` - `v1.3.2`

 - **PERF**(database): improve performance when lots of query registrations and deregistrations. ([5fd6eaea](https://github.com/appsup-dart/firebase_dart/commit/5fd6eaea2935806e4727aaac18f1785046857a70))


## 2025-02-11

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.3.1`](#firebase_dart---v131)
 - [`firebase_dart_plus` - `v0.1.0+11`](#firebase_dart_plus---v01011)
 - [`firebase_dart_flutter` - `v1.1.13`](#firebase_dart_flutter---v1113)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+11`
 - `firebase_dart_flutter` - `v1.1.13`

---

#### `firebase_dart` - `v1.3.1`

 - **REFACTOR**: acknowledge all pending unlistens on disconnected. ([df0c4de2](https://github.com/appsup-dart/firebase_dart/commit/df0c4de200f1c9025e0996472ba052473a1059cf))
 - **FIX**(database): bug that causes no or wrong data returned from query in rare cases. ([ac86787a](https://github.com/appsup-dart/firebase_dart/commit/ac86787aa9097a0427a5c004bed814dde6f78cde))


## 2025-01-01

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.3.0`](#firebase_dart---v130)
 - [`firebase_dart_flutter` - `v1.1.12`](#firebase_dart_flutter---v1112)
 - [`firebase_dart_plus` - `v0.1.0+10`](#firebase_dart_plus---v01010)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+10`

---

#### `firebase_dart` - `v1.3.0`

 - **FEAT**: added ServerValue.increment server value. ([f63f56a2](https://github.com/appsup-dart/firebase_dart/commit/f63f56a28edffb71880cadc979e310fd0d68939b))
 - **FEAT**: remove recaptcha logo after verification on web. ([6b491e92](https://github.com/appsup-dart/firebase_dart/commit/6b491e92a84f43ca8f9fe46f112041725cc33d11))

#### `firebase_dart_flutter` - `v1.1.12`

 - **FIX**: handling recaptcha response on desktop. ([4237e9db](https://github.com/appsup-dart/firebase_dart/commit/4237e9db4045dc09072011bc917fcf3db6029f21))


## 2024-12-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart_flutter` - `v1.1.11`](#firebase_dart_flutter---v1111)

---

#### `firebase_dart_flutter` - `v1.1.11`

 - **REFACTOR**(firebase_dart_flutter): remove dependency on uni_links. ([ab876896](https://github.com/appsup-dart/firebase_dart/commit/ab876896985cf5ac3db7af506aa71ffacb0d59d4))


## 2024-11-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.2.3`](#firebase_dart---v123)
 - [`firebase_dart_flutter` - `v1.1.10`](#firebase_dart_flutter---v1110)
 - [`firebase_dart_plus` - `v0.1.0+9`](#firebase_dart_plus---v0109)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_flutter` - `v1.1.10`
 - `firebase_dart_plus` - `v0.1.0+9`

---

#### `firebase_dart` - `v1.2.3`

 - **PERF**(database): improve memory usage when many listen/unlistens. ([95981df5](https://github.com/appsup-dart/firebase_dart/commit/95981df5aec4ffb724d5f63d98cb4bd2823b8360))


## 2024-10-16

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.2.2`](#firebase_dart---v122)
 - [`firebase_dart_flutter` - `v1.1.9`](#firebase_dart_flutter---v119)
 - [`firebase_dart_plus` - `v0.1.0+8`](#firebase_dart_plus---v0108)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+8`

---

#### `firebase_dart` - `v1.2.2`

 - **REFACTOR**: upgrade minimum sdk to 2.19.0. ([c943f005](https://github.com/appsup-dart/firebase_dart/commit/c943f005c5e444e845d4b64e38c28bca835211a6))
 - **FIX**(database): upgrading of queries when no index. ([497cb098](https://github.com/appsup-dart/firebase_dart/commit/497cb09836a851382b4a911ce870c5306802e1a0))

#### `firebase_dart_flutter` - `v1.1.9`

 - **REFACTOR**: upgrade minimum sdk to 2.19.0. ([c943f005](https://github.com/appsup-dart/firebase_dart/commit/c943f005c5e444e845d4b64e38c28bca835211a6))


## 2023-11-02

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.1.1`](#firebase_dart---v111)
 - [`firebase_dart_flutter` - `v1.1.1`](#firebase_dart_flutter---v111)
 - [`firebase_dart_plus` - `v0.1.0+1`](#firebase_dart_plus---v0101)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0+1`

---

#### `firebase_dart` - `v1.1.1`

 - **REFACTOR**(auth): add stack trace to exception. ([cb204e7c](https://github.com/appsup-dart/firebase_dart/commit/cb204e7cccec31941210756733d99784d5163690))
 - **REFACTOR**(database): add asserts to debug issue with null children. ([f5d45479](https://github.com/appsup-dart/firebase_dart/commit/f5d45479e1e0d993fd1510b0f877d54ec10dcdc9))
 - **FIX**(database): handle when persistent storage corrupt. ([804de4b7](https://github.com/appsup-dart/firebase_dart/commit/804de4b7d627dbdff03fe895cc68d8edacad5608))
 - **FIX**(database): running transactions throw error when app deleted. ([8e2055e9](https://github.com/appsup-dart/firebase_dart/commit/8e2055e9cd04c671e51422bae3ff68ad560e5101))
 - **FIX**(database): fix StateError `Should not call rerun when transactions are running`. ([1cfca21f](https://github.com/appsup-dart/firebase_dart/commit/1cfca21f96c20e93b1a895e15582c06b15c5b219))

#### `firebase_dart_flutter` - `v1.1.1`

 - **FIX**(auth): "Error receiving broadcast Intent". ([c8411ecf](https://github.com/appsup-dart/firebase_dart/commit/c8411ecfadda60b07049caf138b1fa34b3e37c95))


## 2023-10-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.1.0`](#firebase_dart---v110)
 - [`firebase_dart_flutter` - `v1.1.0`](#firebase_dart_flutter---v110)
 - [`firebase_dart_plus` - `v0.1.0`](#firebase_dart_plus---v010)

Packages graduated to a stable release (see pre-releases prior to the stable version for changelog entries):

 - `firebase_dart` - `v1.1.0`
 - `firebase_dart_flutter` - `v1.1.0`
 - `firebase_dart_plus` - `v0.1.0`

---

#### `firebase_dart` - `v1.1.0`

#### `firebase_dart_flutter` - `v1.1.0`

#### `firebase_dart_plus` - `v0.1.0`


## 2023-10-16

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart` - `v1.1.0-dev.12`](#firebase_dart---v110-dev12)
 - [`firebase_dart_plus` - `v0.1.0-dev.5`](#firebase_dart_plus---v010-dev5)
 - [`firebase_dart_flutter` - `v1.1.0-dev.10`](#firebase_dart_flutter---v110-dev10)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `firebase_dart_plus` - `v0.1.0-dev.5`
 - `firebase_dart_flutter` - `v1.1.0-dev.10`

---

#### `firebase_dart` - `v1.1.0-dev.12`

 - **REFACTOR**(firebase_dart): support intl ^0.18.0. ([0daa8dbb](https://github.com/appsup-dart/firebase_dart/commit/0daa8dbbc1688c021b8bebba90e8521ebeaf6dca))
 - **REFACTOR**(firebase_dart): support http package ^1.0.0 (pull request [#47](https://github.com/appsup-dart/firebase_dart/issues/47) from xclud). ([c20f0cb6](https://github.com/appsup-dart/firebase_dart/commit/c20f0cb6b37bc18953a5476f6a2f859dc5dc7374))
 - **FIX**(database): SocketException when trying to connect without internet connection (issue [#39](https://github.com/appsup-dart/firebase_dart/issues/39)). ([db96095d](https://github.com/appsup-dart/firebase_dart/commit/db96095d79dab80fa69e66585c8e2de5f4ebf03e))
 - **FIX**(database): database looses connection when idling during 60 seconds (issue [#40](https://github.com/appsup-dart/firebase_dart/issues/40)). ([c6230aae](https://github.com/appsup-dart/firebase_dart/commit/c6230aae2e4e5184301b5db28938c6bafb0aef9d))
 - **FIX**(storage): ListResult.toJson writing items iso prefix (pull request [#46](https://github.com/appsup-dart/firebase_dart/issues/46) from tomassasovsky). ([d2962e2f](https://github.com/appsup-dart/firebase_dart/commit/d2962e2f0795c47bad616fef5ce01e8d73cae12c))
 - **FIX**: launchUrl throwing exception before redirecting (pull request [#42](https://github.com/appsup-dart/firebase_dart/issues/42) from TimWhiting). ([6ac91a55](https://github.com/appsup-dart/firebase_dart/commit/6ac91a55a0e5c74de066a856a70a977cd2b84c53))
 - **FIX**: prefix not working on toJson. ([2a4bbc9f](https://github.com/appsup-dart/firebase_dart/commit/2a4bbc9f20211b4267959415781083afbea974ed))


## 2023-09-12

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart_plus` - `v0.1.0-dev.4`](#firebase_dart_plus---v010-dev4)

---

#### `firebase_dart_plus` - `v0.1.0-dev.4`

 - **REFACTOR**(firebase_dart_plus): relax dependency of rxdart to 0.27.0. ([c4167219](https://github.com/appsup-dart/firebase_dart/commit/c4167219c446b76fb38e4dab2fbf10abab649ec2))


## 2023-09-12

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart_plus` - `v0.1.0-dev.3`](#firebase_dart_plus---v010-dev3)

---

#### `firebase_dart_plus` - `v0.1.0-dev.3`

 - **FEAT**(firebase_dart_plus): implement onValue for WriteBatch. ([84117e2b](https://github.com/appsup-dart/firebase_dart/commit/84117e2b8aa86a3d030caffa7af2a4fa093d15a7))


## 2023-09-11

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`firebase_dart_plus` - `v0.1.0-dev.2`](#firebase_dart_plus---v010-dev2)

---

#### `firebase_dart_plus` - `v0.1.0-dev.2`

 - **REFACTOR**(firebase_dart_flutter): WriteBatch constructor now takes a DatabaseReference. ([9d79d93a](https://github.com/appsup-dart/firebase_dart/commit/9d79d93a3fdad84e7fb5bcd71aaef692f0ac4be9))

