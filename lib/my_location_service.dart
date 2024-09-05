import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

const _durationLimit = Duration(milliseconds: 500);
const DISTANCE_UPDATE = 10;

class MyLocationService {
  MyLocationService();

  final geolocator = Geolocator();

  Future<bool> isLocationServiceAvailable() =>
      Geolocator.isLocationServiceEnabled();

  Future<void> openLocationService() => Geolocator.openLocationSettings();

  Future<bool> requestLocationPermission({
    VoidCallback? onSetting,
  }) async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      // Location services is disabled.
      return false;
    }

    var locationPermission = await Geolocator.requestPermission();
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever) {
      // Location permission has been permanently denied.
      return false;
    }

    // if (background == true) {
    //   final isAllowBackgroundLocation =
    //       await PermissionHandler.systemRequestPermission(
    //           Permission.locationAlways);
    //   if (!isAllowBackgroundLocation) {
    //     // Location permission must always be granted to collect location in the background.
    //     PermissionHandler.requestPermission(Permission.locationAlways);
    //     return false;
    //   }
    // }

    return true;
  }

  Future<void> onRequestRecordTrail() async {
    final value = await Geolocator.requestTemporaryFullAccuracy(
        purposeKey: 'recordTrail');
    print(value);
  }

  Future<Position> getMyCurrentPosition() async {
    // if (result) {
    try {
      final location = await Geolocator.getCurrentPosition(
          forceAndroidLocationManager: true);
      return location;
    } catch (e) {
      throw Exception('Location permissions are denied');
    }
    // return await Geolocator.getCurrentPosition(
    //     desiredAccuracy: LocationAccuracy.bestForNavigation);
    // } else {
    //   throw LocationDenied('Location permissions are denied');
    // }
  }

  Stream<Position> listenChangeOfPosition({bool isBackground = false}) {
    // return Geolocator.getLocationStream(
    //     interval: _durationLimit.inMilliseconds,
    //     distanceFilter: DISTANCE_UPDATE);
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: DISTANCE_UPDATE.toInt(),
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 1),
        //(Optional) Set foreground notification config to keep the app alive
        //when going to the background
        // foregroundNotificationConfig: const ForegroundNotificationConfig(
        //   notificationText:
        //       "Example app will continue to receive your location even when you aren't using it",
        //   notificationTitle: "Running in Background",
        //   enableWakeLock: true,
        // )
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: DISTANCE_UPDATE.toInt(),
        // pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: isBackground,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: DISTANCE_UPDATE.toInt(),
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
