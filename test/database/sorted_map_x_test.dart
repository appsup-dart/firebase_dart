import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:test/test.dart';

void main() {
  group('KeyValueIntervalX', () {
    group('KeyValueIntervalX.intersects', () {
      test('With fixed value', () {
        var i = KeyValueInterval(4, 0, 10, 0);

        expect(i.intersects(i), true);
        expect(i.intersects(KeyValueInterval(3, 0, 12, 0)), true);

        expect(i.intersects(KeyValueInterval(10, 0, 12, 0)), true);
        expect(i.intersects(KeyValueInterval(1, 0, 4, 0)), true);

        expect(i.intersects(KeyValueInterval(11, 0, 12, 0)), false);
        expect(i.intersects(KeyValueInterval(1, 0, 3, 0)), false);

        expect(i.intersects(KeyValueInterval(10, 0, null, 0)), true);
        expect(i.intersects(KeyValueInterval(null, 0, 4, 0)), true);

        expect(i.intersects(KeyValueInterval(11, 0, null, 0)), false);
        expect(i.intersects(KeyValueInterval(null, 0, 3, 0)), false);
      });

      test('With value range', () {
        var i = KeyValueInterval(4, -10, 10, -5);

        expect(i.intersects(i), true);
        expect(i.intersects(KeyValueInterval(3, -11, 12, -5)), true);

        expect(i.intersects(KeyValueInterval(10, -5, 12, 0)), true);
        expect(i.intersects(KeyValueInterval(1, -20, 4, -10)), true);

        expect(i.intersects(KeyValueInterval(11, -5, 12, 0)), false);
        expect(i.intersects(KeyValueInterval(11, -6, 12, 0)), true);
        expect(i.intersects(KeyValueInterval(1, 0, 3, -10)), false);
        expect(i.intersects(KeyValueInterval(1, 0, 3, -9)), true);
      });
    });

    group('KeyValueIntervalX.coverAll', () {
      test('With fixed value', () {
        expect(
            KeyValueIntervalX.coverAll([
              KeyValueInterval(4, 0, 10, 0),
            ]),
            KeyValueInterval(4, 0, 10, 0));
        expect(
            KeyValueIntervalX.coverAll([
              KeyValueInterval(4, 0, 10, 0),
              KeyValueInterval(11, 0, 13, 0),
              KeyValueInterval(20, 0, 23, 0),
            ]),
            KeyValueInterval(4, 0, 23, 0));
      });
      test('With value range', () {
        expect(
            KeyValueIntervalX.coverAll([
              KeyValueInterval(4, -10, 10, -5),
            ]),
            KeyValueInterval(4, -10, 10, -5));
        expect(
            KeyValueIntervalX.coverAll([
              KeyValueInterval(4, -10, 10, -5),
              KeyValueInterval(11, -20, 13, -19),
              KeyValueInterval(20, -4, 23, 0),
            ]),
            KeyValueInterval(11, -20, 23, 0));
        expect(
            KeyValueIntervalX.coverAll([
              KeyValueInterval(4, -10, 10, null),
              KeyValueInterval(11, null, 13, -19),
              KeyValueInterval(20, -4, 23, 0),
            ]),
            KeyValueInterval(11, null, 10, null));
      });
    });

    group('KeyValueIntervalX.unionAll', () {
      test('', () {
        expect(
            KeyValueIntervalX.unionAll([
              KeyValueInterval(4, -10, 10, -5),
            ]),
            [
              KeyValueInterval(4, -10, 10, -5),
            ]);
        expect(
            KeyValueIntervalX.unionAll([
              KeyValueInterval(4, -10, 10, -5),
              KeyValueInterval(11, -20, 13, -19),
              KeyValueInterval(20, -4, 23, 0),
            ]),
            [
              KeyValueInterval(11, -20, 13, -19),
              KeyValueInterval(4, -10, 10, -5),
              KeyValueInterval(20, -4, 23, 0),
            ]);
        expect(
            KeyValueIntervalX.unionAll([
              KeyValueInterval(4, -10, 10, -5),
              KeyValueInterval(11, -20, 13, -19),
              KeyValueInterval(20, -6, 23, 0),
            ]),
            [
              KeyValueInterval(11, -20, 13, -19),
              KeyValueInterval(4, -10, 23, 0),
            ]);
      });
    });
  });
}
