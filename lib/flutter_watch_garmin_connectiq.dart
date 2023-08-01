import 'flutter_watch_garmin_connectiq_platform_interface.dart';

export 'src/gen/messages.g.dart';

class FlutterWatchGarminConnectIq {
  Future<String?> getPlatformVersion() {
    return FlutterWatchGarminConnectIqPlatform.instance.getPlatformVersion();
  }
}
