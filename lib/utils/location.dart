import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:projects/utils/globals.dart' as global;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class FileOutput extends LogOutput {
  final File logFile;

  FileOutput(this.logFile);

  @override
  void output(OutputEvent event) {
    final log = event.lines.join("\n");
    logFile.writeAsStringSync(log + "\n", mode: FileMode.append, flush: true);
  }
}

Future<Logger> createLogger() async {
  final directory = await getApplicationDocumentsDirectory();
  final logFile = File('${directory.path}/logs.txt');

  if (!logFile.existsSync()) {
    logFile.createSync(recursive: true);
  }

  return Logger(
    output: MultiOutput([
      ConsoleOutput(),
      FileOutput(logFile),
    ]),
  );
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  await service.startService();
}

bool onIosBackground(ServiceInstance service) {
  return true;
}

void onStart(ServiceInstance service) async {
  final logger = await createLogger();
  logger.d("background service started");
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Cognicare Location Service",
      content: "Updating location in the background",
    );
  }

  service.on('stopService').listen((event) {
    logger.d("Service stopped");
    service.stopSelf();
  });

  final storage = new FlutterSecureStorage();
  final token = await storage.read(key: 'token') ?? '';
  String baseURL = global.baseURL;
  String locationUpdateURL = '$baseURL/api/users/geofence/';

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    logger.d("5 Min - Update location");
    if (service is AndroidServiceInstance &&
        !(await service.isForegroundService())) {
      logger.d("Service is not in foreground, stopping timer");
      timer.cancel();
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      logger.d("Current position: ${position.latitude}, ${position.longitude}");
      logger.d('Token: $token');
      final response = await http.post(
        Uri.parse(locationUpdateURL),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token $token',
        },
        body: jsonEncode(<String, dynamic>{
          'current_lat': position.latitude,
          'current_long': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        logger.d("Location updated successfully");
        logger.d("Response: ${response.body}");
        final responseData = jsonDecode(response.body);
        if (responseData['is_outside_geofence']) {
          // playSound();
        }
      } else {
        logger.e("Failed to update location: ${response.statusCode}");
      }
    } catch (e) {
      logger.e("Error updating location: $e");
    }
  });
}

void playSound() {
  final player = AudioPlayer();
  player.play(AssetSource('sound/alert.mp3'));
}
