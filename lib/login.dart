import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projects/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/utils/globals.dart' as globals;
import 'package:projects/signup.dart';
import 'provider/UserProvider.dart';
import 'package:projects/model/user.dart';
import 'package:projects/model/models.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projects/utils/fetchData.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final storage = new FlutterSecureStorage();
  bool _showCogniCare = true;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _showCogniCare = false;
    });
  }

  Future<void> _login(BuildContext context) async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    final String baseURL = globals.baseURL;
    final String loginURL = '$baseURL/api/users/login/';
    final String dataURL = '$baseURL/api/users/patient/';
    // Here you would normally check the credentials with a backend service
    final response = await http.post(
      Uri.parse(loginURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );
    print(response);
    if (response.statusCode == 200) {
      // // If the server returns a 200 OK response, parse the JSON
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      // // Handle the response data as needed
      print(responseData);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isCaretaker',
          responseData['user_type'] == 'caretaker' ? true : false);
      //await prefs.setString('token', responseData['token']);
      await storage.write(key: 'token', value: responseData['token']);

      Provider.of<UserProvider>(context, listen: false).setUser(
        User(
          username: username,
          isLoggedIn: true,
          isCaretaker: responseData['user_type'] == 'caretaker' ? true : false,
          token: responseData['token'],
        ),
      );
      print("fetching data");
      

      

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthWrapper()),
      );
    } else {
      // If the server did not return a 200 OK response, throw an exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: AnimatedSwitcher(
          duration: Duration(seconds: 1),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return child;
          },
          child: TypewriterAnimatedTextKit(
            key: ValueKey('Login'),
            text: ['Login'],
            textStyle: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
            speed: Duration(milliseconds: 200),
            repeatForever: true,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Color(0xFF00DBDE), Color(0xFFFC00FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',
                  color: Colors.white, // This color will be masked by the gradient
                ),
              ),
            ),
            SizedBox(height: 20),
            FocusScope(
              child: Focus(
                onFocusChange: (focus) {
                  setState(() {});
                },
                child: TextField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  decoration: InputDecoration(
                    hintText: _usernameFocusNode.hasFocus ? '' : 'Username',
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            FocusScope(
              child: Focus(
                onFocusChange: (focus) {
                  setState(() {});
                },
                child: TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  decoration: InputDecoration(
                    hintText: _passwordFocusNode.hasFocus ? '' : 'Password',
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  obscureText: true,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle login
                  _login(context);
              },
              child: Text('Login'),
            ),
            
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Handle signup
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupPage()),
                );
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  
  }
}
