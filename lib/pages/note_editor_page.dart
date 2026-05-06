import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notesapp/components/audio_player_widget.dart';
import 'package:notesapp/database/note_database.dart';
import 'package:notesapp/models/note.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class NoteEditorPage extends StatefulWidget {
  final Note? note;
  final String? searchQuery;

  const NoteEditorPage({super.key, this.note, this.searchQuery});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _contentScrollController = ScrollController();
  final List<String> _imagePaths = [];
  final List<AudioRecording> _audioRecordings = [];
  
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
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _imagePaths.addAll(widget.note!.imagePaths);
      _audioRecordings.addAll(widget.note!.audioRecordings);
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
      // 1. Highlight the text (using selection as a temporary visual cue)
      _contentController.selection = TextSelection(
        baseOffset: index,
        extentOffset: index + query.length,
      );

      // 2. Start the fade animation
      setState(() => _showHighlight = true);
      
      // Delay before starting fade
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _highlightController.forward().then((_) {
            if (mounted) {
              setState(() => _showHighlight = false);
              // Clear selection after fade
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

  void _saveNote() {
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isEmpty && content.isEmpty && _imagePaths.isEmpty && _audioRecordings.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (widget.note == null) {
      context.read<NoteDatabase>().addNote(title, content, images: _imagePaths, audio: _audioRecordings);
    } else {
      context.read<NoteDatabase>().updateNote(widget.note!.id, title, content, images: _imagePaths, audio: _audioRecordings);
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

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/${const Uuid().v4()}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordingStartTime = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null && _recordingStartTime != null) {
      final duration = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
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
            onPressed: _saveNote,
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
                children: [
                  // TITLE
                  TextField(
                    controller: _titleController,
                    style: GoogleFonts.dmSerifText(
                      fontSize: 32,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: GoogleFonts.dmSerifText(
                        fontSize: 32,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      border: InputBorder.none,
                    ),
                    maxLines: 1,
                  ),

                  const SizedBox(height: 10),

                  // IMAGES
                  if (_imagePaths.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 150,
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
                          hintText: 'Start typing...',
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                      ),
                      
                      // Highlight Overlay (simple selection-based for now as it handles scrolling automatically)
                      if (_showHighlight)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: FadeTransition(
                              opacity: _highlightAnimation,
                              child: Container(
                                // This is a subtle indicator, since actual text-range background 
                                // inside a TextField is complex, we use the selection color
                                // which Flutter's TextField handles natively for scrolling to.
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
