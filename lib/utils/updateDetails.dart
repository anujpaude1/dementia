import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projects/provider/UserProvider.dart';
import 'package:projects/model/models.dart';

class UpdateDetailsPage extends StatefulWidget {
  final Patient patient;

  UpdateDetailsPage({required this.patient});

  @override
  _UpdateDetailsPageState createState() => _UpdateDetailsPageState();
}

class _UpdateDetailsPageState extends State<UpdateDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _emailController = TextEditingController(text: widget.patient.email);
    _usernameController = TextEditingController(text: widget.patient.username);
    _medicalConditionsController =
        TextEditingController(text: widget.patient.medicalConditions);
    _emergencyContactController =
        TextEditingController(text: widget.patient.emergencyContact);
    _heightController =
        TextEditingController(text: widget.patient.height?.toString());
    _weightController =
        TextEditingController(text: widget.patient.weight?.toString());
    _ageController =
        TextEditingController(text: widget.patient.age?.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _medicalConditionsController.dispose();
    _emergencyContactController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _updateDetails() async {
    if (_formKey.currentState!.validate()) {
      final patientProvider =
          Provider.of<PatientProvider>(context, listen: false);
      final updatedPatient = Patient(
        id: widget.patient.id,
        email: _emailController.text,
        username: _usernameController.text,
        name: _nameController.text,
        medicalConditions: _medicalConditionsController.text,
        emergencyContact: _emergencyContactController.text,
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        age: int.tryParse(_ageController.text),
        photo: widget.patient.photo,
        currentCoordinatesLat: widget.patient.currentCoordinatesLat,
        currentCoordinatesLong: widget.patient.currentCoordinatesLong,
        centerCoordinatesLat: widget.patient.centerCoordinatesLat,
        centerCoordinatesLong: widget.patient.centerCoordinatesLong,
        radius: widget.patient.radius,
        goals: widget.patient.goals,
        medicines: widget.patient.medicines,
        notes: widget.patient.notes,
        appointments: widget.patient.appointments,
      );

      patientProvider.updatePatient(widget.patient.id, updatedPatient);
      await patientProvider.updateOnServer(widget.patient.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient details updated successfully.')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Patient Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0), // Add spacing between fields
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0), // Add spacing between fields
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0), // Add spacing between fields
              TextFormField(
                controller: _medicalConditionsController,
                decoration: InputDecoration(labelText: 'Medical Conditions'),
              ),
              SizedBox(height: 16.0), // Add spacing between fields
              TextFormField(
                controller: _emergencyContactController,
                decoration: InputDecoration(labelText: 'Emergency Contact'),
              ),
              SizedBox(height: 16.0), // Add spacing between fields
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(labelText: 'Height'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0), // Add spacing between fields
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(labelText: 'Weight'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.0), // Add spacing between fields
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20), // Add spacing before the button
              ElevatedButton(
                onPressed: _updateDetails,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
