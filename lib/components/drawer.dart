import 'package:flutter/material.dart';
import 'package:notesapp/components/drawer_tile.dart';
import 'package:notesapp/pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // header
          DrawerHeader(
            child: Icon(
              Icons.bolt_rounded, 
              size: 48,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),

          const SizedBox(height: 25),

          // tasks tile
          DrawerTile(
            title: "T A S K S",
            leading: const Icon(Icons.check_circle_outline),
            onTap: () => Navigator.pop(context),
          ),

          // settings tile
          DrawerTile(
            title: "S E T T I N G S",
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
