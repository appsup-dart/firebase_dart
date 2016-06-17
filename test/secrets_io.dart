
import 'dart:io';
import 'dart:convert';

Map get secrets {
  var f = new File("test/secrets.json");
  if (!f.existsSync()) {
    throw new Exception("Cannot test Authenticate: no secrets.json file");
  }

  return JSON.decode(f.readAsStringSync());
}