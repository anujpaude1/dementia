import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projects/provider/UserProvider.dart';
import 'package:projects/model/models.dart';

class UpdateDetailsCaretakerPage extends StatefulWidget {
  final Caretaker caretaker;

  UpdateDetailsCaretakerPage({required this.caretaker});

  @override
  _UpdateDetailsCaretakerPageState createState() =>
      _UpdateDetailsCaretakerPageState();
}

class _UpdateDetailsCaretakerPageState
    extends State<UpdateDetailsCaretakerPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _qualificationsController;
  late TextEditingController _experienceYearsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.caretaker.name);
    _emailController = TextEditingController(text: widget.caretaker.email);
    _usernameController =
        TextEditingController(text: widget.caretaker.username);
    _qualificationsController =
        TextEditingController(text: widget.caretaker.qualifications);
    _experienceYearsController = TextEditingController(
        text: widget.caretaker.experienceYears?.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _qualificationsController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  Future<void> _updateDetails() async {
    if (_formKey.currentState!.validate()) {
      final caretakerProvider =
          Provider.of<CaretakerProvider>(context, listen: false);
      final updatedCaretaker = Caretaker(
        id: widget.caretaker.id,
        email: _emailController.text,
        username: _usernameController.text,
        name: _nameController.text,
        qualifications: _qualificationsController.text,
        experienceYears: int.tryParse(_experienceYearsController.text),
        photo: widget.caretaker.photo,
        patients: widget.caretaker.patients,
        activePatient: widget.caretaker.activePatient,
      );

      caretakerProvider.updateCaretaker(updatedCaretaker);
      await caretakerProvider.updateOnServer(widget.caretaker.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Caretaker details updated successfully.')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Caretaker Details'),
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
                controller: _qualificationsController,
                decoration: InputDecoration(labelText: 'Qualifications'),
              ),
              SizedBox(height: 16.0), // Add spacing between fields
              TextFormField(
                controller: _experienceYearsController,
                decoration: InputDecoration(labelText: 'Experience Years'),
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
