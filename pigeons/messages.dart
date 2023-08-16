import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/gen/messages.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/src/main/kotlin/com/austrianapps/flutter_watch_garmin_connectiq/Messages.g.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.austrianapps.flutter_watch_garmin_connectiq',
  ),
  // javaOut: 'android/app/src/main/java/io/flutter/plugins/Messages.java',
  // javaOptions: JavaOptions(),
  swiftOut: 'ios/Classes/Messages.g.swift',
  swiftOptions: SwiftOptions(),
  // objcHeaderOut: 'macos/Runner/messages.g.h',
  // objcSourceOut: 'macos/Runner/messages.g.m',
  // // Set this to a unique prefix for your plugin or application, per Objective-C naming conventions.
  // objcOptions: ObjcOptions(prefix: 'PGN'),
  // copyrightHeader: 'pigeons/copyright.txt',
  dartPackageName: 'flutter_watch_garmin_connectiq',
))
//
class PigeonIqDevice {
  PigeonIqDevice({
    required this.deviceIdentifier,
    required this.friendlyName,
    required this.status,
  });

  String deviceIdentifier;
  String friendlyName;
  PigeonIqDeviceStatus status;
}

enum PigeonIqDeviceStatus {
  notPaired,
  notConnected,
  connected,
  unknown,
}

enum PigeonIqAppStatus {
  unknown,
  installed,
  notInstalled,
  notSupported,
}

class PigeonIqApp {
  PigeonIqApp({
    required this.applicationId,
    required this.status,
    required this.displayName,
    required this.version,
  });

  final String applicationId;
  final PigeonIqAppStatus status;
  final String displayName;
  final int version;
}

class PigeonIqOpenApplicationResult {
  PigeonIqOpenApplicationResult({required this.status});

  final PigeonIqOpenApplicationStatus status;
}

enum PigeonIqOpenApplicationStatus {
  promptShownOnDevice,
  promptNotShownOnDevice,
  appIsNotInstalled,
  appIsAlreadyRunning,
  unknownFailure,
}

enum PigeonIqMessageStatus {
  success,
  failureUnknown,
  failureInvalidFormat,
  failureMessageTooLarge,
  failureUnsupportedType,
  failureDuringTransfer,
  failureInvalidDevice,
  failureDeviceNotConnected,
}

class PigeonIqMessageResult {
  PigeonIqMessageResult({required this.status, this.failureDetails});

  PigeonIqMessageStatus status;
  String? failureDetails;
}

class InitAndroidOptions {
  const InitAndroidOptions({required this.connectType, this.adbPort});

  final ConnectType connectType;
  final int? adbPort;
}

class InitIosOptions {
  const InitIosOptions({this.urlScheme = ''});

  final String urlScheme;
}

class AppId {
  const AppId({required this.applicationId, this.storeId});
  final String applicationId;
  final String? storeId;
}

class InitOptions {
  const InitOptions({
    required this.applicationIds,
    this.iosOptions = const InitIosOptions(),
    this.androidOptions =
        const InitAndroidOptions(connectType: ConnectType.wireless),
  });

  final List<AppId?> applicationIds;
  final InitIosOptions iosOptions;
  final InitAndroidOptions androidOptions;
}

enum ConnectType {
  wireless,
  adb,
}

enum InitStatus {
  success,
  errorGcmNotInstalled,
  errorGcmUpgradeNeeded,
  errorServiceError,
}

class InitResult {
  InitResult({
    required this.status,
  });
  final InitStatus status;
}

@HostApi()
abstract class ConnectIqHostApi {
  @async
  InitResult initialize(InitOptions initOptions);

  @async
  List<PigeonIqDevice> getKnownDevices();

  @async
  List<PigeonIqDevice> getConnectedDevices();

  @async
  PigeonIqApp getApplicationInfo(
    String deviceId,
    String applicationId,
  );

  @async
  PigeonIqOpenApplicationResult openApplication(
    String deviceId,
    String applicationId,
  );

  @async
  bool openStore(AppId app);

  @async
  PigeonIqMessageResult sendMessage(
    String deviceId,
    String applicationId,
    Map<String, Object> message,
  );

  @async
  void openStoreForGcm();

  @async
  void iOsShowDeviceSelection();
}

@FlutterApi()
abstract class FlutterConnectIqApi {
  void onDeviceStatusChanged(
    PigeonIqDevice device,
  );
  void onMessageReceived(
    PigeonIqDevice device,
    PigeonIqApp app,
    Object message,
  );
  void showGcmInstallDialog(bool requiresUpgrade);
}
