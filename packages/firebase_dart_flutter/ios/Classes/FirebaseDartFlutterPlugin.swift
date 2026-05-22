import DeviceCheck
import Flutter

public class FirebaseDartFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "firebase_dart_flutter",
      binaryMessenger: registrar.messenger())
    let instance = FirebaseDartFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isDeviceCheckSupported":
      if #available(iOS 11.0, *) {
        result(DCDevice.current.isSupported)
      } else {
        result(false)
      }
    case "generateDeviceCheckToken":
      guard #available(iOS 11.0, *) else {
        result(FlutterError(
          code: "unavailable",
          message: "Device Check requires iOS 11.0 or newer.",
          details: nil))
        return
      }
      DCDevice.current.generateToken { token, error in
        if let error = error {
          result(FlutterError(
            code: "device_check",
            message: error.localizedDescription,
            details: nil))
          return
        }
        guard let token = token else {
          result(FlutterError(
            code: "device_check",
            message: "Empty Device Check token.",
            details: nil))
          return
        }
        result(FlutterStandardTypedData(bytes: token))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
