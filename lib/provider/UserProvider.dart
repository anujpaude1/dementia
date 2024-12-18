import 'package:flutter/material.dart';
import 'package:projects/model/user.dart';
import 'package:projects/model/models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/utils/globals.dart' as Globals;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider with ChangeNotifier {
  User _user =
      User(username: '', isLoggedIn: false, isCaretaker: false, token: '');

  User get user => _user;

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user =
        User(username: '', isLoggedIn: false, isCaretaker: false, token: '');
    notifyListeners();
  }
}

class CaretakerProvider with ChangeNotifier {
  Caretaker? _caretaker;

  Caretaker? get caretaker => _caretaker;

  // Fetch caretaker (mock API or real API)
  Future<void> fetchCaretaker() async {
    // Mock API Response
    Map<String, dynamic> response = {
      'id': '1',
      'email': 'caretaker1@example.com',
      'username': 'caretaker1',
      'name': 'Caretaker One',
      'is_active': true,
      'photo': null,
      'qualifications': 'Certified Nurse',
      'experience_years': 5,
      'patients': [],
    };

    _caretaker = Caretaker.fromJson(response);
    notifyListeners();
  }

  // Set caretaker
  void setCaretaker(Caretaker caretaker) {
    _caretaker = caretaker;
    notifyListeners();
  }

  void clearCaretakers() {
    _caretaker = null;
    notifyListeners();
  }

  // Update caretaker
  void updateCaretaker(Caretaker updatedCaretaker) {
    _caretaker = updatedCaretaker;
    notifyListeners();
  }

  // Sync caretaker data with server
  Future<void> updateOnServer(String caretakerId) async {
    final baseURL = Globals.baseURL;
    final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    print("Token is $token");
    print(jsonEncode(_caretaker!.toJson()));
    final String url = '$baseURL/api/users/caretaker/';
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': "Token $token",
      },
      body: jsonEncode(_caretaker!.toJson()),
    );
    if (response.statusCode != 200) {
      // Handle error
      print('Failed to update caretaker on server');
      print(response.body);
    }
    if (response.statusCode == 200) {
      print('Caretaker updated on server');
    }
  }
}

class PatientProvider with ChangeNotifier {
  List<Patient> _patients = [];
  Patient? _selectedPatient;

  List<Patient> get patients => _patients;
  Patient? get selectedPatient => _selectedPatient;

  // Fetch patients (mock API or real API)
  Future<void> fetchPatients() async {
    // Mock API Response
    List<Map<String, dynamic>> response = [
      {
        'id': '1',
        'email': 'patient1@example.com',
        'username': 'patient1',
        'name': 'Patient One',
        'is_active': true,
        'medical_conditions': 'Diabetes',
        'emergency_contact': '123456789',
        'height': 175.5,
        'weight': 70.2,
        'age': 30,
        'goals': [],
        'medicines': [],
        'notes': [],
        'appointments': [],
        'photo': '',
      }
    ];

    _patients = response.map((data) => Patient.fromJson(data)).toList();
    notifyListeners();
  }

  // Add a new patient
  void addPatient(Patient patient) {
    _patients.add(patient);
    notifyListeners();
  }

