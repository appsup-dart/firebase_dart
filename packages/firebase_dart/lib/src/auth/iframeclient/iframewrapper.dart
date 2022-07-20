// ignore_for_file: constant_identifier_names, non_constant_identifier_names

@JS()
library iframewrapper;

import 'package:js/js.dart';

import 'dart:async';
import 'dart:html';
import 'dart:js';
import 'dart:math';
import 'gapi.dart' as gapi;
import 'gapi_iframes.dart' as gapi;
import 'gapi_iframes.dart';
import 'util.dart' as util;

/// Defines the hidden iframe wrapper for cross origin communications.
class IframeWrapper {
  /// The hidden iframe URL.
  final String url;

  late gapi.Iframe _iframe;

  /// A future that resolves on iframe open.
  late final Future<void> _onIframeOpen = _open();

  IframeWrapper(this.url);

  /// The future that resolves when the iframe is ready.
  Future<void> get onReady => _onIframeOpen;

  /// Opens an iframe.
  Future<void> _open() async {
    return IframeWrapper._loadGApiJs().then((_) {
      var completer = Completer<void>();

      var container = DivElement();
      document.body!.append(container);
      gapi.getContext().open(
          gapi.IframeOptions(
              where: container,
              url: url,
              messageHandlersFilter: gapi.CROSS_ORIGIN_IFRAMES_FILTER,
              attributes: gapi.IframeAttributes(
                  style: CssStyleDeclaration()
                    ..position = 'absolute'
                    ..top = '-100px'
                    ..width = '1px'
                    ..height = '1px'),
              dontclear: true), allowInterop(
        (iframe) {
          _iframe = iframe;
          _iframe.restyle(gapi.IframeRestyleOptions(
              // Prevent iframe from closing on mouse out.
              setHideOnLeave: false));

          // This returns an IThenable. However the reject part does not call
          // when the iframe is not loaded.
          promiseToFuture(iframe.ping())
              // Confirm iframe is correctly loaded.
              // To fallback on failure, set a timeout.
              .timeout(PING_TIMEOUT_.get())
              .then((_) => completer.complete(), onError: (error) {
            completer.completeError(Exception('Network Error'));
          });
        },
      ));
      return completer.future.then((_) => print('completed'));
    });
  }

  Future<Map<String, dynamic>?> sendMessage(Message message) {
    return _onIframeOpen.then((_) {
      var completer = Completer<Map<String, dynamic>?>();

      _iframe.send(message.type, message, allowInterop(completer.complete),
          gapi.CROSS_ORIGIN_IFRAMES_FILTER);
      return completer.future;
    });
  }

  /// Registers a listener to a post message.
  void registerEvent(String eventName,
      IframeEventHandlerResponse Function(IframeEvent) handler) {
    _onIframeOpen.then((_) {
      var h = _handlers[handler] ??= (event, iframe) {
        return handler(event);
      };
      _iframe.register(
          eventName, allowInterop(h), gapi.CROSS_ORIGIN_IFRAMES_FILTER);
    });
  }

  final Expando<IframeEventHandler> _handlers = Expando();

  /// Unregisters a listener to a post message.
  void unregisterEvent(String eventName, Function(dynamic) handler) {
    _onIframeOpen.then((_) {
      _iframe.unregister(eventName, allowInterop(_handlers[handler]!));
    });
  }

  /// The GApi loader URL.
  static const GAPI_LOADER_SRC_ = 'https://apis.google.com/js/api.js';

  /// The gapi.load network error timeout delay with units in ms.
  static final NETWORK_TIMEOUT_ =
      util.Delay(Duration(seconds: 30), Duration(seconds: 60));

  /// The iframe ping error timeout delay with units in ms.
  static final PING_TIMEOUT_ =
      util.Delay(Duration(seconds: 5), Duration(seconds: 15));

  /// The cached GApi loader promise.
  static dynamic _cachedGApiLoader;

  /// Resets the cached GApi loader.
  static void resetCachedGApiLoader() {
    IframeWrapper._cachedGApiLoader = null;
  }

  static final _random = Random();

  /// Loads the GApi client library if it is not loaded for gapi.iframes usage.
  static Future<void> _loadGApiJs() {
    return IframeWrapper._cachedGApiLoader ??= Future(() async {
      var completer = Completer<void>();

      // Function to run when gapi.load is ready.
      void onGapiLoad() {
        // The developer may have tried to previously run gapi.load and failed.
        // Run this to fix that.
        // TODO fireauth.util.resetUnloadedGapiModules();

        gapi.load(
            'gapi.iframes',
            gapi.LoadConfig(
                callback: allowInterop(completer.complete),
                ontimeout: allowInterop(() {
                  // The above reset may be sufficient, but having this reset after
                  // failure ensures that if the developer calls gapi.load after the
                  // connection is re-established and before another attempt to embed
                  // the iframe, it would work and would not be broken because of our
                  // failed attempt.
                  // Timeout when gapi.iframes.Iframe not loaded.
                  // TODO: fireauth.util.resetUnloadedGapiModules();
                  completer.completeError(Exception('Network Error'));
                }),
                timeout: 30000));
      }

      if (util.getObjectRef('gapi.iframes.Iframe') != null) {
        // If gapi.iframes.Iframe available, resolve.
        completer.complete();
      } else if (util.getObjectRef('gapi.load') != null) {
        // Gapi loader ready, load gapi.iframes.
        onGapiLoad();
      } else {
        // Create a new iframe callback when this is called so as not to overwrite
        // any previous defined callback. This happens if this method is called
        // multiple times in parallel and could result in the later callback
        // overwriting the previous one. This would end up with a iframe
        // timeout.
        var cbName = '__iframefcb${_random.nextInt(1000000)}';
        // GApi loader not available, dynamically load platform.js.
        context[cbName] = allowInterop(() {
          // GApi loader should be ready.
          if (util.getObjectRef('gapi.load') != null) {
            onGapiLoad();
          } else {
            // Gapi loader failed, throw error.
            completer.completeError(Exception('Network Error'));
          }
        });
        // Build GApi loader.
        var url = Uri.parse(IframeWrapper.GAPI_LOADER_SRC_)
            .replace(queryParameters: {'onload': cbName});
        // Load GApi loader.
        var script = ScriptElement()..src = url.toString();
        document.body!.append(script);
      }

      return completer.future;
    }).catchError((error) {
      // Reset cached promise to allow for retrial.
      IframeWrapper._cachedGApiLoader = null;
      throw error;
    });
  }
}

class Message {
  final String type;

  Message({required this.type});
}
