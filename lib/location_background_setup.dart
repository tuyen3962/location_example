import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:location_example/location_background_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationBackgroundSetup {
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final result = await FlutterForegroundTask.isIgnoringBatteryOptimizations;

      if (!result) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        final newResult =
            await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        if (!newResult) {
          await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
        }
        return false;
      }
      // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
      final NotificationPermission notificationPermissionStatus =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermissionStatus != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
      return true;
    }

    return true;
  }

  static Future<void> initService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Recording your trail',
        channelDescription:
            'This notification appear when you are recording your trail.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.once(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static void onSendDataToService(Object data) async {
    FlutterForegroundTask.sendDataToTask(data);
  }

  static Future<ServiceRequestResult> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 25,
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        notificationIcon: null,
        // notificationButtons: [
        //   const NotificationButton(id: 'btn_hello', text: 'hello'),
        // ],
        callback: startCallback,
      );
    }
  }

  static Future<ServiceRequestResult> stopService() async {
    return FlutterForegroundTask.stopService();
  }
}