  // Function to update centerCoordinatesLat, centerCoordinatesLong, and radius
  void updatePatientLocation(
      String patientId, double lat, double long, double radius) {
    int index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      _patients[index].centerCoordinatesLat = lat;
      _patients[index].centerCoordinatesLong = long;
      _patients[index].radius = radius;
      notifyListeners();
    }
  }

  // Create a patient from JSON and add to the list
  void createAndAddPatient(Map<String, dynamic> patientJson) {
    Patient newPatient = Patient.fromJson(patientJson);
    addPatient(newPatient);
  }

  void clearPatients() {
    _patients = [];
    _selectedPatient = null;
    notifyListeners();
  }

  // Select a patient
  void selectPatient(Patient patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

  // Update a patient
  void updatePatient(String id, Patient updatedPatient) {
    int index = _patients.indexWhere((p) => p.id == id);
    if (index != -1) {
      _patients[index] = updatedPatient;
      _selectedPatient = updatedPatient;
      notifyListeners();
    }
  }

  // Delete a patient
  void deletePatient(String id) {
    _patients.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Add an appointment
  void addAppointment(String patientId, Map<String, dynamic> appointment) {
    print(appointment);
    int index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      _patients[index].appointments.add(appointment);
      notifyListeners();
    }
  }

  // Add a medicine
  void addMedicine(String patientId, Map<String, dynamic> medicine) {
    int index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      _patients[index].medicines.add(medicine);
      notifyListeners();
    }
  }

  void updateMedicine(String patientId, Map<String, dynamic> updatedMedicine) {
    int patientIndex = _patients.indexWhere((p) => p.id == patientId);
    if (patientIndex != -1) {
      int medicineIndex = _patients[patientIndex]
          .medicines
          .indexWhere((m) => m['name'] == updatedMedicine['name']);
      if (medicineIndex != -1) {
        _patients[patientIndex].medicines[medicineIndex] = updatedMedicine;
        notifyListeners();
      }
    }
  }

  void deleteMedicine(String patientId, String medicineName) {
    int patientIndex = _patients.indexWhere((p) => p.id == patientId);
    if (patientIndex != -1) {
      _patients[patientIndex]
          .medicines
          .removeWhere((m) => m['name'] == medicineName);
      notifyListeners();
    }
  }

  // Add a note
  void addNote(String patientId, Map<String, dynamic> note) {
    int index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      _patients[index].notes.add(note);
      notifyListeners();
    }
  }

  //Update note
  void updateNote(Map<String, dynamic> updatedNote) {
    int noteIndex = _patients[0]
        .notes
        .indexWhere((n) => n['title'] == updatedNote['title']);
    if (noteIndex != -1) {
      _patients[0].notes[noteIndex] = updatedNote;
      notifyListeners();
    }
  }

  //Delete note
  void deleteNote(String title) {
    _patients[0].notes.removeWhere((n) => n['title'] == title);
    notifyListeners();
  }

  void updateAppointment(
      String patientId, Map<String, dynamic> updatedAppointment) {
    int patientIndex = _patients.indexWhere((p) => p.id == patientId);
    if (patientIndex != -1) {
      int appointmentIndex = _patients[patientIndex]
          .appointments
          .indexWhere((a) => a['date'] == updatedAppointment['date']);
      if (appointmentIndex != -1) {
        _patients[patientIndex].appointments[appointmentIndex] =
            updatedAppointment;
        notifyListeners();
      }
    }
  }

  void deleteAppointment(String patientId, String appointmentDate) {
    int patientIndex = _patients.indexWhere((p) => p.id == patientId);
    if (patientIndex != -1) {
      _patients[patientIndex]
          .appointments
          .removeWhere((a) => a['date'] == appointmentDate);
      notifyListeners();
    }
  }

  void allPatientsDetails() {
    for (var patient in _patients) {
      print(patient.toJson());
    }
  }

  //sync all data with server of selected patient
  Future<void> updateOnServer(String patientId) async {
    final baseURL = Globals.baseURL;
    final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    print("Token is $token");
    print(jsonEncode(_selectedPatient!.toJson()));
    final String url = '$baseURL/api/users/patient/$patientId/';
    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': "Token ${token}",
      },
      body: jsonEncode(_selectedPatient!.toJson()),
    );
    if (response.statusCode != 200) {
      // Handle error
      print('Failed to update patient on server');
      print(response.body);
    }
    if (response.statusCode == 200) {
      print('Patient updated on server');
    }
  }
}

class NotesPatient with ChangeNotifier {
  List<dynamic> _notes = [];

  List<dynamic> get notes => _notes;

  void setNotes(List<dynamic> notes) {
    _notes = notes;
    notifyListeners();
  }

  Future<void> fetchNotes(String patientId) async {
    final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    final baseURL = Globals.baseURL;
    final String notesURL = '$baseURL/api/users/patient/notes/';

    final response = await http.get(
      Uri.parse(notesURL),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final notesData = json.decode(response.body);
      setNotes(notesData);
    } else {
      // Handle error
      print('Failed to fetch notes');
    }
  }

  Future<void> addNote(Map<String, dynamic> note) async {
    final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    final baseURL = Globals.baseURL;
    final String notesURL = '$baseURL/api/users/patient/notes/';

    final response = await http.post(
      Uri.parse(notesURL),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode(note),
    );

    if (response.statusCode == 201) {
      _notes.add(note);
      notifyListeners();
    } else {
      // Handle error
      print('Failed to add note');
    }
  }

  Future<void> updateNote(
      String noteId, Map<String, dynamic> updatedNote) async {
    final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    final baseURL = Globals.baseURL;
    final String noteURL = '$baseURL/api/users/patient/notes/$noteId';

    final response = await http.put(
      Uri.parse(noteURL),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: json.encode(updatedNote),
    );

    if (response.statusCode == 200) {
      int index = _notes.indexWhere((note) => note['id'] == noteId);
      if (index != -1) {
        _notes[index] = updatedNote;
        notifyListeners();
      }
    } else {
      // Handle error
      print('Failed to update note');
    }
  }

  Future<void> deleteNote(String noteId) async {
    final storage = new FlutterSecureStorage();
    final token = await storage.read(key: 'token') ?? '';
    final baseURL = Globals.baseURL;
    final String noteURL = '$baseURL/api/users/patient/notes/$noteId';

    final response = await http.delete(
      Uri.parse(noteURL),
      headers: {
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 204) {
      _notes.removeWhere((note) => note['id'] == noteId);
      notifyListeners();
    } else {
      // Handle error
      print('Failed to delete note');
    }
  }
}
