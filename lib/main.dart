import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:projects/caretaker/route.dart';
import 'package:projects/patient/route.dart';
import 'provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:flutter/material.dart';



import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  // Base colors
  primaryColor: const Color(0xFF514CE4), // Primary color
  scaffoldBackgroundColor: const Color(0xFFFFFFFF), // White

  // Color scheme
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF514CE4), // Primary color
    secondary: const Color(0xFF757575), // Grey
    background: const Color(0xFFFFFFFF), // White background
    surface: const Color(0xFFFFFFFF), // White surface
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onBackground: const Color(0xFF514CE4),
    onSurface: const Color(0xFF514CE4),
    // primaryVariant: const Color(0xFF3B3AC4), // Darker variant of primary color
    // secondaryVariant: const Color(0xFF6A67E8), // Lighter variant of primary color
  ),

  // Text theme
  textTheme: TextTheme(
    // Large titles
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF514CE4),
    ),
    // App bar and screen titles
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF514CE4),
    ),
    // Subtitle text
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF757575), // Grey
    ),
    // Body text
    bodyLarge: TextStyle(
      fontSize: 16,
      color: const Color(0xFF514CE4),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: const Color(0xFF757575), // Grey
    ),
    // Small text like captions
    bodySmall: TextStyle(
      fontSize: 12,
      color: const Color(0xFF9E9E9E), // Light grey
    ),
  ),

  // AppBar theme
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF514CE4),
    foregroundColor: Colors.white,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
  ),

  // Elevated Button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF514CE4),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),

  // Text Button theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF514CE4),
    ),
  ),

  // Outlined Button theme
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF514CE4),
      side: BorderSide(color: const Color(0xFF514CE4)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),

  // Card theme
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    shadowColor: const Color(0xFF514CE4).withOpacity(0.3),
  ),

  // Input Decoration theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF514CE4).withOpacity(0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF514CE4), width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF514CE4).withOpacity(0.5)),
    ),
    labelStyle: TextStyle(
      color: const Color(0xFF514CE4),
    ),
  ),

  // Floating Action Button theme
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF514CE4), // Primary color
    foregroundColor: Colors.white,
  ),

);void main() async {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => CaretakerProvider()),
        ChangeNotifierProvider(create: (_) => NotesPatient()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: appTheme,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isLoggedIn = false;
  bool isCaretaker = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      isCaretaker = prefs.getBool('isCaretaker') ?? false;
      isLoading = false;
    });

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          child: CircularProgressIndicator(),
           decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF514CE4), Color(0xFF6A67E8)], // Gradient from primary to lighter variant
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      );
    }

    if (isLoggedIn) {
      if (isCaretaker) {
        return CaretakerHomeScreen();
      } else {
        return PatientHomeScreen();
      }
    }

    // This will never be reached because of the Navigator.pushReplacement in checkLoginStatus
    return Container();
  }
}
