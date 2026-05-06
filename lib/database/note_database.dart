import 'package:flutter/material.dart';
import 'package:notesapp/models/note.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class NoteDatabase with ChangeNotifier {
  static late Database database;

  // I N I T I A L I Z E
  static Future<void> initialize() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'notes_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, timestamp TEXT, imagePaths TEXT, audioPaths TEXT)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        // Migration logic for version 3+
      },
      version: 3,
    );
  }

  // list of notes
  final List<Note> _currentNotes = [];
  String _searchQuery = "";

  List<Note> get currentNotes {
    if (_searchQuery.isEmpty) {
      return _currentNotes;
    } else {
      return _currentNotes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // C R E A T E
  Future<void> addNote(String title, String content, {List<String> images = const [], List<AudioRecording> audio = const []}) async {
    await database.insert(
      'notes',
      Note(
        id: 0,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        imagePaths: images,
        audioRecordings: audio,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // re-read from db
    fetchNotes();
  }

  // R E A D
  Future<void> fetchNotes() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'notes',
      orderBy: 'timestamp DESC',
    );

    _currentNotes.clear();
    _currentNotes.addAll(List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    }));

    notifyListeners();
  }

  // U P D A T E
  Future<void> updateNote(int id, String newTitle, String newContent, {List<String>? images, List<AudioRecording>? audio}) async {
    await database.update(
      'notes',
      {
        'title': newTitle,
        'content': newContent,
        'timestamp': DateTime.now().toIso8601String(),
        if (images != null) 'imagePaths': Note(id: id, title: '', content: '', timestamp: DateTime.now(), imagePaths: images).toMap()['imagePaths'],
        if (audio != null) 'audioPaths': Note(id: id, title: '', content: '', timestamp: DateTime.now(), audioRecordings: audio).toMap()['audioPaths'],
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchNotes();
  }

  // D E L E T E
  Future<void> deleteNote(int id) async {
    await database.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchNotes();
  }
}
