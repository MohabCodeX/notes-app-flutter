import 'package:flutter/material.dart';
import 'package:notesapp/database/task_database.dart';
import 'package:notesapp/pages/tasks_page.dart';
import 'package:notesapp/theme/theme_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  // initialize task database
  WidgetsFlutterBinding.ensureInitialized();
  await TaskDatabase.initialize();

  runApp(
    MultiProvider(
      providers: [
        // Task Provider
        ChangeNotifierProvider(create: (context) => TaskDatabase()..fetchTasks()),

        // Theme Provider
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Momentum',
      home: const TasksPage(),
      theme: Provider.of<ThemeProvider>(context).themeData,
    );
  }
}
