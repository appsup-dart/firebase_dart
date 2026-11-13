import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart_flutter/src/app_check/app_attest.dart';
import 'package:firebase_dart_flutter/src/app_check/device_check.dart';
import 'package:firebase_dart_flutter/src/app_check/flutter_app_check_providers.dart';
import 'package:firebase_dart_flutter/src/app_check/play_integrity.dart';
import 'package:firebase_dart_flutter/src/app_check/recaptcha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android adds native reCAPTCHA Enterprise after Play Integrity', () {
    initPlatform(Platform.android(
      packageId: 'be.appsup.example',
      sha1Cert: 'aa:bb',
      isOnline: true,
    ));

    final providers = FlutterAppCheckProviders(
      androidRecaptchaEnterpriseSiteKey: 'android-key',
      iosRecaptchaEnterpriseSiteKey: 'ios-key',
    );

    expect(providers.providers, [
      isA<PlayIntegrityAppCheckProvider>(),
      isA<RecaptchaEnterpriseNativeAppCheckProvider>()
          .having((provider) => provider.siteKey, 'siteKey', 'android-key'),
    ]);
  });

  test('iOS adds native reCAPTCHA Enterprise after device attestation', () {
    initPlatform(Platform.ios(appId: 'ios-app', isOnline: true));

    final providers = FlutterAppCheckProviders(
      androidRecaptchaEnterpriseSiteKey: 'android-key',
      iosRecaptchaEnterpriseSiteKey: 'ios-key',
    );

    expect(providers.providers, [
      isA<AppAttestAppCheckProvider>(),
      isA<DeviceCheckAppCheckProvider>(),
      isA<RecaptchaEnterpriseNativeAppCheckProvider>()
          .having((provider) => provider.siteKey, 'siteKey', 'ios-key'),
    ]);
  });

  test('macOS does not use the iOS reCAPTCHA Enterprise key', () {
    initPlatform(Platform.macos(appId: 'mac-app', isOnline: true));

    final providers = FlutterAppCheckProviders(
      iosRecaptchaEnterpriseSiteKey: 'ios-key',
    );

    expect(
      providers.providers
          .whereType<RecaptchaEnterpriseNativeAppCheckProvider>(),
      isEmpty,
    );
  });
}
