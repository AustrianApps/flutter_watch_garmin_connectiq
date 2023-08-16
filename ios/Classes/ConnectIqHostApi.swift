//
//  FlutterConnectIqHostApi.swift
//  flutter_watch_garmin_connectiq
//
//  Created by Herbert Poul on 16.08.23.
//

import Foundation
import Flutter
import ConnectIQ

// This extension of Error is required to do use FlutterError in any Swift code.
extension FlutterError: Error {}

class ConnectIqHostApiImpl: NSObject, ConnectIqHostApi {
  
  private let flutterConnectIqApi: FlutterConnectIqApi
  private lazy var connectIQ: ConnectIQ = ConnectIQ.sharedInstance()
  
  init(flutterConnectIqApi: FlutterConnectIqApi) {
    self.flutterConnectIqApi = flutterConnectIqApi
  }
  
  func initialize(initOptions: InitOptions, completion: @escaping (Result<InitResult, Error>) -> Void) {
    connectIQ = ConnectIQ.sharedInstance()
    connectIQ.initialize(withUrlScheme: initOptions.iosOptions.urlScheme, uiOverrideDelegate: self)
    completion(.success(InitResult(status: InitStatus.success)))
  }
  
  func getKnownDevices(completion: @escaping (Result<[PigeonIqDevice], Error>) -> Void) {
    
  }
  
  func getConnectedDevices(completion: @escaping (Result<[PigeonIqDevice], Error>) -> Void) {
    
  }
  
  func getApplicationInfo(deviceId: Int64, applicationId: String, completion: @escaping (Result<PigeonIqApp, Error>) -> Void) {
    
  }
  
  func openApplication(deviceId: Int64, applicationId: String, completion: @escaping (Result<PigeonIqOpenApplicationResult, Error>) -> Void) {
    
  }
  
  func openStore(storeId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
    
  }
  
  func sendMessage(deviceId: Int64, applicationId: String, message: [String : Any], completion: @escaping (Result<PigeonIqMessageResult, Error>) -> Void) {
    
  }
  
  func openStoreForGcm(completion: @escaping (Result<Void, Error>) -> Void) {
    
  }
  
  
}

extension ConnectIqHostApiImpl: IQUIOverrideDelegate {
  func needsToInstallConnectMobile() {
    flutterConnectIqApi.showGcmInstallDialog(requiresUpgrade: false) {
      
    }
  }
}
