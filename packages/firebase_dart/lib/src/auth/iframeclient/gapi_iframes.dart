// ignore_for_file: non_constant_identifier_names

@JS('gapi.iframes')
library;

import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart';

@JS()
external Context getContext();

@JS()
extension type Iframe._(JSObject _) implements JSObject {
  external IThenable ping();

  external void restyle(IframeRestyleOptions parameters);

  external void send(
      String type, JSAny data, JSFunction onDone, IframesFilter filter);

  external void register(String eventName, IframeEventHandler callback,
      [IframesFilter filter]);
  external void unregister(String eventName, IframeEventHandler callback);
}

@JS()
@anonymous
extension type Context._(JSObject _) implements JSObject {
  external void openChild(IframeOptions options);

  external void open(IframeOptions options, [JSFunction onOpen]);
}

@JS()
@anonymous
extension type IframeAttributes._(JSObject _) implements JSObject {
  external CSSStyleDeclaration? style;

  external factory IframeAttributes({CSSStyleDeclaration? style});
}

@JS()
@anonymous
extension type IframeRestyleOptions._(JSObject _) implements JSObject {
  external bool? setHideOnLeave;

  external factory IframeRestyleOptions({bool? setHideOnLeave});
}

@JS()
@anonymous
extension type IframeEvent._(JSObject _) implements JSObject {
  external String type;

  external IframeAuthEvent? authEvent;
}

@JS()
@anonymous
extension type IframeEventHandlerResponse._(JSObject _) implements JSObject {
  external String status;

  external factory IframeEventHandlerResponse({String status});
}

typedef IframeEventHandler = JSFunction;

@JS()
@anonymous
extension type IframeAuthEvent._(JSObject _) implements JSObject {
  external String? eventId;

  external String? postBody;

  external String? sessionId;

  external String? providerId;

  external String? tenantId;

  external String type;

  external String? urlResponse;

  external IframeError? error;
}

@JS()
@anonymous
extension type IframeError._(JSObject _) implements JSObject {
  external String code;

  external String message;
}

@JS()
@anonymous
extension type IframeOptions._(JSObject _) implements JSObject {
  external String get url;
  external HTMLElement? get where;
  external IframeAttributes? get attributes;
  external IframesFilter? messageHandlersFilter;
  external bool? dontclear;

  external factory IframeOptions(
      {String url,
      HTMLElement? where,
      IframeAttributes? attributes,
      IframesFilter? messageHandlersFilter,
      bool? dontclear});
}

@JS()
@anonymous
extension type IThenable._(JSObject _) implements JSObject {
  external void then(JSFunction callback, JSFunction onError);

  Future<void> toFuture() {
    var completer = Completer<void>();
    then(
        () {
          completer.complete();
        }.toJS,
        (JSAny error) {
          completer.completeError(error);
        }.toJS);
    return completer.future;
  }
}

@JS()
external IframesFilter get CROSS_ORIGIN_IFRAMES_FILTER;

@JS()
extension type IframesFilter._(JSObject _) implements JSObject {}
