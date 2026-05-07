import 'dart:convert';
import 'package:intl/intl.dart';

class AudioRecording {
  final String path;
  final DateTime timestamp;
  final int durationMs;

  AudioRecording({
    required this.path, 
    required this.timestamp,
    this.durationMs = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': durationMs,
    };
  }

  factory AudioRecording.fromMap(Map<String, dynamic> map) {
    return AudioRecording(
      path: map['path']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      durationMs: map['durationMs'] is int ? map['durationMs'] : 0,
    );
  }

  String get formattedTimestamp => DateFormat('MMM d, h:mm a').format(timestamp);

  String get formattedDuration {
    final seconds = (durationMs / 1000).round();
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}m';
      }
      return '${minutes}m ${remainingSeconds}s';
    }
  }
}

class Task {
  int id;
  String title;
  String content;
  DateTime timestamp;
  List<String> imagePaths;
  List<AudioRecording> audioRecordings;
  bool isCompleted;
  int priority; // 0: Low, 1: Medium, 2: High
  DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.imagePaths = const [],
    this.audioRecordings = const [],
    this.isCompleted = false,
    this.priority = 0,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'imagePaths': jsonEncode(imagePaths),
      'audioPaths': jsonEncode(audioRecordings.map((r) => r.toMap()).toList()),
      'isCompleted': isCompleted ? 1 : 0,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    dynamic decode(String key) {
      final val = map[key];
      if (val == null || val is! String || val.isEmpty) return [];
      try {
        return jsonDecode(val);
      } catch (e) {
        return [];
      }
    }

    final rawImages = decode('imagePaths');
    final rawAudio = decode('audioPaths');

    return Task(
      id: map['id'] is int ? map['id'] : 0,
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ?? DateTime.now(),
      imagePaths: (rawImages is List) ? rawImages.map((e) => e.toString()).toList() : [],
      audioRecordings: (rawAudio is List) ? rawAudio.map((item) {
        if (item is Map) {
          return AudioRecording.fromMap(Map<String, dynamic>.from(item));
        } else {
          return AudioRecording(path: item.toString(), timestamp: DateTime.now());
        }
      }).toList() : [],
      isCompleted: (map['isCompleted'] == 1),
      priority: map['priority'] is int ? map['priority'] : 0,
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate'].toString()) : null,
    );
  }

  String get formattedTimestamp => DateFormat('MMM d, yyyy • h:mm a').format(timestamp);
  
  String get formattedDueDate {
    if (dueDate == null) return '';
    return DateFormat('MMM d, h:mm a').format(dueDate!);
  }
}
