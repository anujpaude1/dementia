import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/UserProvider.dart';
import '../provider/UserProvider.dart';
import 'medicines.dart';
import 'notes.dart';
import 'appointments.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientHomePage extends StatelessWidget {
  final Function(int) onNavigate;
   void _makeEmergencyCall(String? phoneNumber) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );
      await launchUrl(launchUri);
    } else {
      // Handle the case where the phone number is not available
      print('Emergency contact number is not available');
    }
  }


  PatientHomePage({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final use = userProvider.user;
    final patient = Provider.of<PatientProvider>(context).patients[0];

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(patient.photo),
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${patient.name}'), // Add patient name
                      Text('Age: ${patient.age} years'), // Add patient age
                      Text('Height: ${patient.height} cm'), // Add patient height
                      Text('Weight: ${patient.weight} kg'), // Add patient weight
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildGridTile(context, Icons.calendar_today, 'Appointments', Colors.lightGreen, () {
                    onNavigate(1); // Navigate to Appointments page
                  }),
                  _buildGridTile(context, Icons.medical_services, 'Medicines', const Color.fromARGB(255, 74, 153, 195), () {
                    onNavigate(2); // Navigate to Medicines page
                  }),
                  _buildGridTile(context, Icons.note, 'Notes', const Color.fromARGB(255, 153, 74, 195), () {
                    onNavigate(3); // Navigate to Notes page
                  }),
                  _buildGridTile(context, Icons.support, 'Support', const Color.fromARGB(255, 195, 167, 74), () {
                    // Navigate to Support page
                  }),
                ],
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
              
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpansionTile(
                  leading: Icon(Icons.star, color: Theme.of(context).primaryColor),
                  title: Text('Goals & Achievements', style: Theme.of(context).textTheme.bodyLarge),
                  backgroundColor: Colors.pink.withOpacity(0.1),
                  children: patient.goals.map((goal) {
                    return ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text(goal), // Add goal title
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.red),
                title: Text('Emergency Contact'),
                tileColor: Colors.red.withOpacity(0.2),
                onTap: () {
                  // Handle emergency contact call
                  _makeEmergencyCall(patient.emergencyContact);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 10),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}
