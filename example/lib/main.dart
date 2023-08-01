import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_watch_garmin_connectiq/flutter_watch_garmin_connectiq.dart';

import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';

final _logger = Logger('main');

void main() {
  PrintAppender.setupLogging();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _connectIq = ConnectIqHostApi();
  bool _initialized = false;
  List<PigeonIqDevice>? devices;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    try {
      _logger.fine('Initializing...');
      final status = await _connectIq.initialize();
      _logger.fine('initialized sdk. $status');
      setState(() {
        _initialized = true;
      });
      final d = await _connectIq.getKnownDevices();
      setState(() {
        devices = d.map<PigeonIqDevice>((e) => e!).toList();
      });
    } catch (e) {
      _logger.severe('Error initialzing connectIq', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = this.devices;
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
            ...?(devices == null
                ? []
                : [
                    const SizedBox(height: 16),
                    Text('Devices: '),
                    ...devices.map(
                      (e) => ListTile(
                        title: Text(e.friendlyName),
                        subtitle: Text(e.deviceIdentifier.toString()),
                        trailing: Text(e.status.name),
                      ),
                    ),
                  ]),
          ],
        ),
      ),
    );
  }
}
