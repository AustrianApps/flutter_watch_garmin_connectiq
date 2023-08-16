import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_watch_garmin_connectiq/src/gen/messages.g.dart';
import 'package:logging/logging.dart';

final _logger = Logger('connectiq');

class FlutterWatchGarminConnectIq {
  final ConnectIqHostApi hostApi;
  final ValueNotifier<List<PigeonIqDevice>> _knownDevices = ValueNotifier([]);
  final ValueNotifier<Map<String, PigeonIqApp?>> _applications;
  late final _messageReceivedController =
      StreamController<ConnectIqMessage>.broadcast();
  late final messageReceived = _messageReceivedController.stream;
  final void Function(bool requiresUpgrade) showGcmInstallDialogCb;

  FlutterWatchGarminConnectIq._(
    this.hostApi,
    List<AppId> applicationIds, {
    required this.showGcmInstallDialogCb,
  }) : _applications = ValueNotifier(
            {for (final e in applicationIds) e.applicationId: null}) {
    FlutterConnectIqApi.setup(_FlutterConnectIqApiImpl(this));
    (() async {
      _knownDevices.value = List.unmodifiable(
          (await hostApi.getKnownDevices()).map((e) => e as PigeonIqDevice));
    })();
  }

  static Future<void> openStoreForGcm() async {
    ConnectIqHostApi().openStoreForGcm();
  }

  static Future<FlutterWatchGarminConnectIq> initialize(
    InitOptions initOptions, {
    required void Function(bool requiresUpgrade) showGcmInstallDialog,
  }) async {
    final hostApi = ConnectIqHostApi();
    final initialized = await hostApi.initialize(initOptions);
    switch (initialized.status) {
      case InitStatus.success:
        return FlutterWatchGarminConnectIq._(
          hostApi,
          initOptions.applicationIds.map((e) => e!).toList(),
          showGcmInstallDialogCb: showGcmInstallDialog,
        );
      case InitStatus.errorGcmNotInstalled:
      case InitStatus.errorGcmUpgradeNeeded:
        showGcmInstallDialog(
            initialized.status == InitStatus.errorGcmUpgradeNeeded);
        throw StateError('GCM Missing');
      case InitStatus.errorServiceError:
        throw StateError('Unable to initialize.');
    }
  }

  ValueListenable<List<PigeonIqDevice>> getKnownDevices() => _knownDevices;

  Future<PigeonIqMessageResult> sendMessage(String deviceId,
      String applicationId, Map<String, Object> message) async {
    return await hostApi.sendMessage(deviceId, applicationId, message);
  }

  Future<PigeonIqOpenApplicationResult> openApplication(
          String deviceId, String applicationId) =>
      hostApi.openApplication(deviceId, applicationId);

  Future<void> iOsShowDeviceSelection() async {
    await hostApi.iOsShowDeviceSelection();
  }
}

// extension on PigeonIqDevice {
//   PigeonIqDevice copyWithStatus(PigeonIqDeviceStatus status) => PigeonIqDevice(
//         deviceIdentifier: deviceIdentifier,
//         friendlyName: friendlyName,
//         status: status,
//       );
// }

class _FlutterConnectIqApiImpl implements FlutterConnectIqApi {
  final FlutterWatchGarminConnectIq _connectIq;

  _FlutterConnectIqApiImpl(this._connectIq);

  @override
  void onDeviceStatusChanged(PigeonIqDevice device) {
    _logger.finer(
        'onDeviceStatusChanged(${device.friendlyName}, ${device.status})');
    final devices = _connectIq._knownDevices;
    final v = devices.value;
    devices.value = List.unmodifiable(v.map(
        (e) => e.deviceIdentifier == device.deviceIdentifier ? device : e));
  }

  @override
  void onMessageReceived(
      PigeonIqDevice device, PigeonIqApp app, Object message) {
    _logger.finer(
        'onMessageReceived(${device.friendlyName}, ${app.displayName}, $message');
    _connectIq._messageReceivedController.add(ConnectIqMessage._(
      device: device,
      app: app,
      data: message,
    ));
  }

  @override
  void showGcmInstallDialog(bool requiresUpgrade) {
    _connectIq.showGcmInstallDialogCb(requiresUpgrade);
  }
}

class ConnectIqMessage {
  ConnectIqMessage._({
    required this.device,
    required this.app,
    required this.data,
  });
  final PigeonIqDevice device;
  final PigeonIqApp app;
  final Object data;
}
