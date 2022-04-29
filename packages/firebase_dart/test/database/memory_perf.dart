import 'dart:developer';
import 'dart:isolate';
import 'dart:math';
import 'package:firebase_dart/standalone_database.dart';
import 'package:rxdart/rxdart.dart';
import 'package:vm_service/vm_service_io.dart';
import 'package:vm_service/vm_service.dart' hide Isolate;

late final String isolateId;
late final VmService vmService;

Future<void> main(List<String> args) async {
  final serverUri = (await Service.getInfo()).serverUri;

  if (serverUri == null) {
    print('Please run the application with the --observe parameter!');
    return;
  }

  isolateId = Service.getIsolateID(Isolate.current)!;
  vmService = await vmServiceConnectUri(_toWebSocket(serverUri));

  await run();

  await Future.delayed(Duration(milliseconds: 5000));
  await printMemoryUsage();
}

Future<void> printMemoryUsage() async {
  final profile = await vmService.getAllocationProfile(isolateId, gc: true);

  var heap = profile.memoryUsage!.heapUsage!.toDouble();

  var gcTime = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(profile.dateLastServiceGC!));

  print('heap size = ${(heap / 1024 / 1024).round()} MB (gc: $gcTime ago)');
}

int countLeafs(dynamic data) {
  if (data is Map) {
    return data.values.map(countLeafs).fold(0, (a, b) => a + b);
  }
  return 1;
}

int countNonLeafs(dynamic data) {
  if (data is Map) {
    return 1 + data.values.map(countNonLeafs).fold(0, (a, b) => a + b);
  }
  return 0;
}

dynamic composeData({int size = 400}) {
  var r = Random();

  return {
    'resources': {
      for (var i = 0; i < size; i++)
        'resource-$i': {
          'name': 'Resource $i',
          'description': 'this is the ${i}th resource',
          'device': 'device-$i',
          'location': 'location-$i',
          'group': 'group-${i % 3}',
        },
    },
    'locations': {
      for (var i = 0; i < size; i++)
        'location-$i': {
          'name': 'Location $i',
          'description': 'this is the location for resource $i',
          'geometry':
              'POINT(${r.nextDouble() * 360 - 180}, ${r.nextDouble() * 180 - 90})'
        }
    },
    'devices': {
      for (var i = 0; i < size; i++)
        'device-$i': {
          'name': 'This is the device for resource $i',
          'status': {
            'position': {
              'lat': r.nextDouble() * 180 - 90,
              'lon': r.nextDouble() * 360 - 180
            },
            'locked': r.nextBool(),
            'mileage': r.nextDouble() * 100000
          }
        }
    },
    'reservations': {
      for (var i = 0; i < size; i++)
        'resource-$i': {for (var i = 0; i < size; i++) '${r.nextInt(1000)}': ''}
    }
  };
}

Future<void> initDb() async {
  var db = StandaloneFirebaseDatabase('mem://test');

  var data = composeData();
  print('leafs ${countLeafs(data)}');
  print('non-leafs ${countNonLeafs(data)}');

  await db.reference().set(data);
  await printMemoryUsage();
  await db.delete();
}

Future<void> run() async {
  await initDb();
  await printMemoryUsage();

  var db = StandaloneFirebaseDatabase('mem://test');

  var root = db.reference();

  var s = root
      .child('resources')
      .orderByChild('group')
      .equalTo('group-1')
      .onValue
      .map<Map<String, dynamic>>((v) => v.snapshot.value)
      .switchMap((v) {
    return CombineLatestStream(
        v.values.map((v) => v['location']).map((v) => root
            .child('locations')
            .child(v)
            .onValue
            .map<Map<String, dynamic>>((v) => v.snapshot.value)), (locations) {
      return Map.fromIterables(v.entries, locations).map((k, v) {
        return MapEntry(k.key, {...k.value, 'location': v});
      });
    });
  });

  await s.first;
  await printMemoryUsage();

  await db.delete();
  await printMemoryUsage();
}

List<String> _cleanupPathSegments(Uri uri) {
  final pathSegments = <String>[];
  if (uri.pathSegments.isNotEmpty) {
    pathSegments.addAll(uri.pathSegments.where(
      (s) => s.isNotEmpty,
    ));
  }
  return pathSegments;
}

String _toWebSocket(Uri uri) {
  final pathSegments = _cleanupPathSegments(uri);
  pathSegments.add('ws');
  return uri.replace(scheme: 'ws', pathSegments: pathSegments).toString();
}
