import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

void main() {
  group('TreeStructuredData.hash', () {
    test('Hash for string', () {
      expect(TreeStructuredData.fromJson('nl').hash,
          'lzXmvmvvpskRQUDqDuTMvZE2AQI=');
      expect(TreeStructuredData.fromJson('default config').hash,
          'wvI1cAKcFCSEHyb527WMjwKCR/o=');
    });
    test('Hash for string with special chars', () {
      expect(TreeStructuredData.fromJson('à').hash,
          '31pfWlkApe+5G1/vDg375CZ+I2M=');
    });
    test('Hash for bool', () {
      expect(TreeStructuredData.fromJson(true).hash,
          'E5z61QM0lN/U2WsOnusszCTkR8M=');
      expect(TreeStructuredData.fromJson(false).hash,
          'aSSNoqcS4oQwJ2xxH20rvpp3zP0=');
    });
  });
}
