import 'package:flutter/material.dart';
import 'package:notesapp/components/note_tile.dart';
import 'package:notesapp/database/note_database.dart';
import 'package:notesapp/pages/note_editor_page.dart';
import 'package:provider/provider.dart';

class NoteSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          context.read<NoteDatabase>().setSearchQuery('');
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        context.read<NoteDatabase>().setSearchQuery('');
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    // Update the search query in the database to trigger highlighting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteDatabase>().setSearchQuery(query);
    });

    final noteDatabase = context.watch<NoteDatabase>();
    final results = noteDatabase.currentNotes;

    if (results.isEmpty) {
      return const Center(child: Text('No notes found.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return NoteTile(
          note: note,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorPage(
                  note: note,
                  searchQuery: query,
                ),
              ),
            );
          },
          onDeletePressed: () {
            noteDatabase.deleteNote(note.id);
          },
        );
      },
    );
  }
}
