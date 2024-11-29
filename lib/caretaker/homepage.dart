import 'package:flutter/material.dart';
import 'package:projects/provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:projects/utils/signout.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projects/utils/globals.dart' as globals;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CaretakerHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Caretaker'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              signOut(context);
            },
          ),
        ],
      ),
      body: Consumer<CaretakerProvider>(
        builder: (context, caretakerProvider, child) {
          final caretaker = caretakerProvider.caretaker;
          if (caretaker == null) {
            return Center(child: Text('No caretaker data available.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: caretaker.photo != null
                        ? NetworkImage(caretaker.photo!)
                        : AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    caretaker.name ?? 'No Name',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    caretaker.email,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Qualifications:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  caretaker.qualifications ?? 'No qualifications',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'Experience Years:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  caretaker.experienceYears?.toString() ??
                      'No experience years',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Show list of patients in a popup page
                      showDialog(
                        context: context,
                        builder: (context) => PatientListPopup(),
                      );
                    },
                    child: Text('Switch Patient'),
                  ),
                ),
                SizedBox(height: 20),
                Consumer<PatientProvider>(
                  builder: (context, patientProvider, child) {
                    final patient = patientProvider.selectedPatient;
                    if (patient == null) {
                      return Center(child: Text('No patient selected.'));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Active Patient:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: patient.photo.isNotEmpty
                                ? NetworkImage(patient.photo)
                                : AssetImage('assets/default_avatar.png')
                                    as ImageProvider,
                          ),
                          title: Text(patient.username),
                          subtitle: Text(patient.email),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PatientListPopup extends StatelessWidget {
  Future<void> _assignPatient(
      BuildContext context, String patientUsername) async {
    final String baseURL = globals.baseURL;
    final String assignURL = '$baseURL/api/users/assign/';
    final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';

    final response = await http.post(
      Uri.parse(assignURL),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'patient_username': patientUsername,
      }),
    );
    print(response.body);
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final patientDetails = responseData['patient_details'];

      // Use a callback to update the state after the asynchronous operation completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final patientProvider =
            Provider.of<PatientProvider>(context, listen: false);
        patientProvider.createAndAddPatient(patientDetails);
        patientProvider.allPatientsDetails();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient assigned successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign patient.')),
      );
    }
  }

  void _showAssignPatientDialog(BuildContext context) {
    final TextEditingController _usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign Patient'),
          content: TextField(
            controller: _usernameController,
            decoration: InputDecoration(hintText: 'Enter patient username'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final patientUsername = _usernameController.text;
                if (patientUsername.isNotEmpty) {
                  _assignPatient(context, patientUsername).then((_) {
                    Navigator.of(context).pop();
                  });
                }
              },
              child: Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Select Patient'),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _showAssignPatientDialog(context);
            },
          ),
        ],
      ),
      content: Consumer<PatientProvider>(
        builder: (context, patientProvider, child) {
          return Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: patientProvider.patients.length,
              itemBuilder: (context, index) {
                final patient = patientProvider.patients[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: patient.photo.isNotEmpty
                        ? NetworkImage(patient.photo)
                        : AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                  ),
                  title: Text(patient.username),
                  onTap: () {
                    // Set the selected patient as the active patient
                    patientProvider.selectPatient(patient);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
