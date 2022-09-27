@JS()
library grecaptcha;

import 'package:js/js.dart';

@JS()
@anonymous
class GRecaptcha {
  /// Renders the container as a reCAPTCHA widget and returns the ID of the
  /// newly created widget..
  ///
  /// [container] is the HTML element to render the reCAPTCHA widget.
  /// Specify either the ID of the container (string) or the DOM element itself.
  external int render(dynamic container, GRecaptchaParameters options);

  /// Gets the response for the reCAPTCHA widget.
  external String getResponse([int widgetId]);

  /// Programmatically invoke the reCAPTCHA check. Used if the invisible
  /// reCAPTCHA is on a div instead of a button.
  ///
  /// [widgetId] is optional and defaults to the first widget created if
  /// unspecified.
  external void execute([int widgetId]);

  /// Resets the reCAPTCHA widget.
  ///
  /// [widgetId] is optional and defaults to the first widget created if
  /// unspecified.
  external void reset([int widgetId]);
}

@JS('grecaptcha')
external GRecaptcha get grecaptcha;

@JS()
@anonymous
class GRecaptchaParameters {
  /// The sitekey of your reCAPTCHA site.
  external String get sitekey;

  /// Reposition the reCAPTCHA badge. 'inline' lets you position it with CSS.
  ///
  /// Accepted values are: 'bottomright' (default), 'bottomleft', 'inline'.
  external String? get badge;

  /// The color theme of the widget.
  ///
  /// Accepted values are: 'dark', 'light' (default).
  external String? get theme;

  /// The size of the widget.
  ///
  /// Accepted values are: 'normal' (default), 'compact', 'invisible'.
  external String? get size;

  /// The tabindex of the widget and challenge.
  ///
  /// If other elements in your page use tabindex, it should be set to make user
  /// navigation easier.
  external int? get tabindex;

  /// The callback function, executed when the user submits a successful
  /// response.
  ///
  /// The g-recaptcha-response token is passed to your callback.
  external TokenCallback? callback;

  /// The callback function, executed when the reCAPTCHA response expires and
  /// the user needs to re-verify.
  @JS('expired-callback')
  external Function()? expiredCallback;

  /// The callback function, executed when reCAPTCHA encounters an error
  /// (usually network connectivity) and cannot continue until connectivity is
  /// restored.
  ///
  /// If you specify a function here, you are responsible for informing the user
  /// that they should retry.
  @JS('error-callback')
  external Function(Object)? errorCallback;

  external factory GRecaptchaParameters({
    required String sitekey,
    String? badge,
    String? theme,
    String? size,
    int? tabindex,
    TokenCallback? callback,
    @JS('expired-callback') Function()? expiredCallback,
    @JS('error-callback') Function(Object)? errorCallback,
  });
}

typedef TokenCallback = Function(String);
