import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

Future<Position> getCurrentPosition() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Location permissions are permanently denied');
  }
  return await Geolocator.getCurrentPosition();
}

Future<void> handleLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    bool opened = await openAppSettings();
    if (!opened) {
      return Future.error('Could not open app settings');
    }
    return Future.error('Location permissions are permanently denied');
  }

  if (permission != LocationPermission.always) {
    bool opened = await openAppSettings();
    if (!opened) {
      return Future.error('Could not open app settings');
    }
    return Future.error('Location permissions are not granted');
  }
}
