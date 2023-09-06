
[:heart: sponsor](https://github.com/sponsors/rbellens)

Some additional features for the `firebase_dart` package.

## Features

### Write batches for realtime database

A WriteBatch is a series of write operations to be performed as one unit.

Operations done on a WriteBatch do not take effect until you commit().

Example code:

```dart

var db = FirebaseDatabase(app: app, databaseURL: 'mem://some.name/');
var batch = db.batch();

var ref = batch.reference();

await ref.child('some/path').set('value1');
await ref.child('some/other/path').set('value2');

await batch.commit();

```



