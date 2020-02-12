import 'dart:io';
import 'package:dart2_constant/convert.dart';

Map get secrets {
  var f = File('test/secrets.json');
  if (!f.existsSync()) {
    throw Exception('Cannot test Authenticate: no secrets.json file');
  }

  return json.decode(f.readAsStringSync());
}
