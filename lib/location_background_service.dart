// The callback function should always be a top-level function.
import 'dart:async';
import 'dart:developer';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_example/my_location_service.dart';

class LocationTaskHandler extends TaskHandler {
  final myLocationService = MyLocationService();
  late StreamSubscription<Position>? _locationSub = null;
  Timer? timer;
  // Called when the task is started.

  int duration = 1;
  @override
  void onStart(DateTime timestamp) async {
    log('[][][][[]]] on start background service');

    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      duration += 1;
      log('[][][][][][] update duration $duration');
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {}

  // Called when the task is destroyed.
  @override
  void onDestroy(DateTime timestamp) {
    log('onDestroy background location service');
    if (_locationSub != null) {
      _locationSub?.cancel();
    }
    if (timer != null) {
      timer?.cancel();
    }
  }

  // Called when data is sent using [FlutterForegroundTask.sendDataToTask].
  @override
  void onReceiveData(Object data) async {
    log('onReceiveData: $data');
    if (data is Map) {
      log('receive data in background: $data');
      try {
        // final stream = myLocationService.listenChangeOfPosition();
        _locationSub = myLocationService
            .listenChangeOfPosition(isBackground: true)
            .listen((position) => onHandleNewPosition(position));
        log('run success');
      } catch (e) {
        print(e);
        log('run fail $e');
      }
    }
  }

  Future<void> onHandleNewPosition(Position position) async {
    /// Update new position
    print('new position ${position.toJson()}');
    FlutterForegroundTask.sendDataToMain(position.toJson());
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed: $id');
  }

  // Called when the notification itself on the Android platform is pressed.
  //
  // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // this function to be called.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
    print('onNotificationPressed');
  }

  // Called when the notification itself on the Android platform is dismissed
  // on Android 14 which allow this behaviour.
  @override
  void onNotificationDismissed() {
    print('onNotificationDismissed');
  }
}
