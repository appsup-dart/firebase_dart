import DeviceCheck
import FlutterMacOS

public class FirebaseDartFlutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "firebase_dart_flutter",
      binaryMessenger: registrar.messenger)
    let instance = FirebaseDartFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isDeviceCheckSupported":
      if #available(macOS 10.15, *) {
        result(DCDevice.current.isSupported)
      } else {
        result(false)
      }
    case "generateDeviceCheckToken":
      guard #available(macOS 10.15, *) else {
        result(FlutterError(
          code: "unavailable",
          message: "Device Check requires macOS 10.15 or newer.",
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
    case "isAppAttestSupported":
      if #available(macOS 11.0, *) {
        result(DCAppAttestService.shared.isSupported)
      } else {
        result(false)
      }
    case "generateAppAttestKey":
      guard #available(macOS 11.0, *) else {
        result(FlutterError(
          code: "unavailable",
          message: "App Attest requires macOS 11.0 or newer.",
          details: nil))
        return
      }
      DCAppAttestService.shared.generateKey { keyId, error in
        if let error = error {
          result(FlutterError(
            code: "app_attest",
            message: error.localizedDescription,
            details: nil))
          return
        }
        guard let keyId = keyId else {
          result(FlutterError(
            code: "app_attest",
            message: "Empty App Attest key id.",
            details: nil))
          return
        }
        result(keyId)
      }
    case "attestAppAttestKey":
      guard #available(macOS 11.0, *) else {
        result(FlutterError(
          code: "unavailable",
          message: "App Attest requires macOS 11.0 or newer.",
          details: nil))
        return
      }
      guard let args = call.arguments as? [String: Any],
            let keyId = args["keyId"] as? String,
            let hashList = args["clientDataHash"] as? FlutterStandardTypedData else {
        result(FlutterError(
          code: "invalid_argument",
          message: "attestAppAttestKey requires keyId and clientDataHash.",
          details: nil))
        return
      }
      DCAppAttestService.shared.attestKey(keyId, clientDataHash: hashList.data) {
        attestation, error in
        if let error = error {
          result(FlutterError(
            code: "app_attest",
            message: error.localizedDescription,
            details: nil))
          return
        }
        guard let attestation = attestation else {
          result(FlutterError(
            code: "app_attest",
            message: "Empty App Attest attestation.",
            details: nil))
          return
        }
        result(FlutterStandardTypedData(bytes: attestation))
      }
    case "generateAppAttestAssertion":
      guard #available(macOS 11.0, *) else {
        result(FlutterError(
          code: "unavailable",
          message: "App Attest requires macOS 11.0 or newer.",
          details: nil))
        return
      }
      guard let args = call.arguments as? [String: Any],
            let keyId = args["keyId"] as? String,
            let hashList = args["clientDataHash"] as? FlutterStandardTypedData else {
        result(FlutterError(
          code: "invalid_argument",
          message: "generateAppAttestAssertion requires keyId and clientDataHash.",
          details: nil))
        return
      }
      DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: hashList.data) {
        assertion, error in
        if let error = error {
          result(FlutterError(
            code: "app_attest",
            message: error.localizedDescription,
            details: nil))
          return
        }
        guard let assertion = assertion else {
          result(FlutterError(
            code: "app_attest",
            message: "Empty App Attest assertion.",
            details: nil))
          return
        }
        result(FlutterStandardTypedData(bytes: assertion))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
