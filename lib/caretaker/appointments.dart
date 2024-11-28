import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projects/provider/UserProvider.dart';
import 'package:projects/utils/signout.dart';
import 'package:projects/utils/globals.dart' as Globals;
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppointmentsPage extends StatefulWidget {
  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with SingleTickerProviderStateMixin {
  final String baseURL = Globals.baseURL;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _initialFunction();
  }

  void _initialFunction() async {
    // Fetch initial data if needed
    _controller.forward();
  }

  Future<void> _addAppointment(BuildContext context) async {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController timeController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Appointment'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                ),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(labelText: 'Time (HH:MM AM/PM)'),
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
                final description = descriptionController.text;
                final date = dateController.text;
                final time = timeController.text;

                if (description.isNotEmpty &&
                    date.isNotEmpty &&
                    time.isNotEmpty) {
                  final newAppointment = {
                    'description': description,
                    'date': date,
                    'time': time,
                  };

                  final patientProvider =
                      Provider.of<PatientProvider>(context, listen: false);
                  final patient = patientProvider.selectedPatient;

                  if (patient != null) {
                    patientProvider.addAppointment(patient.id, newAppointment);
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

  Future<void> _editAppointment(BuildContext context, Map<String, dynamic> appointment) async {
    final TextEditingController descriptionController = TextEditingController(text: appointment['description']);
    final TextEditingController dateController = TextEditingController(text: appointment['date']);
    final TextEditingController timeController = TextEditingController(text: appointment['time']);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Appointment'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                ),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(labelText: 'Time (HH:MM AM/PM)'),
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
                final description = descriptionController.text;
                final date = dateController.text;
                final time = timeController.text;

                if (description.isNotEmpty &&
                    date.isNotEmpty &&
                    time.isNotEmpty) {
                  final updatedAppointment = {
                    'description': description,
                    'date': date,
                    'time': time,
                  };

                  final patientProvider =
                      Provider.of<PatientProvider>(context, listen: false);
                  final patient = patientProvider.selectedPatient;

                  if (patient != null) {
                    patientProvider.updateAppointment(patient.id, updatedAppointment);
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context, listen: true);
    final patient = patientProvider.selectedPatient;

    if (patient == null) {
      return Center(child: Text('No patient selected.'));
    }

    final appointments = patient.appointments;
    appointments.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
    final upcomingAppointment = appointments.isNotEmpty ? appointments.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointments'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              signOut(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (upcomingAppointment != null)
            SlideTransition(
              position: _offsetAnimation,
              child: Container(
                padding: EdgeInsets.all(16.0),
                color: Colors.blue,
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Upcoming Appointment: ${upcomingAppointment['description']} on ${upcomingAppointment['date']} at ${upcomingAppointment['time']}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(appointment['description']),
                    subtitle: Text('${appointment['date']} at ${appointment['time']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editAppointment(context, appointment);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              final patientProvider = Provider.of<PatientProvider>(context, listen: false);
                              patientProvider.deleteAppointment(patient.id, appointment['date']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Appointment deleted')),
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addAppointment(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
