# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

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

