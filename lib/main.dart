import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_example/location_background_setup.dart';
import 'package:location_example/my_location_service.dart';

void main() {
  FlutterForegroundTask.initCommunicationPort();
  LocationBackgroundSetup.initService();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final ValueNotifier<Position> position = ValueNotifier(Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0));
  final myLocationService = MyLocationService();
  var hasStart = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
    onInit();
  }

  void onInit() async {
    await LocationBackgroundSetup.requestPermissions();
    await myLocationService.requestLocationPermission();
    position.value = await myLocationService.getMyCurrentPosition();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!hasStart && state == AppLifecycleState.hidden) {
      hasStart = true;
      LocationBackgroundSetup.startService();
    } else if (hasStart && state == AppLifecycleState.resumed) {
      hasStart = false;
      LocationBackgroundSetup.stopService();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  void _onReceiveTaskData(dynamic data) {
    log('_onReceiveTaskData background location $data');
    if (data is Map<String, dynamic>) {
      try {
        final model = Position.fromMap(data);
        position.value = model;
      } catch (e) {
        log('error map json');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: position,
          builder: (context, value, child) =>
              Text('${value.latitude} ${value.longitude}'),
        ),
      ),
    );
  }
}
