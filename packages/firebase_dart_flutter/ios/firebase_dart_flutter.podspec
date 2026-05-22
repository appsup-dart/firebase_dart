#
# iOS Device Check (and shared MethodChannel) for firebase_dart_flutter.
#
Pod::Spec.new do |s|
  s.name             = 'firebase_dart_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Firebase Dart Flutter iOS plugin'
  s.description      = 'Device Check App Check and shared platform channel on iOS.'
  s.homepage         = 'https://github.com/appsup-dart/firebase_dart'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'rbellens' => 'https://github.com/rbellens' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
  s.frameworks = 'DeviceCheck'
end
