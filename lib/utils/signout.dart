import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projects/login.dart';
import '../provider/UserProvider.dart';
import 'package:provider/provider.dart';

Future<void> signOut(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
Provider.of<UserProvider>(context, listen: false).clearUser();

  // Clear Patient data
  Provider.of<PatientProvider>(context, listen: false).clearPatients();

  // Clear Caretaker data
  Provider.of<CaretakerProvider>(context, listen: false).clearCaretakers();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginPage()),
    (Route<dynamic> route) => false,
  );
}
