import 'package:flutter/material.dart';
import 'package:notesapp/components/task_tile.dart';
import 'package:notesapp/database/task_database.dart';
import 'package:notesapp/pages/task_editor_page.dart';
import 'package:provider/provider.dart';

class TaskSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          context.read<TaskDatabase>().setSearchQuery('');
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        context.read<TaskDatabase>().setSearchQuery('');
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
      if (context.mounted) {
        context.read<TaskDatabase>().setSearchQuery(query);
      }
    });

    final taskDatabase = context.watch<TaskDatabase>();
    final results = taskDatabase.currentTasks;

    if (results.isEmpty) {
      return const Center(child: Text('No tasks found.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        return TaskTile(
          task: task,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskEditorPage(
                  task: task,
                  searchQuery: query,
                ),
              ),
            );
          },
          onDeletePressed: () {
            taskDatabase.deleteTask(task.id);
          },
        );
      },
    );
  }
}
