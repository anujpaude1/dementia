import 'package:flutter/material.dart';
import 'package:projects/provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:projects/utils/signout.dart';

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
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Patient'),
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
