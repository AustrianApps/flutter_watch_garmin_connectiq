import Flutter
import UIKit
import os
import ConnectIQ

private let logger = Logger(
  subsystem: "flutter_watch_garmin_connectiq",
  category: "FlutterWatchGarminConnectIqPlugin")

public class FlutterWatchGarminConnectIqPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    _ = FlutterWatchGarminConnectIqPlugin(registrar: registrar)
  }
  
  private let flutterConnectIqApi: FlutterConnectIqApi
  private let connectIqHostApiImpl: ConnectIqHostApiImpl

  init(registrar: FlutterPluginRegistrar) {
    flutterConnectIqApi = FlutterConnectIqApi(binaryMessenger: registrar.messenger())
    connectIqHostApiImpl = ConnectIqHostApiImpl(flutterConnectIqApi: flutterConnectIqApi)
    ConnectIqHostApiSetup.setUp(
      binaryMessenger: registrar.messenger(),
      api: connectIqHostApiImpl)
    super.init()
    registrar.addApplicationDelegate(self)
  }
  
  public func application(_ application: UIApplication, open url: URL, sourceApplication: String, annotation: Any) -> Bool {
    if let initOptions = connectIqHostApiImpl.initOptions {
      if (url.scheme == initOptions.iosOptions.urlScheme) {
        logger.debug("Got our url scheme. manage application list.")
        if (sourceApplication == IQGCMBundle) {
          logger.debug("Received from GCM")
          connectIqHostApiImpl.openFromGCM(url: url)
        }
      }
    }
    return false
  }
}
