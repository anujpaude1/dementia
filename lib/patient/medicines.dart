import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/UserProvider.dart';

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

class MedicinesListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final patient = Provider.of<PatientProvider>(context).patients[0];
    final medicines = patient.medicines.map<Medicine>((medicine) => Medicine.fromJson(medicine)).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.medical_services, color: Theme.of(context).primaryColor),
                      title: Text('${medicine.name} (${medicine.dosage})'),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          medicine.frequency,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}