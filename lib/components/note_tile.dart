import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notesapp/components/highlighted_text.dart';
import 'package:notesapp/database/note_database.dart';
import 'package:notesapp/models/note.dart';
import 'package:provider/provider.dart';

class NoteTile extends StatelessWidget {
  final Note note;
  final void Function()? onTap;
  final void Function()? onDeletePressed;

  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final searchQuery = context.watch<NoteDatabase>().searchQuery;

    return Container(
      margin: const EdgeInsets.only(top: 15, left: 25, right: 25),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE & MENU
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: HighlightedText(
                      text: note.title.isEmpty ? 'Untitled' : note.title,
                      highlight: searchQuery,
                      maxLines: 1,
                      style: GoogleFonts.dmSerifText(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                      highlightStyle: GoogleFonts.dmSerifText(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.inversePrimary,
                        backgroundColor: Colors.yellow.withValues(alpha: 0.3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDeletePressed?.call();
                      } else if (value == 'edit') {
                        onTap?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // CONTENT SNIPPET
              if (note.content.isNotEmpty)
                HighlightedText(
                  text: note.content,
                  highlight: searchQuery,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                    height: 1.4,
                  ),
                  highlightStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.inversePrimary,
                    backgroundColor: Colors.yellow.withValues(alpha: 0.3),
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),

              const SizedBox(height: 15),

              // FOOTER: TIMESTAMP & MEDIA ICONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    note.formattedTimestamp,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  // Media Indicators
                  Row(
                    children: [
                      if (note.imagePaths.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.image_outlined,
                            size: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      if (note.audioRecordings.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.mic_none_outlined,
                            size: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
