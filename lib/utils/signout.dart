import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projects/login.dart';
import '../provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> signOut(BuildContext context) async {
  // Stop the background service
  final service = FlutterBackgroundService();
  service.invoke('stopService');

  // Clear secure storage
  final storage = FlutterSecureStorage();
  await storage.delete(key: 'token');

  // Clear shared preferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  // Clear user data
  Provider.of<UserProvider>(context, listen: false).clearUser();

  // Clear Patient data
  Provider.of<PatientProvider>(context, listen: false).clearPatients();

  // Clear Caretaker data
  Provider.of<CaretakerProvider>(context, listen: false).clearCaretakers();

  // Navigate to login page
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginPage()),
    (Route<dynamic> route) => false,
  );
}
