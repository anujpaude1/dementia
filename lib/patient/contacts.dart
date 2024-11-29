import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:projects/utils/globals.dart' as globals;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Contact {
  final int id;
  final String name;
  final String phoneNumber;
  final String? photo;
  final String relationship;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.photo,
    required this.relationship,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      photo: json['photo'],
      relationship: json['relationship'],
    );
  }
}

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
   final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    final String baseURL = globals.baseURL;
    final String contactsURL = '$baseURL/contacts/patient/';

    final response = await http.get(
      Uri.parse(contactsURL),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      setState(() {
        contacts = jsonResponse.map((data) => Contact.fromJson(data)).toList();
        isLoading = false;
      });
    } else {
      print('Failed to load contacts');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: contact.photo != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(contact.photo!),
                          )
                        : CircleAvatar(
                            child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                          ),
                    title: Text(contact.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.phoneNumber),
                        Text(contact.relationship, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.phone, color: Colors.green),
                      onPressed: () {
                        _makePhoneCall(contact.phoneNumber);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
} 