import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_watch_garmin_connectiq_platform_interface.dart';

/// An implementation of [FlutterWatchGarminConnectIqPlatform] that uses method channels.
class MethodChannelFlutterWatchGarminConnectIq
    extends FlutterWatchGarminConnectIqPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_watch_garmin_connectiq');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
