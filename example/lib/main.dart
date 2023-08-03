import 'dart:async';

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

const _applicationId = 'd7671b9b-1041-4c2c-925d-bab5e50302c3';
// const _applicationId = 'D7671B9B10414C2C925DBAB5E50302C3';

class _MyAppState extends State<MyApp> {
  late final FlutterWatchGarminConnectIq _connectIq;
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
          iosOptions: InitIosOptions(urlScheme: ''),
          androidOptions: InitAndroidOptions(connectType: ConnectType.adb),
        ),
      );
      _logger.fine('initialized connectiq sdk');
      setState(() {
        _initialized = true;
      });
      final d = await _connectIq.getKnownDevices();
      setState(() {
        devices = d;
      });
    } catch (e) {
      _logger.severe('Error initializing connectIq', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = useValueListenable(this.devices);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ConnectIQ example app'),
        ),
        body: Column(
          children: [
            ListTile(
              title: Text('Initialized: $_initialized'),
            ),
            ...?(devices.isEmpty
                ? null
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
                                    e.deviceIdentifier, _applicationId);
                                _logger.fine('result: ${result.status}');
                              },
                              child: Text('Open App'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await _connectIq.sendMessage(
                                  e.deviceIdentifier,
                                  _applicationId,
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
