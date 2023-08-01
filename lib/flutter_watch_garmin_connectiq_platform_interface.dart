import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_watch_garmin_connectiq_method_channel.dart';

abstract class FlutterWatchGarminConnectiqPlatform extends PlatformInterface {
  /// Constructs a FlutterWatchGarminConnectiqPlatform.
  FlutterWatchGarminConnectiqPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterWatchGarminConnectiqPlatform _instance = MethodChannelFlutterWatchGarminConnectiq();

  /// The default instance of [FlutterWatchGarminConnectiqPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterWatchGarminConnectiq].
  static FlutterWatchGarminConnectiqPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterWatchGarminConnectiqPlatform] when
  /// they register themselves.
  static set instance(FlutterWatchGarminConnectiqPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
