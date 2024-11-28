import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:projects/caretaker/route.dart';
import 'package:projects/patient/route.dart';
import 'provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  // Base colors
  primaryColor: const Color(0xFF06402B),
  scaffoldBackgroundColor: const Color(0xFFF5ECE5),

  // Color scheme
  colorScheme: ColorScheme.light(
    primary: const Color(0xFF06402B), // Dark olive green
    secondary: const Color(0xFFAD5D50), // Terracotta red
    background: const Color(0xFFF5ECE5), // Soft beige background
    surface: const Color(0xFFF5ECE5),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: const Color(0xFF06402B),
    onSurface: const Color(0xFF45523E),
  ),

  // Text theme
  textTheme: TextTheme(
    // Large titles
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    // App bar and screen titles
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    // Subtitle text
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF45523E),
    ),
    // Body text
    bodyLarge: TextStyle(
      fontSize: 16,
      color: Colors.black,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: const Color(0xFF45523E),
    ),
    // Small text like captions
    bodySmall: TextStyle(
      fontSize: 12,
      color: const Color(0xFFAD5D50),
    ),
  ),

  // AppBar theme
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF45523E),
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
      backgroundColor: const Color(0xFF45523E),
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
      foregroundColor: const Color(0xFF45523E),
    ),
  ),

  // Outlined Button theme
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF45523E),
      side: BorderSide(color: const Color(0xFF45523E)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),

  // Card theme
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    shadowColor: const Color(0xFF45523E).withOpacity(0.3),
  ),

  // Input Decoration theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFFAD5D50).withOpacity(0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF45523E), width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFFAD5D50).withOpacity(0.5)),
    ),
    labelStyle: TextStyle(
      color: const Color(0xFF45523E),
    ),
  ),

  // Floating Action Button theme
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFFAD5D50),
    foregroundColor: Colors.white,
  ),
);

void main() async {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => CaretakerProvider())
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        body: Center(
          child: CircularProgressIndicator(),
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
