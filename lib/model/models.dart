import 'package:flutter/foundation.dart';

class Caretaker {
  String id;
  String email;
  String username;
  String? name;
  bool isActive;
  String? photo;
  String? qualifications;
  int? experienceYears;
  List<Patient> patients;
  Patient? activePatient;

  Caretaker({
    required this.id,
    required this.email,
    required this.username,
    this.name,
    this.isActive = true,
    this.photo,
    this.qualifications,
    this.experienceYears,
    this.patients = const [],
    this.activePatient,
  });

  // Factory constructor for JSON deserialization
  factory Caretaker.fromJson(Map<String, dynamic> json) {
    return Caretaker(
      id: (json['id']).toString(),
      email: json['email'],
      username: json['username'],
      name: json['name'],
      photo: json['photo'],
      qualifications: json['qualifications'],
      experienceYears: json['experience_years'],
    );
  }

  // Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'is_active': isActive,
      'photo': photo,
      'qualifications': qualifications,
      'experience_years': experienceYears,
      'patients': patients.map((patient) => patient.toJson()).toList(),
      'active_patient': activePatient?.toJson(),
    };
  }
}

class Patient {
  String id;
  String email;
  String username;
  String? name;
  bool isActive;
  String photo;
  String? medicalConditions;
  String? emergencyContact;
  double? height;
  double? weight;
  int? age;
  double? currentCoordinatesLat;
  double? currentCoordinatesLong;
  double? centerCoordinatesLat;
  double? centerCoordinatesLong;
  double radius;
  List<String> goals;
  List<Map<String, dynamic>> medicines;
  List<Map<String, dynamic>> notes;
  List<Map<String, dynamic>> appointments;

  Patient({
    required this.id,
    required this.email,
    required this.username,
    this.name,
    this.isActive = true,
    this.medicalConditions,
    this.emergencyContact,
    this.height,
    this.weight,
    this.age,
    this.currentCoordinatesLat,
    this.currentCoordinatesLong,
    this.centerCoordinatesLat,
    this.centerCoordinatesLong,
    this.radius = 5.0,
    this.goals = const [],
    this.medicines = const [],
    this.notes = const [],
    this.appointments = const [],
    this.photo = '',
  });

  // Factory constructor for JSON deserialization
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      name: json['name'],
      isActive: json['is_active'],
      medicalConditions: json['medical_conditions'],
      emergencyContact: json['emergency_contact'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      age: json['age'],
      currentCoordinatesLat: json['current_coordinates_lat']?.toDouble(),
      currentCoordinatesLong: json['current_coordinates_long']?.toDouble(),
      centerCoordinatesLat: json['center_coordinates_lat']?.toDouble(),
      centerCoordinatesLong: json['center_coordinates_long']?.toDouble(),
      radius: json['radius']?.toDouble() ?? 5.0,
      goals: (json['goals'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          [],
      medicines: (json['medicines'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [],
      notes: (json['notes'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [],
      appointments: (json['appointments'] as List<dynamic>?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [],
      photo: json['photo'] ?? '',
    );
  }

  // Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'name': name,
      'is_active': isActive,
      'medical_conditions': medicalConditions,
      'emergency_contact': emergencyContact,
      'height': height,
      'weight': weight,
      'age': age,
      'radius': radius,
      'goals': goals,
      'medicines': medicines,
      'appointments': appointments,
    };
  }
}
