import 'package:flutter/material.dart';
import 'package:local_storage_cache_example/screens/advanced_queries_screen.dart';
import 'package:local_storage_cache_example/screens/backup_restore_screen.dart';
import 'package:local_storage_cache_example/screens/encryption_screen.dart';
import 'package:local_storage_cache_example/screens/home_screen.dart';
import 'package:local_storage_cache_example/screens/multi_space_screen.dart';
import 'package:local_storage_cache_example/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService().storage;

  runApp(const MyApp());
}

/// Main application widget.
class MyApp extends StatelessWidget {
  /// Creates the main application widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Storage Cache Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

/// Main screen with bottom navigation.
class MainScreen extends StatefulWidget {
  /// Creates the main screen.
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AdvancedQueriesScreen(),
    MultiSpaceScreen(),
    EncryptionScreen(),
    BackupRestoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Basic',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Queries',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers),
            label: 'Spaces',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock),
            label: 'Encryption',
          ),
          NavigationDestination(
            icon: Icon(Icons.backup),
            label: 'Backup',
          ),
        ],
      ),
    );
  }
}
