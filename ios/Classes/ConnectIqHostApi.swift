//
//  FlutterConnectIqHostApi.swift
//  flutter_watch_garmin_connectiq
//
//  Created by Herbert Poul on 16.08.23.
//

import ConnectIQ
import Flutter
import Foundation
import os

/// name of the UserDefaults entry storing the last received device list.
private let cachedDevicesUrl = "com.austrianapps.flutter_watch_garmin_connectiq.gcmdevices"

private let logger = Logger(
  subsystem: "flutter_watch_garmin_connectiq",
  category: "ConnectiqHostAPi")

// This extension of Error is required to do use FlutterError in any Swift code.
extension FlutterError: Error {}

extension AppId {
  func toIQApp(device: IQDevice?) -> IQApp? {
    guard let appUuid = UUID(uuidString: applicationId) else {
      logger.warning("Invalid appId: \(String(describing: applicationId))")
      return nil
    }
    let storeUuid: UUID?
    if let storeId = storeId {
      storeUuid = UUID(uuidString: storeId)
    } else {
      storeUuid = nil
    }
    let app = IQApp(uuid: appUuid, store: storeUuid, device: device)
    return app
  }
}

class ConnectIqHostApiImpl: NSObject {
  var initOptions: InitOptions?
  private let flutterConnectIqApi: FlutterConnectIqApi
  private lazy var connectIQ: ConnectIQ = .sharedInstance()
  var devices: [UUID: IQDevice] = [:]
  var deviceStatus: [UUID: IQDeviceStatus] = [:]
  private let plugin: FlutterWatchGarminConnectIqPlugin
  
  init(flutterConnectIqApi: FlutterConnectIqApi, plugin: FlutterWatchGarminConnectIqPlugin) {
    self.flutterConnectIqApi = flutterConnectIqApi
    self.plugin = plugin
  }
  
  func openFromGCM(url: URL) {
    guard let devices = connectIQ.parseDeviceSelectionResponse(from: url)?.compactMap({ $0 as? IQDevice }) else {
      return
    }
    UserDefaults.standard.set(url, forKey: cachedDevicesUrl)
    self.devices = Dictionary(uniqueKeysWithValues: zip(devices.map { $0.uuid! }, devices))
    
    guard let initOptions = initOptions else {
      return
    }
    
    for device in devices {
      connectIQ.register(forDeviceEvents: device, delegate: self)
      for appId in initOptions.applicationIds {
        guard let app = appId?.toIQApp(device: device) else {
          continue
        }
        connectIQ.register(forAppMessages: app, delegate: self)
      }
    }
  }
}

extension IQDeviceStatus {
  func toPigeon() -> PigeonIqDeviceStatus {
    switch self {
    case .connected: return .connected
    case .bluetoothNotReady: return .unknown
    case .invalidDevice: return .unknown
    case .notFound: return .notPaired
    case .notConnected: return .notConnected
    @unknown default:
      logger.error("Invalid IQDeviceStatus? \(String(reflecting: self))")
      return .notConnected
    }
  }
}

extension IQDevice {
  func toPigeon(status: PigeonIqDeviceStatus) -> PigeonIqDevice {
    return PigeonIqDevice(deviceIdentifier: uuid.uuidString, friendlyName: friendlyName, status: status)
  }
}

extension IQSendMessageResult {
  func toPigeon() -> PigeonIqMessageStatus {
    switch self {
    case .success: return .success
    case .failure_AppAlreadyRunning: return .failureUnknown
    case .failure_AppNotFound: return .failureUnknown
    case .failure_Timeout: return .failureDuringTransfer
    case .failure_MaxRetries: return .failureDuringTransfer
    case .failure_Unknown: return .failureUnknown
    case .failure_InternalError:
      return .failureUnknown
    case .failure_DeviceNotAvailable:
      return .failureDeviceNotConnected
    case .failure_DeviceIsBusy:
      return .failureDeviceNotConnected
    case .failure_UnsupportedType:
      return .failureInvalidFormat
    case .failure_InsufficientMemory:
      return .failureUnknown
    case .failure_PromptNotDisplayed:
      return .failureUnknown
    @unknown default:
      return .failureUnknown
    }
  }
  
  func toOpenApplicationStatus() -> PigeonIqOpenApplicationStatus {
    switch self {
    case .success: return .promptShownOnDevice
    case .failure_Unknown: fallthrough
    case .failure_InternalError: fallthrough
    case .failure_DeviceNotAvailable: fallthrough
    case .failure_AppNotFound: fallthrough
    case .failure_DeviceIsBusy: fallthrough
    case .failure_UnsupportedType: fallthrough
    case .failure_InsufficientMemory: fallthrough
    case .failure_Timeout: fallthrough
    case .failure_MaxRetries: return .unknownFailure
    case .failure_PromptNotDisplayed: return .promptNotShownOnDevice
    case .failure_AppAlreadyRunning: return .appIsAlreadyRunning
    @unknown default:
      return .unknownFailure
    }
  }
}

