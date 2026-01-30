import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Screen demonstrating backup and restore operations.
class BackupRestoreScreen extends StatefulWidget {
  /// Creates the backup and restore screen.
  const BackupRestoreScreen({Key? key}) : super(key: key);

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isProcessing = false;
  String _status = '';
  List<String> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (await backupDir.exists()) {
        final files = await backupDir.list().toList();
        setState(() {
          _backupFiles = files
              .where((f) => f is File && f.path.endsWith('.db'))
              .map((f) => f.path.split('/').last)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading backup files: $e');
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isProcessing = true;
      _status = 'Creating backup...';
    });

    try {
      final storage = await DatabaseService().storage;
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'backup_$timestamp.db';
      final backupPath = '${backupDir.path}/$filename';

      // Use exportDatabase method
      await storage.exportDatabase(backupPath);

      setState(() {
        _isProcessing = false;
        _status = 'Backup created: $filename';
      });

      await _loadBackupFiles();
      _showSuccess('Backup created successfully');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Backup failed: $e';
      });
      _showError('Backup failed: $e');
    }
  }

  Future<void> _restoreBackup(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content:
            Text('Restore from $filename? This will replace existing data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _status = 'Restoring backup...';
    });

    try {
      final storage = await DatabaseService().storage;
      final directory = await getApplicationDocumentsDirectory();
      final backupPath = '${directory.path}/backups/$filename';

      // Use importDatabase method
      await storage.importDatabase(backupPath);

      setState(() {
        _isProcessing = false;
        _status = 'Restored from: $filename';
      });

      _showSuccess('Backup restored successfully');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = 'Restore failed: $e';
      });
      _showError('Restore failed: $e');
    }
  }

  Future<void> _deleteBackup(String filename) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text('Delete $filename?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/backups/$filename');
      await file.delete();
      await _loadBackupFiles();
      _showSuccess('Backup deleted');
    } catch (e) {
      _showError('Failed to delete backup: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Backup',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _createBackup,
                  icon: const Icon(Icons.backup),
                  label: const Text('Create Database Backup'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Creates a full copy of the database file',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_status.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: _status.contains('failed')
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('failed')
                              ? Colors.red.shade900
                              : Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Backups',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadBackupFiles,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : _backupFiles.isEmpty
                    ? const Center(
                        child: Text('No backups yet. Create one above!'),
                      )
                    : ListView.builder(
                        itemCount: _backupFiles.length,
                        itemBuilder: (context, index) {
                          final filename = _backupFiles[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.backup,
                                color: Colors.blue,
                              ),
                              title: Text(filename),
                              subtitle: const Text('Database backup'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.restore),
                                    color: Colors.orange,
                                    onPressed: () => _restoreBackup(filename),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteBackup(filename),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
