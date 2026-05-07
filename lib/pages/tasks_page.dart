import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notesapp/components/drawer.dart';
import 'package:notesapp/components/task_search_delegate.dart';
import 'package:notesapp/components/task_tile.dart';
import 'package:notesapp/database/task_database.dart';
import 'package:notesapp/models/task.dart';
import 'package:notesapp/pages/task_editor_page.dart';
import 'package:provider/provider.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  @override
  void initState() {
    super.initState();
    // read existing tasks on startup
    readTasks();
  }

  // read tasks
  void readTasks() {
    context.read<TaskDatabase>().fetchTasks();
  }

  // create a task
  void createTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskEditorPage()),
    );
  }

  // edit task
  void editTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditorPage(task: task),
      ),
    );
  }

  // delete task
  void deleteTask(int id) {
    context.read<TaskDatabase>().deleteTask(id);
  }

  @override
  Widget build(BuildContext context) {
    // task database
    final taskDatabase = context.watch<TaskDatabase>();

    // current tasks
    List<Task> currentTasks = taskDatabase.currentTasks;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      drawer: const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createTask,
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADING
          Padding(
            padding: const EdgeInsets.only(left: 25.0, top: 10, bottom: 20),
            child: Text(
              'Momentum',
              style: GoogleFonts.dmSerifText(
                fontSize: 48,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),

          // LIST OF TASKS
          Expanded(
            child: currentTasks.isEmpty 
              ? Center(
                  child: Text(
                    "No tasks yet. Get moving!",
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: currentTasks.length,
                  itemBuilder: (context, index) {
                    final task = currentTasks[index];
                    
                    // Show "Completed" header if this is the first completed task
                    bool showCompletedHeader = false;
                    if (task.isCompleted) {
                      if (index == 0 || !currentTasks[index - 1].isCompleted) {
                        showCompletedHeader = true;
                      }
                    }

                    // Show "Active" header if this is the first task and it's active
                    bool showActiveHeader = false;
                    if (!task.isCompleted && index == 0) {
                      showActiveHeader = true;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showActiveHeader)
                          const _SectionHeader(title: "Active Tasks"),
                        
                        if (showCompletedHeader)
                          const _SectionHeader(title: "Completed"),
                        
                        TaskTile(
                          task: task,
                          onTap: () => editTask(task),
                          onDeletePressed: () => deleteTask(task.id),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30.0, top: 20, bottom: 5),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
