import 'package:firebase_dart/src/implementation/testing.dart';
import 'package:http/http.dart' as http;

http.Client createHttpClient() {
  return TestClient(BackendRef());
}
