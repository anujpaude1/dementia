import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../provider/UserProvider.dart';

class Appointment {
  final String description;
  final DateTime dateTime;

  Appointment({required this.description, required this.dateTime});

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final date = json['date'];
    final time = json['time'];
    final dateTimeString = '$date $time';
    final dateTime = DateFormat('yyyy-MM-dd hh:mm a').parse(dateTimeString);

    return Appointment(
      description: json['description'],
      dateTime: dateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'date': DateFormat('yyyy-MM-dd').format(dateTime),
      'time': DateFormat('hh:mm a').format(dateTime),
    };
  }
}

class AppointmentsListPage extends StatefulWidget {
  @override
  _AppointmentsListPageState createState() => _AppointmentsListPageState();
}

class _AppointmentsListPageState extends State<AppointmentsListPage> with SingleTickerProviderStateMixin {
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

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = Provider.of<PatientProvider>(context).patients[0];
    final appointments = patient.appointments.map<Appointment>((appointment) => Appointment.fromJson(appointment)).toList();

    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final upcomingAppointment = appointments.first;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlideTransition(
              position: _offsetAnimation,
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Upcoming Appointment: ${upcomingAppointment.description} on ${DateFormat.yMMMd().format(upcomingAppointment.dateTime)} at ${DateFormat.jm().format(upcomingAppointment.dateTime)}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                      title: Text(appointment.description),
                      subtitle: Text(
                        '${DateFormat.yMMMd().format(appointment.dateTime)} at ${DateFormat.jm().format(appointment.dateTime)}',
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