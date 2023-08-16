import ConnectIQ
import Flutter
import os
import UIKit

private let logger = Logger(
  subsystem: "flutter_watch_garmin_connectiq",
  category: "FlutterWatchGarminConnectIqPlugin")

public class FlutterWatchGarminConnectIqPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    _ = FlutterWatchGarminConnectIqPlugin(registrar: registrar)
  }
  
  private let flutterConnectIqApi: FlutterConnectIqApi
  private lazy var connectIqHostApiImpl: ConnectIqHostApiImpl = .init(
    flutterConnectIqApi: flutterConnectIqApi,
    plugin: self)

  init(registrar: FlutterPluginRegistrar) {
    flutterConnectIqApi = FlutterConnectIqApi(binaryMessenger: registrar.messenger())
    super.init()
    ConnectIqHostApiSetup.setUp(
      binaryMessenger: registrar.messenger(),
      api: connectIqHostApiImpl)
    registrar.addApplicationDelegate(self)
  }
  
  public func applicationDidBecomeActive(_ application: UIApplication) {
    logger.debug("applicationDidBecomeActive")
  }
  
  public func applicationWillResignActive(_ application: UIApplication) {
    logger.debug("")
  }
  
  public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]) -> Bool {
    logger.debug("application willFinishLaunchingWithOptions: \(launchOptions)")
    return false
  }
  
  public func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
    logger.debug("handleOpen: \(url)")
    return false
  }
  
  private func handleOpenURL(_ url: URL) -> Bool {
    if let initOptions = connectIqHostApiImpl.initOptions {
      if url.scheme == initOptions.iosOptions.urlScheme {
        logger.debug("Got our url scheme. manage application list.")
        connectIqHostApiImpl.openFromGCM(url: url)
        return true
      }
    }
    return false
  }
  
  public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    logger.debug("application open URL: \(url) , options: \(options)")
    return handleOpenURL(url)
  }
  
  public func application(_ application: UIApplication, open url: URL, sourceApplication: String, annotation: Any) -> Bool {
    if sourceApplication == IQGCMBundle {
      logger.debug("Received from GCM")
      return handleOpenURL(url)
    }
    logger.debug("application open URL with annotation: \(url)")
    return false
  }
}
