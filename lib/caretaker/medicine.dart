import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/UserProvider.dart';
import 'package:projects/utils/signout.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/utils/globals.dart' as Globals;

class Medicine {
  final String name;
  final String dosage;
  final String frequency;

  Medicine({required this.name, required this.dosage, required this.frequency});

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
    };
  }
}

class MedicinePage extends StatefulWidget {
  @override
  _MedicinePageState createState() => _MedicinePageState();
}

class _MedicinePageState extends State<MedicinePage> {
  Future<void> _addMedicine(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController dosageController = TextEditingController();
    final TextEditingController frequencyController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Medicine'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: dosageController,
                  decoration: InputDecoration(labelText: 'Dosage'),
                ),
                TextField(
                  controller: frequencyController,
                  decoration: InputDecoration(labelText: 'Frequency'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Add'),
              onPressed: () async {
                final name = nameController.text;
                final dosage = dosageController.text;
                final frequency = frequencyController.text;

                if (name.isNotEmpty && dosage.isNotEmpty && frequency.isNotEmpty) {
                  final newMedicine = {
                    'name': name,
                    'dosage': dosage,
                    'frequency': frequency,
                  };

                  final patientProvider =
                      Provider.of<PatientProvider>(context, listen: false);
                  final patient = patientProvider.selectedPatient;

                  if (patient != null) {
                    patientProvider.addMedicine(patient.id, newMedicine);
                    await patientProvider.updateOnServer(patient.id);
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editMedicine(BuildContext context, Map<String, dynamic> medicine) async {
    final TextEditingController dosageController = TextEditingController(text: medicine['dosage']);
    final TextEditingController frequencyController = TextEditingController(text: medicine['frequency']);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Medicine'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: dosageController,
                  decoration: InputDecoration(labelText: 'Dosage'),
                ),
                TextField(
                  controller: frequencyController,
                  decoration: InputDecoration(labelText: 'Frequency'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Update'),
              onPressed: () async {
                final dosage = dosageController.text;
                final frequency = frequencyController.text;

                if (dosage.isNotEmpty && frequency.isNotEmpty) {
                  final updatedMedicine = {
                    'name': medicine['name'], // Keep the original name
                    'dosage': dosage,
                    'frequency': frequency,
                  };

                  final patientProvider =
                      Provider.of<PatientProvider>(context, listen: false);
                  final patient = patientProvider.selectedPatient;

                  if (patient != null) {
                    patientProvider.updateMedicine(patient.id, updatedMedicine);
                    await patientProvider.updateOnServer(patient.id);
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context, listen: true);
    final patient = patientProvider.selectedPatient;

    if (patient == null) {
      return Center(child: Text('No patient selected.'));
    }

    final medicines = patient.medicines;

    return Scaffold(
      appBar: AppBar(
        title: Text('Medicines'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              signOut(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: medicines.length,
        itemBuilder: (context, index) {
          final medicine = medicines[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              title: Text(medicine['name']),
              subtitle: Text('Dosage: ${medicine['dosage']}, Frequency: ${medicine['frequency']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _editMedicine(context, medicine);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        final patientProvider = Provider.of<PatientProvider>(context, listen: false);
                        patientProvider.deleteMedicine(patient.id, medicine['name']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Medicine deleted')),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addMedicine(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}