extension ConnectIqHostApiImpl: ConnectIqHostApi {
  func initialize(initOptions: InitOptions, completion: @escaping (Result<InitResult, Error>) -> Void) {
    self.initOptions = initOptions
    connectIQ.initialize(withUrlScheme: initOptions.iosOptions.urlScheme, uiOverrideDelegate: self)
    if let cachedUrlString = UserDefaults.standard.string(forKey: cachedDevicesUrl),
       let cachedUrl = URL(string: cachedUrlString) {
      openFromGCM(url: cachedUrl)
    }
    logger.debug("Initialize done.")
    completion(.success(InitResult(status: InitStatus.success)))
  }
  
  private func _getKnownDevices() -> [PigeonIqDevice] {
    return devices.values.map {
      $0.toPigeon(status: deviceStatus[$0.uuid]?.toPigeon() ?? .unknown)
    }
  }

  func getKnownDevices(completion: @escaping (Result<[PigeonIqDevice], Error>) -> Void) {
    let knownDevices = _getKnownDevices()
    completion(.success(knownDevices))
  }
  
  func getConnectedDevices(completion: @escaping (Result<[PigeonIqDevice], Error>) -> Void) {
    let devices = _getKnownDevices().filter { $0.status == .connected }
    completion(.success(devices))
  }
  
  func withDevice<T>(deviceId: String, completion: (Result<T, Error>) -> Void, cb: @escaping (IQDevice) -> Void) -> Void {
    guard let uuid = UUID(uuidString: deviceId), let device = devices[uuid] else {
      completion(.failure(FlutterError(code: "InvalidDevice", message: "Invalid device \(deviceId)", details: nil)))
      return
    }
    cb(device)
  }
  
  func withDeviceAndApp<T>(deviceId: String, applicationId: String, completion: @escaping (Result<T, Error>) -> Void, cb: @escaping (IQDevice, IQApp) -> Void) -> Void {
    withDevice(deviceId: deviceId, completion: completion) { device in
      guard let uuid = UUID(uuidString: applicationId) else {
        completion(.failure(FlutterError(code: "InvalidApp", message: "Invalid app uuid: \(applicationId)", details: nil)))
        return
      }
      guard let app = IQApp(uuid: uuid, store: nil, device: device) else {
        completion(.failure(FlutterError(code: "InvalidApp", message: "Error creating app for: \(applicationId)", details: nil)))
        return
      }
      cb(device, app)
    }
  }
  
  func getApplicationInfo(deviceId: String, applicationId: String, completion: @escaping (Result<PigeonIqApp, Error>) -> Void) {
    withDeviceAndApp(deviceId: deviceId, applicationId: applicationId, completion: completion) { _, app in
      self.connectIQ.getAppStatus(app) { status in
        guard let status = status else {
          completion(.failure(FlutterError(code: "ErrorLoadingAppDetails", message: "unknown error", details: nil)))
          return
        }
        let pigeonApp = PigeonIqApp(applicationId: applicationId, status: .installed, displayName: "", version: Int64(status.version))
        completion(.success(pigeonApp))
      }
    }
  }
  
  func openApplication(deviceId: String, applicationId: String, completion: @escaping (Result<PigeonIqOpenApplicationResult, Error>) -> Void) {
    withDeviceAndApp(deviceId: deviceId, applicationId: applicationId, completion: completion) { _, app in
      self.connectIQ.openAppRequest(app) { status in
        logger.debug("openAppRequest response: \(String(reflecting: status))")
        completion(.success(PigeonIqOpenApplicationResult(status: status.toOpenApplicationStatus())))
      }
    }
  }
  
  func openStore(app: AppId, completion: @escaping (Result<Bool, Error>) -> Void) {
    connectIQ.showStore(for: app.toIQApp(device: nil))
    completion(.success(true))
  }
  
  func sendMessage(deviceId: String, applicationId: String, message: [String: Any], completion: @escaping (Result<PigeonIqMessageResult, Error>) -> Void) {
    withDeviceAndApp(deviceId: deviceId, applicationId: applicationId, completion: completion) { _, app in
      self.connectIQ.sendMessage(message, to: app, progress: nil) { result in
        let failureDetails = result == .success ? nil : "\(String(reflecting: result))"
        completion(.success(PigeonIqMessageResult(status: result.toPigeon(), failureDetails: failureDetails)))
      }
    }
  }
  
  func openStoreForGcm(completion: @escaping (Result<Void, Error>) -> Void) {
    connectIQ.showAppStoreForConnectMobile()
    completion(.success(()))
  }
  
  func iOsShowDeviceSelection(completion: @escaping (Result<Void, Error>) -> Void) {
    connectIQ.showDeviceSelection()
    completion(.success(()))
  }
}

extension ConnectIqHostApiImpl: IQUIOverrideDelegate {
  func needsToInstallConnectMobile() {
    logger.debug("Requesting GCM Install dialog.")
    flutterConnectIqApi.showGcmInstallDialog(requiresUpgrade: false) {
      logger.debug("GCM Install: Got reply from flutter side.")
    }
  }
}

extension ConnectIqHostApiImpl: IQDeviceEventDelegate {
  func deviceStatusChanged(_ device: IQDevice!, status: IQDeviceStatus) {
    deviceStatus[device.uuid] = status
    flutterConnectIqApi.onDeviceStatusChanged(device: device.toPigeon(status: status.toPigeon())) {}
  }
}

extension ConnectIqHostApiImpl: IQAppMessageDelegate {
  func receivedMessage(_ message: Any!, from app: IQApp!) {
    logger.debug("Received message. \(String(reflecting: message))")
  }
}
