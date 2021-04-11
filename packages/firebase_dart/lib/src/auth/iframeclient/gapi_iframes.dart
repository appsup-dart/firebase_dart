@JS('gapi.iframes')
library gapi.iframes;

import 'dart:async';
import 'dart:html';

import 'package:js/js.dart';

@JS()
external Context getContext();

@JS()
class Iframe {
  external IThenable ping();

  external void restyle(Map<String, dynamic> parameters);

  external void send(
      String type, dynamic data, Function onDone, IframesFilter filter);

  external void register(String eventName, Function(dynamic, dynamic) callback,
      [IframesFilter filter]);
  external void unregister(
      String eventName, Function(dynamic, dynamic) callback);
}

@JS()
@anonymous
abstract class Context {
  external void openChild(IframeOptions options);

  external void open(IframeOptions options, [Function(Iframe) onOpen]);
}

@JS()
@anonymous
abstract class IframeOptions {
  external String get url;
  external HtmlElement? get where;
  external Map<String, dynamic>? get attributes;
  external IframesFilter? messageHandlersFilter;
  external bool? dontclear;

  external factory IframeOptions(
      {String url,
      HtmlElement? where,
      Map<String, dynamic>? attributes,
      IframesFilter? messageHandlersFilter,
      bool? dontclear});
}

@JS()
@anonymous
abstract class IThenable {
  external void then(Function callback, Function onError);
}

extension IThenableX on IThenable {
  Future<void> asFuture() {
    var completer = Completer<void>();
    then(allowInterop(completer.complete),
        allowInterop(completer.completeError));
    return completer.future;
  }
}

@JS()
external IframesFilter get CROSS_ORIGIN_IFRAMES_FILTER;

@JS()
abstract class IframesFilter {}
