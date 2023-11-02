# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

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

