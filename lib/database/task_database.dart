import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:notesapp/models/task.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TaskDatabase with ChangeNotifier {
  static late Database database;

  // I N I T I A L I Z E
  static Future<void> initialize() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'tasks_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, timestamp TEXT, imagePaths TEXT, audioPaths TEXT, isCompleted INTEGER DEFAULT 0, priority INTEGER DEFAULT 0, dueDate TEXT)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE tasks ADD COLUMN isCompleted INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE tasks ADD COLUMN priority INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE tasks ADD COLUMN dueDate TEXT');
        }
      },
      version: 4,
    );
  }

  // list of tasks
  final List<Task> _currentTasks = [];
  String _searchQuery = "";

  List<Task> get currentTasks {
    List<Task> tasks = _searchQuery.isEmpty
        ? _currentTasks
        : _currentTasks.where((task) {
            return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                   task.content.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
    
    // Sort logic: Incomplete first, then by priority (desc), then by timestamp (desc)
    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      return b.timestamp.compareTo(a.timestamp);
    });
    
    return tasks;
  }

  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // C R E A T E
  Future<void> addTask(String title, String content, {
    List<String> images = const [], 
    List<AudioRecording> audio = const [],
    int priority = 0,
    DateTime? dueDate,
  }) async {
    await database.insert(
      'tasks',
      Task(
        id: 0,
        title: title,
        content: content,
        timestamp: DateTime.now(),
        imagePaths: images,
        audioRecordings: audio,
        priority: priority,
        dueDate: dueDate,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    fetchTasks();
  }

  // R E A D
  Future<void> fetchTasks() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'tasks',
      orderBy: 'isCompleted ASC, priority DESC, timestamp DESC',
    );

    _currentTasks.clear();
    _currentTasks.addAll(List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    }));

    notifyListeners();
  }

  // U P D A T E
  Future<void> updateTask(int id, String newTitle, String newContent, {
    List<String>? images, 
    List<AudioRecording>? audio,
    bool? isCompleted,
    int? priority,
    DateTime? dueDate,
  }) async {
    Map<String, dynamic> updateData = {
      'title': newTitle,
      'content': newContent,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (images != null) updateData['imagePaths'] = jsonEncode(images);
    if (audio != null) updateData['audioPaths'] = jsonEncode(audio.map((r) => r.toMap()).toList());
    if (isCompleted != null) updateData['isCompleted'] = isCompleted ? 1 : 0;
    if (priority != null) updateData['priority'] = priority;
    if (dueDate != null) updateData['dueDate'] = dueDate.toIso8601String();

    await database.update(
      'tasks',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchTasks();
  }

  // Toggle Completion
  Future<void> toggleCompletion(Task task) async {
    await updateTask(task.id, task.title, task.content, isCompleted: !task.isCompleted);
  }

  // D E L E T E
  Future<void> deleteTask(int id) async {
    await database.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchTasks();
  }
}
