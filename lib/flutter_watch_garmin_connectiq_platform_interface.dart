import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_watch_garmin_connectiq_method_channel.dart';

abstract class FlutterWatchGarminConnectIqPlatform extends PlatformInterface {
  /// Constructs a FlutterWatchGarminConnectIqPlatform.
  FlutterWatchGarminConnectIqPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterWatchGarminConnectIqPlatform _instance = MethodChannelFlutterWatchGarminConnectIq();

  /// The default instance of [FlutterWatchGarminConnectIqPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterWatchGarminConnectIq].
  static FlutterWatchGarminConnectIqPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterWatchGarminConnectIqPlatform] when
  /// they register themselves.
  static set instance(FlutterWatchGarminConnectIqPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
