import 'dart:js';

dynamic getObjectRef(String ref) {
  dynamic m = context;
  for (var k in ref.split('.')) {
    m = m?[k];
  }
  return m;
}

class Delay {
  final Duration minDelay;
  final Duration maxDelay;

  Delay(this.minDelay, this.maxDelay);

  Duration get() => maxDelay;
}
