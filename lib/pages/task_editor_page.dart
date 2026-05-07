import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesapp/components/audio_player_widget.dart';
import 'package:notesapp/database/task_database.dart';
import 'package:notesapp/models/task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class TaskEditorPage extends StatefulWidget {
  final Task? task;
  final String? searchQuery;

  const TaskEditorPage({super.key, this.task, this.searchQuery});

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentScrollController = ScrollController();
  final List<String> _imagePaths = [];
  final List<AudioRecording> _audioRecordings = [];
  
  int _priority = 0; // 0: Low, 1: Medium, 2: High
  DateTime? _dueDate;

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  // Animation for fading highlight
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  bool _showHighlight = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _contentController.text = widget.task!.content;
      _imagePaths.addAll(widget.task!.imagePaths);
      _audioRecordings.addAll(widget.task!.audioRecordings);
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
    }

    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _highlightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeIn),
    );

    // Handle search query highlighting and scrolling
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleSearchHighlight());
    }
  }

  void _handleSearchHighlight() {
    final query = widget.searchQuery!.toLowerCase();
    final content = _contentController.text.toLowerCase();
    final index = content.indexOf(query);

    if (index != -1) {
      _contentController.selection = TextSelection(
        baseOffset: index,
        extentOffset: index + query.length,
      );

      setState(() => _showHighlight = true);
      
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _highlightController.forward().then((_) {
            if (mounted) {
              setState(() => _showHighlight = false);
              _contentController.selection = const TextSelection.collapsed(offset: 0);
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentScrollController.dispose();
    _audioRecorder.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isEmpty && content.isEmpty && _imagePaths.isEmpty && _audioRecordings.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.task == null) {
      context.read<TaskDatabase>().addTask(
        title, 
        content, 
        images: _imagePaths, 
        audio: _audioRecordings,
        priority: _priority,
        dueDate: _dueDate,
      );
    } else {
      context.read<TaskDatabase>().updateTask(
        widget.task!.id, 
        title, 
        content, 
        images: _imagePaths, 
        audio: _audioRecordings,
        priority: _priority,
        dueDate: _dueDate,
      );
    }

    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    
    if (image != null) {
      setState(() {
        _imagePaths.add(image.path);
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/${const Uuid().v4()}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordingStartTime = DateTime.now();
          });
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null && _recordingStartTime != null) {
      final duration = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
      if (mounted) {
        setState(() {
          _isRecording = false;
          _audioRecordings.add(AudioRecording(
            path: path, 
            timestamp: _recordingStartTime!,
            durationMs: duration,
          ));
          _recordingStartTime = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(onPressed: _takePhoto, icon: const Icon(Icons.camera_alt_outlined)),
          IconButton(onPressed: _pickImage, icon: const Icon(Icons.image_outlined)),
          IconButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic_none_outlined),
            color: _isRecording ? Colors.red : null,
          ),
          IconButton(
            onPressed: _saveTask,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _contentScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.dmSerifText(
                      fontSize: 32,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Task Title',
                      hintStyle: GoogleFonts.dmSerifText(
                        fontSize: 32,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      border: InputBorder.none,
                    ),
                    maxLines: 1,
                  ),

                  // PRIORITY & DUE DATE ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Priority",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _PriorityChip(
                                    label: "Low",
                                    isSelected: _priority == 0,
                                    color: Colors.blue,
                                    onTap: () => setState(() => _priority = 0),
                                  ),
                                  _PriorityChip(
                                    label: "Medium",
                                    isSelected: _priority == 1,
                                    color: Colors.orange,
                                    onTap: () => setState(() => _priority = 1),
                                  ),
                                  _PriorityChip(
                                    label: "High",
                                    isSelected: _priority == 2,
                                    color: Colors.red,
                                    onTap: () => setState(() => _priority = 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Due Date Button
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Deadline",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: _selectDueDate,
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.inversePrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              Icons.calendar_today_rounded, 
                              size: 16,
                              color: _dueDate != null ? Colors.blue : Theme.of(context).colorScheme.secondary,
                            ),
                            label: Text(
                              _dueDate == null ? "No deadline" : Task(id: 0, title: '', content: '', timestamp: DateTime.now(), dueDate: _dueDate).formattedDueDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.inversePrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // IMAGES
                  if (_imagePaths.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: FileImage(File(_imagePaths[index])),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 5,
                                right: 15,
                                child: GestureDetector(
                                  onTap: () => setState(() => _imagePaths.removeAt(index)),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 10),

                  // AUDIO
                  if (_audioRecordings.isNotEmpty)
                    Column(
                      children: _audioRecordings.asMap().entries.map((entry) {
                        return AudioPlayerWidget(
                          path: entry.value.path,
                          timestamp: entry.value.formattedTimestamp,
                          duration: entry.value.formattedDuration,
                          onDelete: () => setState(() => _audioRecordings.removeAt(entry.key)),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 10),

                  // CONTENT
                  Stack(
                    children: [
                      TextField(
                        controller: _contentController,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add details...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                      
                      // Highlight Overlay
                      if (_showHighlight)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: FadeTransition(
                              opacity: _highlightAnimation,
                              child: Container(
                                color: Colors.yellow.withValues(alpha: 0.3),
                              ),
                            ),
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
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
