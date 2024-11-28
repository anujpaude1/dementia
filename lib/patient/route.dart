import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:projects/utils/signout.dart';
import 'homepage.dart';
import 'appointments.dart';
import 'notes.dart';
import 'medicines.dart';
import '../utils/fetchData.dart';

class PatientHomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<PatientHomeScreen> {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  List<Widget>? _pages;

  @override
   @override
  void initState() {
    super.initState();
    _fetchData();
  }
  void _navigateToPage(int index) {
    setState(() {
      _page = index;
    });
  }

  final List<String> _titles = [
    'Patient Home Page',
    'Appointments',
    'Medicines',
    'Notes',
  ];
Future<void> _fetchData() async {
    await fetchData(context);
    setState(() {
      _pages = [
        PatientHomePage(onNavigate: _navigateToPage), // Home page
        AppointmentsListPage(),
        MedicinesListPage(),
        NotesPage(),
      ];
    });
  }
  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_page]),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              signOut(context);
            },
          ),
        ],
      ),
      body:  _pages == null
          ? Center(child: CircularProgressIndicator())
          : _pages![_page],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 60.0,
        items: <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.calendar_today, size: 30, color: Colors.white),
          Icon(Icons.medical_services, size: 30, color: Colors.white),
          Icon(Icons.note, size: 30, color: Colors.white),
        ],
        color: Theme.of(context).primaryColor,
        buttonBackgroundColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 600),
        onTap: (index) {
          _navigateToPage(index);
        },
      ),
    );
  }
}