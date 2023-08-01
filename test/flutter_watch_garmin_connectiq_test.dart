import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_watch_garmin_connectiq/flutter_watch_garmin_connectiq.dart';
import 'package:flutter_watch_garmin_connectiq/flutter_watch_garmin_connectiq_platform_interface.dart';
import 'package:flutter_watch_garmin_connectiq/flutter_watch_garmin_connectiq_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterWatchGarminConnectIqPlatform
    with MockPlatformInterfaceMixin
    implements FlutterWatchGarminConnectIqPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterWatchGarminConnectIqPlatform initialPlatform = FlutterWatchGarminConnectIqPlatform.instance;

  test('$MethodChannelFlutterWatchGarminConnectIq is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterWatchGarminConnectIq>());
  });

  test('getPlatformVersion', () async {
    FlutterWatchGarminConnectIq flutterWatchGarminConnectIqPlugin = FlutterWatchGarminConnectIq();
    MockFlutterWatchGarminConnectIqPlatform fakePlatform = MockFlutterWatchGarminConnectIqPlatform();
    FlutterWatchGarminConnectIqPlatform.instance = fakePlatform;

    expect(await flutterWatchGarminConnectIqPlugin.getPlatformVersion(), '42');
  });
}
