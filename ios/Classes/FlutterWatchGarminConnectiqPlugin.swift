import Flutter
import UIKit

public class FlutterWatchGarminConnectIqPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let flutterConnectIqApi = FlutterConnectIqApi(binaryMessenger: registrar.messenger())
    ConnectIqHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: ConnectIqHostApiImpl(flutterConnectIqApi: flutterConnectIqApi))
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
