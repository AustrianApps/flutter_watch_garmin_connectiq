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

  FlutterWatchGarminConnectIq._(this.hostApi, List<String> applicationIds)
      : _applications =
            ValueNotifier({for (final e in applicationIds) e: null}) {
    FlutterConnectIqApi.setup(_FlutterConnectIqApiImpl(this));
    (() async {
      _knownDevices.value = List.unmodifiable(
          (await hostApi.getKnownDevices()).map((e) => e as PigeonIqDevice));
    })();
  }

  static Future<FlutterWatchGarminConnectIq> initialize(
      InitOptions initOptions) async {
    final hostApi = ConnectIqHostApi();
    final initialized = await hostApi.initialize(initOptions);
    if (!initialized) {
      throw StateError('Unable to initialize.');
    }
    return FlutterWatchGarminConnectIq._(
        hostApi, initOptions.applicationIds.map((e) => e!).toList());
  }

  Future<ValueListenable<List<PigeonIqDevice>>> getKnownDevices() async =>
      _knownDevices;

  Future<PigeonIqMessageResult> sendMessage(
      int deviceId, String applicationId, Map<String, Object> message) async {
    return await hostApi.sendMessage(deviceId, applicationId, message);
  }

  Future<PigeonIqOpenApplicationResult> openApplication(
          int deviceId, String applicationId) =>
      hostApi.openApplication(deviceId, applicationId);
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
