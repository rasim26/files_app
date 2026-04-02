
import 'package:flutter/material.dart';
import 'package:files_app_flutter/screens/delete_screen.dart';
import 'package:files_app_flutter/screens/files_display.dart';
import 'package:files_app_flutter/screens/recovery_screen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int currentIndex = 0;

  final screens = [Filesdisplay(), DeleteScreen(), RecoveryScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: Theme.of(context).primaryColor.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: "My Files",
          ),
          NavigationDestination(
            icon: Icon(Icons.delete_outline),
            selectedIcon: Icon(Icons.delete),
            label: "Trash",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_backup_restore_outlined),
            selectedIcon: Icon(Icons.settings_backup_restore),
            label: "Recovered",
          ),
        ],
      ),
    );
  }
}
