//
//  DtoExtensionHelpers.swift
//  flutter_watch_garmin_connectiq
//
//  Created by Herbert Poul on 22.08.23.
//

import ConnectIQ
import Foundation
import os

private let logger = Logger(
  subsystem: "flutter_watch_garmin_connectiq",
  category: "ConnectiqHostAPi")

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

extension IQApp {
  func toPigeon() -> PigeonIqApp {
    return PigeonIqApp(applicationId: uuid.uuidString, status: .installed, displayName: "", version: Int64(0))
  }
}

extension IQAppStatus {
  func toPigeon() -> PigeonIqAppStatus {
    if (isInstalled) {
      return .installed
    } else {
      return .notInstalled
    }
  }
}
