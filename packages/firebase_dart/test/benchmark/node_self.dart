import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('globalThis')
external JSObject get _realGlobal;

@JS('Object.defineProperty')
external void _defineProperty(
  JSObject object,
  JSString name,
  JSObject descriptor,
);

/// Makes `self.crypto` readable for dart2js on Node.
///
/// `dart test -p node` prepends `node_preamble`, which sets
/// `self` to `Object.create(globalThis)`. Hive then builds `Random.secure()`
/// while its library loads, and that constructor reads `self.crypto`.
/// The inherited Node getter rejects that `self`, so this installs an own
/// property before Hive loads.
void ensureGlobalSelf() {
  try {
    if (globalContext['crypto'] != null) return;
  } catch (_) {}
  final descriptor = JSObject()..['value'] = _realGlobal['crypto'];
  _defineProperty(globalContext, 'crypto'.toJS, descriptor);
}

/// Runs when this library loads. Import it before Hive.
final bool nodeSelfReady = _bindSelf();

bool _bindSelf() {
  ensureGlobalSelf();
  return true;
}
