import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_watch_garmin_connectiq/flutter_watch_garmin_connectiq.dart';
import 'package:flutter_watch_garmin_connectiq/flutter_watch_garmin_connectiq_platform_interface.dart';
import 'package:flutter_watch_garmin_connectiq/flutter_watch_garmin_connectiq_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterWatchGarminConnectiqPlatform
    with MockPlatformInterfaceMixin
    implements FlutterWatchGarminConnectiqPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterWatchGarminConnectiqPlatform initialPlatform = FlutterWatchGarminConnectiqPlatform.instance;

  test('$MethodChannelFlutterWatchGarminConnectiq is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterWatchGarminConnectiq>());
  });

  test('getPlatformVersion', () async {
    FlutterWatchGarminConnectiq flutterWatchGarminConnectiqPlugin = FlutterWatchGarminConnectiq();
    MockFlutterWatchGarminConnectiqPlatform fakePlatform = MockFlutterWatchGarminConnectiqPlatform();
    FlutterWatchGarminConnectiqPlatform.instance = fakePlatform;

    expect(await flutterWatchGarminConnectiqPlugin.getPlatformVersion(), '42');
  });
}
