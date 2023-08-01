
import 'flutter_watch_garmin_connectiq_platform_interface.dart';

class FlutterWatchGarminConnectiq {
  Future<String?> getPlatformVersion() {
    return FlutterWatchGarminConnectiqPlatform.instance.getPlatformVersion();
  }
}
