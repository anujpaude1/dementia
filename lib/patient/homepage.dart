import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/UserProvider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/chat.dart'; // Import the ChatPage

class PatientHomePage extends StatelessWidget {
  final Function(int) onNavigate;

  PatientHomePage({required this.onNavigate});

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

  void _openGoogleMaps(double? lat, double? long) async {
    if (lat != null && long != null) {
      final Uri googleMapsUri = Uri(
        scheme: 'https',
        host: 'www.google.com',
        path: '/maps/search/',
        queryParameters: {'api': '1', 'query': '$lat,$long'},
      );
      await launchUrl(googleMapsUri);
    } else {
      // Handle the case where the coordinates are not available
      print('Coordinates are not available');
    }
  }

  Future<void> getLocation() async {
    final String baseURL = 'https://example.com'; // Replace with your actual base URL
    final String locationURL = '$baseURL/api/users/patient/6/location/';

    try {
      final response = await http.get(Uri.parse(locationURL));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final double? lat = jsonResponse['latitude'];
        final double? long = jsonResponse['longitude'];
        _openGoogleMaps(lat, long);
      } else {
        print('Failed to fetch location');
      }
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 80, // Bigger size
                  backgroundImage: NetworkImage(patient.photo),
                ),
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Hey ${patient.name},',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                        color: Colors.white, // This color will be masked by the gradient
                      ),
                    ),
                  ),
                  Text(
                    'How may I help you today?',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [Color(0xFFabbaab), Color(0xFFffffff)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    backgroundBlendMode: BlendMode.overlay,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildDetailRow('Name:', patient.name ?? 'N/A'),
                        _buildDetailRow('Age:', '${patient.age} years'),
                        _buildDetailRow('Height:', '${patient.height} cm'),
                        _buildDetailRow('Weight:', '${patient.weight} kg'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [Color.fromARGB(255, 255, 255, 255), Color(0xFFffffff)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: true, // Expanded by default
                    leading: Icon(Icons.star, color: Theme.of(context).primaryColor),
                    title: Text('Goals & Achievements', style: Theme.of(context).textTheme.bodyLarge),
                    children: patient.goals.map((goal) {
                      return ListTile(
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text(goal), // Add goal title
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(Icons.navigation, color: Theme.of(context).primaryColor),
                  title: Text('Navigate Home', style: TextStyle(fontSize: 18, fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
                  onTap: () {
                    getLocation();
                  },
                ),
              ),
              SizedBox(height: 10),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(Icons.phone, color: Colors.red),
                  title: Text('Emergency Call', style: TextStyle(color: Colors.red, fontSize: 18, fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
                  onTap: () {
                    _makeEmergencyCall(patient.emergencyContact);
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
  onPressed: () {
    Navigator.of(context).pop();
  },
  icon: Icon(Icons.home, color: Theme.of(context).primaryColor),
  label: Text('Home'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Theme.of(context).primaryColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
)

            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ChatPage()),
          );
        },
        child: Icon(Icons.chat),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: color ?? Colors.black,
            ),
          ),
          SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Roboto',
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}