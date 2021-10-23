import 'dart:io';
import 'dart:convert';

Map<String, dynamic> get secrets {
  var f = File('test/secrets.json');
  if (!f.existsSync()) {
    throw Exception('Cannot test Authenticate: no secrets.json file');
  }

  return json.decode(f.readAsStringSync());
}
