@JS('gapi')
library;

import 'dart:js_interop';

@JS()
external void load(String libraries, LoadConfig config);

@JS()
@anonymous
extension type LoadConfig._(JSObject _) implements JSObject {
  external factory LoadConfig(
      {JSFunction callback,
      JSFunction onerror,
      num timeout,
      JSFunction ontimeout});
  external JSFunction get callback;
  external JSFunction get onerror;
  external num get timeout;
  external JSFunction get ontimeout;
}
