import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:projects/utils/signout.dart';
import 'package:projects/utils/fetchData.dart';
import 'package:projects/caretaker/homepage.dart';
import 'package:projects/caretaker/map.dart';
import 'package:projects/caretaker/medicine.dart';

import 'package:projects/caretaker/notes.dart';
import '../provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:projects/utils/globals.dart' as globals;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:projects/caretaker/appointments.dart';

class CaretakerHomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<CaretakerHomeScreen> {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initialFunction();
  }

  void _initialFunction() async {
    await fetchData(context);
  }

  List<Widget> getPages() {
    return [
      CaretakerHomePage(),
      AppointmentsPage(),
      MedicinePage(),
      NotesPage(),
      MapPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getPages()[_page],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: 0,
        height: 60.0,
        items: <Widget>[
          Icon(Icons.home, size: 20),
          Icon(Icons.calendar_today, size: 20),
          Icon(FontAwesomeIcons.pills, size: 20),
          Icon(Icons.note, size: 20),
          Icon(Icons.map, size: 20),
        ],
        color: Theme.of(context).primaryColor,
        buttonBackgroundColor: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 600),
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
