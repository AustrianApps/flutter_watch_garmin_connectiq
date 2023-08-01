import 'flutter_watch_garmin_connectiq_platform_interface.dart';

class FlutterWatchGarminConnectIq {
  Future<String?> getPlatformVersion() {
    return FlutterWatchGarminConnectIqPlatform.instance.getPlatformVersion();
  }
}
