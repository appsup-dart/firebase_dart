import 'dart:js_interop';
import 'dart:js_interop_unsafe';

dynamic getObjectRef(String ref) {
  JSObject? m = globalContext;
  for (var k in ref.split('.')) {
    m = m?.getProperty(k.toJS) as JSObject?;
  }
  return m;
}

class Delay {
  final Duration minDelay;
  final Duration maxDelay;

  Delay(this.minDelay, this.maxDelay);

  Duration get() => maxDelay;
}
