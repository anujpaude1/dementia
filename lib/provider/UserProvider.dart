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

  void clearPatients() {
    _patients = [];
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
