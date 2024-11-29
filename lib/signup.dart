import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projects/utils/globals.dart' as globals;
import 'package:projects/main.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:image_picker/image_picker.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  bool _isCaretaker = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _profileImage = pickedFile;
    });
  }

  Future<void> _signup(BuildContext context) async {
    final String username = _usernameController.text;
    final String password = _passwordController.text;
    final String email = _emailController.text;
    final String baseURL = globals.baseURL;
    final String signupURL = '$baseURL/api/users/signup/';

    final request = http.MultipartRequest('POST', Uri.parse(signupURL));
    request.fields['username'] = username;
    request.fields['password'] = password;
    request.fields['email'] = email;
    request.fields['user_type'] = _isCaretaker ? 'caretaker' : 'patient';

    if (_profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('photo', _profileImage!.path),
      );
    }

    final response = await request.send();
    if (response.statusCode == 201) {
      final responseData = await http.Response.fromStream(response);
      final Map<String, dynamic> jsonResponse = jsonDecode(responseData.body);
      print(jsonResponse);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isCaretaker', _isCaretaker);
      // Store the token in secure storage
      final storage = FlutterSecureStorage();
      await storage.write(key: 'token', value: jsonResponse['token']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthWrapper()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Sign Up',
              textStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              speed: Duration(milliseconds: 200),
            ),
          ],
          repeatForever: true,
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _profileImage != null ? FileImage(File(_profileImage!.path)) : null,
                  child: _profileImage == null
                      ? Icon(
                          Icons.camera_alt,
                          color: Colors.grey[800],
                          size: 50,
                        )
                      : null,
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
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
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    decoration: InputDecoration(
                      hintText: _emailFocusNode.hasFocus ? '' : 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    obscureText: true,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Are you a caretaker?'),
                  Switch(
                    value: _isCaretaker,
                    onChanged: (value) {
                      setState(() {
                        _isCaretaker = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _signup(context);
                },
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}