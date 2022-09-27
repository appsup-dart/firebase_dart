import 'auth.dart';

import 'recaptcha_verifier_io.dart'
    if (dart.library.html) 'recaptcha_verifier_web.dart';

/// An [reCAPTCHA](https://www.google.com/recaptcha/?authuser=0)-based
/// application verifier.
abstract class RecaptchaVerifier {
  /// Creates a new [RecaptchaVerifier] instance used to render a reCAPTCHA widget
  /// when calling [signInWithPhoneNumber].
  ///
  /// It is possible to configure the reCAPTCHA widget with the following arguments,
  /// however if no arguments are provided, an "invisible" reCAPTCHA widget with
  /// defaults will be created.
  ///
  /// [container] If a value is provided, the element must exist in the DOM when
  ///   [render] or [signInWithPhoneNumber] is called. The reCAPTCHA widget will
  ///   be rendered within the specified DOM element.
  ///
  ///   If no value is provided, an "invisible" reCAPTCHA will be shown when [render]
  ///   is called. An invisible reCAPTCHA widget is shown a modal on-top of your
  ///   application.
  ///
  /// [size] When providing a custom [container], a size (normal or compact) can
  ///   be provided to change the size of the reCAPTCHA widget. This has no effect
  ///    when a [container] is not provided. Defaults to [RecaptchaVerifierSize.normal].
  ///
  /// [theme] When providing a custom [container], a theme (light or dark) can
  ///   be provided to change the appearance of the reCAPTCHA widget. This has no
  ///   effect when a [container] is not provided. Defaults to [RecaptchaVerifierTheme.light].
  ///
  /// [onSuccess] An optional callback which is called when the user successfully
  ///   completes the reCAPTCHA widget.
  ///
  /// [onError] An optional callback which is called when the reCAPTCHA widget errors
  ///   (such as a network issue).
  ///
  /// [onExpired] An optional callback which is called when the reCAPTCHA expires.
  factory RecaptchaVerifier({
    required FirebaseAuth auth,
    String? container,
    RecaptchaVerifierSize size = RecaptchaVerifierSize.normal,
    RecaptchaVerifierTheme theme = RecaptchaVerifierTheme.light,
    RecaptchaVerifierOnSuccess? onSuccess,
    RecaptchaVerifierOnError? onError,
    RecaptchaVerifierOnExpired? onExpired,
  }) {
    return RecaptchaVerifierImpl(
      auth: auth,
      container: container,
      size: size,
      theme: theme,
      onSuccess: onSuccess,
      onError: onError,
      onExpired: onExpired,
    );
  }

  /// The application verifier type. For a reCAPTCHA verifier, this is
  /// 'recaptcha'.
  String get type;

  /// Clears the reCAPTCHA widget from the page and destroys the current
  /// instance.
  void clear();

  /// Renders the reCAPTCHA widget on the page.
  ///
  /// Returns a [Future] that resolves with the reCAPTCHA widget ID.
  Future<int> render();

  /// Waits for the user to solve the reCAPTCHA and resolves with the reCAPTCHA
  /// token.
  Future<String> verify();
}

/// A enum to represent a reCAPTCHA widget size.
enum RecaptchaVerifierSize {
  /// Renders the widget in the default size.
  normal,

  /// Renders the widget in a smaller, compact size.
  compact,
}

/// A enum to represent a reCAPTCHA widget theme.
enum RecaptchaVerifierTheme {
  /// Renders the widget in a light theme (white-gray background).
  light,

  /// Renders the widget in a dark theme (black-gray background).
  dark,
}

/// Called on successful completion of the reCAPTCHA widget.
typedef RecaptchaVerifierOnSuccess = void Function();

/// Called when the reCAPTCHA widget errors (such as a network error).
typedef RecaptchaVerifierOnError = void Function(
  FirebaseAuthException exception,
);

/// Called when the time to complete the reCAPTCHA widget expires.
typedef RecaptchaVerifierOnExpired = void Function();
