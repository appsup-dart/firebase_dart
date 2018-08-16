
import 'dart:io';
import 'package:dart2_constant/convert.dart';

Map get secrets {
  var f = new File("test/secrets.json");
  if (!f.existsSync()) {
    throw new Exception("Cannot test Authenticate: no secrets.json file");
  }

  return json.decode(f.readAsStringSync());
}