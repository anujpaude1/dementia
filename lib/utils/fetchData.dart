import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projects/utils/globals.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/provider/UserProvider.dart';
import 'package:projects/model/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<bool> fetchData(BuildContext context) async {
  final storage = new FlutterSecureStorage();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  final username = prefs.getString('username') ?? '';
  final token = await storage.read(key: 'token') ?? '';
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final isCaretaker = prefs.getBool('isCaretaker') ?? false;

  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final user = userProvider.user;
  // Function body starts here
  final baseURL = globals.baseURL;
  final String dataURL = '$baseURL/api/users/patient/';
  final String caretakerDataURL = '$baseURL/api/users/caretaker/';

  if (isCaretaker) {
    final caretakerResponse = await http.get(
      Uri.parse(caretakerDataURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token ${token}',
      },
    );

    if (caretakerResponse.statusCode == 200) {
      final caretakerData = jsonDecode(caretakerResponse.body);
      print(caretakerData);

      if (context.mounted) {
        Provider.of<CaretakerProvider>(context, listen: false)
            .setCaretaker(Caretaker.fromJson(caretakerData));
      }

      // Fetch all patients associated with the caretaker
      final patientsResponse = await http.get(
        Uri.parse(dataURL),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Token ${token}',
        },
      );

      if (patientsResponse.statusCode == 200) {
        final patientsData = jsonDecode(patientsResponse.body);

        if (context.mounted) {
          for (var patient in patientsData) {
            Provider.of<PatientProvider>(context, listen: false).addPatient(
              Patient(
                id: (patient['id']).toString(),
                email: patient['email'],
                username: patient['username'],
                name: patient['name'],
                photo: patient['photo'],
                age: patient['age'],
                height: patient['height'],
                weight: patient['weight'],
                medicalConditions: patient['medical_conditions'],
                emergencyContact: patient['emergency_contact'],
                goals: (patient['goals'] as List<dynamic>?)
                        ?.map((item) => item as String)
                        .toList() ??
                    [],
                medicines: (patient['medicines'] as List<dynamic>?)
                        ?.map((item) => item as Map<String, dynamic>)
                        .toList() ??
                    [],
                notes: (patient['notes'] as List<dynamic>?)
                        ?.map((item) => item as Map<String, dynamic>)
                        .toList() ??
                    [],
                appointments: (patient['appointments'] as List<dynamic>?)
                        ?.map((item) => item as Map<String, dynamic>)
                        .toList() ??
                    [],
              ),
            );
          }
        }
      } else {
        // Handle patient data fetch error
        print('Failed to load patient data');
      }
    } else {
      // Handle caretaker data fetch error
      print('Failed to load caretaker data');
    }
  }
  if (!isCaretaker) {
    final patientResponse = await http.get(
      Uri.parse(dataURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token ${token}',
      },
    );

    if (patientResponse.statusCode == 200) {
      final patientData = jsonDecode(patientResponse.body);

      Provider.of<PatientProvider>(context, listen: false).addPatient(
        Patient(
          id: (patientData[0]['id']).toString(),
          email: patientData[0]['email'],
          username: patientData[0]['username'],
          name: patientData[0]['name'],
          photo: patientData[0]['photo'],
          age: patientData[0]['age'],
          height: patientData[0]['height'],
          weight: patientData[0]['weight'],
          medicalConditions: patientData[0]['medical_conditions'],
          emergencyContact: patientData[0]['emergency_contact'],
          goals: (patientData[0]['goals'] as List<dynamic>?)
                  ?.map((item) => item as String)
                  .toList() ??
              [],
          medicines: (patientData[0]['medicines'] as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [],
          notes: (patientData[0]['notes'] as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [],
          appointments: (patientData[0]['appointments'] as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [],
        ),
      );
    } else {
      //   // Handle patient data fetch error
      print('Failed to load patient data');
    }
  }

  // Debug print
  // Check if data is successfully fetched and stored in models
  if (context.mounted) {
    final patients =
        Provider.of<PatientProvider>(context, listen: false).patients;
    final caretaker =
        Provider.of<CaretakerProvider>(context, listen: false).caretaker;

    // for (var patient in patients) {
    //   print(
    //       'Patient: ${patient.name}, Email: ${patient.email}, Username: ${patient.username}');
    // }

    // if (caretaker != null) {
    //   print(
    //       'Caretaker: ${caretaker.name}, Email: ${caretaker.email}, Username: ${caretaker.username}');
    // }
  }
  return true;
}
