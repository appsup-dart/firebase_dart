import 'dart:async';
import 'dart:html';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/iframeclient/gapi_iframes.dart';
import 'package:firebase_dart/src/auth/iframeclient/url_builder.dart';
import 'iframewrapper.dart';

final IfcHandler ifc = _createIfc(Firebase.apps.first);

class DefaultAuthHandler extends FirebaseAppAuthHandler {
  const DefaultAuthHandler();

  @override
  Future<AuthCredential?> getSignInResult(FirebaseApp app) async {
    var completer = Completer<AuthCredential?>();
    bool callback(IframeAuthEvent r) {
      var error = r.error;
      if (error != null) {
        var code = error.code;
        if (code.startsWith('auth/')) {
          code = code.substring('auth/'.length);
        }
        if (code == 'no-auth-event') return false;
        throw FirebaseAuthException(code, error.message);
      }
      createCredential(
        link: r.urlResponse,
        sessionId: r.sessionId,
        providerId: r.providerId,
        eventId: r.eventId,
      ).then((c) {
        completer.complete(c);
      }).catchError((e, tr) {
        if (e is FirebaseAuthException &&
            e.code == FirebaseAuthException.noAuthEvent().code) {
          return;
        }
        completer.completeError(e, tr);
      });

      return true;
    }

    ifc._authEventListeners.add(callback);
    await ifc.initialize();

    return completer.future
        .whenComplete(() => ifc._authEventListeners.remove(callback));
  }
}

void webLaunchUrl(Uri uri, {bool popup = false}) {
  var width = 500;
  var height = 600;
  var top = (window.screen!.available.height - height) / 2;
  var left = (window.screen!.available.width - width) / 2;

  window.open(
      uri.toString(),
      popup ? '_blank' : '_self',
      !popup
          ? null
          : 'height=$height,width=$width,top=${top > 0 ? top : 0},'
              'left=${left > 0 ? left : 0},location=true,resizable=true,'
              'statusbar=true,toolbar=false');
}

IfcHandler _createIfc(FirebaseApp app) {
  return IfcHandler(
      apiKey: app.options.apiKey,
      authDomain: app.options.authDomain!,
      appName: app.name);
}

/// Provides the mechanism to listen to Auth events on the hidden iframe.
class IfcHandler {
  /// The firebase authDomain used to determine the OAuth helper page domain.
  final String authDomain;

  /// The API key for sending backend Auth requests.
  final String apiKey;

  /// The App ID for the Auth instance that triggered this request.
  final String appName;

  /// The optional client version string.
  final String? clientVersion;

  /// The endpoint ID (staging, test Gaia, etc).
  final String? endpointId;

  /// The iframe URL.
  late final String iframeUrl = _getAuthIframeUrl(
    authDomain: authDomain,
    apiKey: apiKey,
    appName: appName,
    clientVersion: clientVersion,
    endpointId: endpointId,
  );

  /// The initialization promise.
  late final Future<void> _isInitialized = Future(() async {
    // Register all event listeners to Auth event messages sent from Auth
    // iframe.
    _registerEvents();
  });

  late final IframeWrapper _iframeWrapper = IframeWrapper(iframeUrl);

  /// The Auth event listeners.
  final List<bool Function(IframeAuthEvent)> _authEventListeners = [];

  IfcHandler({
    required this.authDomain,
    required this.apiKey,
    required this.appName,
    this.clientVersion,
    this.endpointId,
  });

  static String _getAuthIframeUrl({
    required String authDomain,
    required String apiKey,
    required String appName,
    String? clientVersion,
    String? endpointId,
    List<String>? frameworks,
  }) {
    // OAuth helper iframe URL.
    var builder = IframeUrlBuilder(authDomain, apiKey, appName);
    return builder
        .setVersion(clientVersion)
        .setEndpointId(endpointId)
        .setFrameworks(frameworks)
        .toString();
  }

  /// Initializes the iframe client wrapper.
  Future<void> initialize() {
    return _isInitialized;
  }

  /// Registers all event listeners.
  void _registerEvents() {
    // Listen to Auth change events emitted from iframe.
    _iframeWrapper.registerEvent('authEvent', (response) {
      // Get Auth event
      var authEvent = response.authEvent;
      if (authEvent != null) {
        var isHandled = false;
        // Trigger Auth change on all listeners.
        for (var i = 0; i < _authEventListeners.length; i++) {
          isHandled = _authEventListeners[i](authEvent) || isHandled;
        }
        // Return ack response to notify sender of success.
        return IframeEventHandlerResponse(status: isHandled ? 'ACK' : 'ERROR');
      }
      // Return error status if the response is invalid.
      return IframeEventHandlerResponse(status: 'ERROR');
    });
  }
}
