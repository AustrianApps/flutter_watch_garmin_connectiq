import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_watch_garmin_connectiq/flutter_watch_garmin_connectiq.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';

final _logger = Logger('main');

void main() {
  PrintAppender.setupLogging();
  runApp(const MyApp());
}

class MyApp extends StatefulHookWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

final _applicationId =
    AppId(applicationId: 'd7671b9b-1041-4c2c-925d-bab5e50302c3');
// const _applicationId = 'D7671B9B10414C2C925DBAB5E50302C3';

class _MyAppState extends State<MyApp> {
  late FlutterWatchGarminConnectIq _connectIq;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();
  bool _initialized = false;
  ValueListenable<List<PigeonIqDevice>> devices =
      ValueNotifier(<PigeonIqDevice>[]);

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    try {
      _logger.fine('Initializing...');
      _connectIq = await FlutterWatchGarminConnectIq.initialize(
          InitOptions(
            applicationIds: [_applicationId],
            iosOptions:
                InitIosOptions(urlScheme: 'flutter-connectiq-example-382'),
            androidOptions:
                InitAndroidOptions(connectType: ConnectType.wireless),
          ), showGcmInstallDialog: (requireUpgrade) {
        _logger.info('Showing GCM Install Dialog.');
        final navContext = _navigatorKey.currentContext;
        if (navContext == null) {
          _logger.severe('Navigation context is not (yet)? defined.');
          return;
        }
        showDialog(
            context: navContext,
            builder: (context) {
              return AlertDialog(
                title: Text('Requires GCM'),
                content: Text('Garmin Connect Mobile required.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      FlutterWatchGarminConnectIq.openStoreForGcm();
                      Navigator.of(context).pop();
                    },
                    child: Text("Install"),
                  ),
                ],
              );
            });
      });
      _logger.fine('initialized connectiq sdk');
      setState(() {
        _initialized = true;
      });
      setState(() {
        devices = _connectIq.getKnownDevices();
      });
    } catch (e) {
      _logger.severe('Error initializing connectIq', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = useValueListenable(this.devices);
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ConnectIQ example app'),
        ),
        body: Column(
          children: [
            ListTile(
              title: Text('Initialized: $_initialized'),
            ),
            ...(devices.isEmpty
                ? (Platform.isIOS
                    ? [
                        ElevatedButton(
                          onPressed: () {
                            _connectIq.iOsShowDeviceSelection();
                          },
                          child: Text('Show Device Selection'),
                        ),
                      ]
                    : [])
                : [
                    const SizedBox(height: 16),
                    const Text('Devices: '),
                    ...devices.expand(
                      (e) => [
                        ListTile(
                          title: Text(e.friendlyName),
                          subtitle: Text(e.deviceIdentifier.toString()),
                          trailing: Text(e.status.name),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final result = await _connectIq.openApplication(
                                    e.deviceIdentifier,
                                    _applicationId.applicationId);
                                _logger.fine('result: ${result.status}');
                              },
                              child: Text('Open App'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await _connectIq.sendMessage(
                                  e.deviceIdentifier,
                                  _applicationId.applicationId,
                                  {'echo': 'Hello World!'},
                                );
                                _logger
                                    .fine('Message result: ${result.status}');
                              },
                              child: Text('Send Message'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ]),
          ],
        ),
      ),
    );
  }
}
