import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/UserProvider.dart';

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  Map<String, dynamic>? selectedNote;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final patient = Provider.of<PatientProvider>(context).patients[0];
    final notes = patient.notes;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: selectedNote == null
                ? Padding(
                    padding: const EdgeInsets.only(
                        top:
                            70.0), // Adjust padding to move the notes container below the FAB
                    child: ListView.builder(
                      key: ValueKey<int>(0),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(note['title'],
                                style: Theme.of(context).textTheme.bodyLarge),
                            subtitle: Text(
                              'Created on: ${DateTime.parse(note['date']).toLocal().toString().split(' ')[0]}',
                            ),
                            onTap: () {
                              setState(() {
                                selectedNote = note;
                                _titleController.text = note['title'];
                                _descriptionController.text =
                                    note['description'];
                              });
                            },
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Handle note delete
                                setState(() {
                                  final patientProvider =
                                      Provider.of<PatientProvider>(context,
                                          listen: false);
                                  patientProvider.deleteNote(note['title']);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Note deleted')),
                                  );
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Column(
                    key: ValueKey<int>(1),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: Theme.of(context).primaryColor,
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
                              selectedNote!['title'],
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
                                'Created on: ${DateTime.parse(selectedNote!['date']).toLocal().toString().split(' ')[0]}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              SizedBox(height: 20),
                              TextField(
                                controller: _descriptionController,
                                maxLines: null,
                                decoration: InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Handle note update
                                      // Update the note in the model
                                      setState(() {
                                        selectedNote!['description'] =
                                            _descriptionController.text;
                                        // Update the note in the patient model
                                        final patientProvider =
                                            Provider.of<PatientProvider>(
                                                context,
                                                listen: false);
                                        patientProvider
                                            .updateNote(selectedNote!);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('Note updated')),
                                        );
                                      });
                                    },
                                    icon: Icon(Icons.update),
                                    label: Text('Update'),
                                  ),
                                  SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Handle note delete
                                      // Delete the note from the model
                                      setState(() {
                                        final patientProvider =
                                            Provider.of<PatientProvider>(
                                                context,
                                                listen: false);
                                        patientProvider
                                            .deleteNote(selectedNote!['title']);
                                        selectedNote = null;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('Note deleted')),
                                        );
                                      });
                                    },
                                    icon: Icon(Icons.delete),
                                    label: Text('Delete'),
                                    style: ElevatedButton.styleFrom(
                                      iconColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                _showAddNoteDialog(context);
              },
              icon: Icon(Icons.add),
              label: Text('Add Note'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    _titleController.clear();
    _descriptionController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Note'),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle note addition
                // Add a new note to the model
                setState(() {
                  final newNote = {
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'date': DateTime.now().toIso8601String(),
                  };
                  final patientProvider =
                      Provider.of<PatientProvider>(context, listen: false);
                  patientProvider.addNote(
                      patientProvider.patients[0].id, newNote);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Note added')),
                  );
                });
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
