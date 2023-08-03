import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_watch_garmin_connectiq/src/gen/messages.g.dart';

import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

final _logger = Logger('connectiq');

class FlutterWatchGarminConnectIq implements FlutterConnectIqApi {
  final ConnectIqHostApi hostApi;
  final ValueNotifier<List<PigeonIqDevice>> _knownDevices = ValueNotifier([]);
  final ValueNotifier<Map<String, PigeonIqApp?>> _applications;

  FlutterWatchGarminConnectIq._(this.hostApi, List<String> applicationIds)
      : _applications =
            ValueNotifier({for (final e in applicationIds) e: null}) {
    FlutterConnectIqApi.setup(this);
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

  @override
  void onDeviceStatusChanged(PigeonIqDevice device) {
    _logger.finer(
        'onDeviceStatusChanged(${device.friendlyName}, ${device.status})');
    final devices = _knownDevices;
    if (devices != null) {
      final v = devices.value;
      devices.value = List.unmodifiable(v.map(
          (e) => e.deviceIdentifier == device.deviceIdentifier ? device : e));
    }
  }

  @override
  void onMessageReceived(
      PigeonIqDevice device, PigeonIqApp app, Object message) {
    _logger.finer(
        'onMessageReceived(${device.friendlyName}, ${app.displayName}, $message');
  }

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
