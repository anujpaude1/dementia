import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/UserProvider.dart';
import 'package:projects/utils/signout.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:projects/utils/globals.dart' as Globals;

class Note {
  final String title;
  final String description;
  final DateTime createdDate;

  Note({
    required this.title,
    required this.description,
    required this.createdDate,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title'],
      description: json['description'],
      createdDate: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': createdDate.toIso8601String(),
    };
  }
}

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  Note? selectedNote;

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context, listen: true);
    final patient = patientProvider.selectedPatient;

    if (patient == null) {
      return Center(child: Text('No patient selected.'));
    }

    final notes =
        patient.notes.map<Note>((note) => Note.fromJson(note)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              signOut(context);
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: selectedNote == null
            ? Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      key: ValueKey<int>(0),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(note.title,
                                style: Theme.of(context).textTheme.bodyLarge),
                            subtitle: Text(
                              'Created on: ${note.createdDate.toLocal().toString().split(' ')[0]}',
                            ),
                            onTap: () {
                              setState(() {
                                selectedNote = note;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            : Column(
                key: ValueKey<int>(1),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.secondary,
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              selectedNote = null;
                            });
                          },
                        ),
                        SizedBox(width: 10),
                        Text(
                          selectedNote!.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            'Created on: ${selectedNote!.createdDate.toLocal().toString().split(' ')[0]}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          SizedBox(height: 20),
                          Text(
                            selectedNote!.description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNote(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _addNote(BuildContext context) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                final title = titleController.text;
                final description = descriptionController.text;

                if (title.isNotEmpty && description.isNotEmpty) {
                  final newNote = {
                    'title': title,
                    'description': description,
                    'date': DateTime.now().toIso8601String(),
                  };

                  final patientProvider =
                      Provider.of<PatientProvider>(context, listen: false);
                  final patient = patientProvider.selectedPatient;

                  if (patient != null) {
                    patientProvider.addNote(patient.id, newNote);
                    await patientProvider.updateOnServer(patient.id);
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
