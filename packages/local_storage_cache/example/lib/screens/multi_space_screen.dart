import 'package:flutter/material.dart';
import 'package:local_storage_cache_example/services/database_service.dart';

/// Screen demonstrating multi-space architecture.
class MultiSpaceScreen extends StatefulWidget {
  /// Creates the multi-space screen.
  const MultiSpaceScreen({super.key});

  @override
  State<MultiSpaceScreen> createState() => _MultiSpaceScreenState();
}

class _MultiSpaceScreenState extends State<MultiSpaceScreen> {
  String _currentSpace = 'user_1';
  List<Map<String, dynamic>> _spaceData = [];
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSpaceData();
  }

  Future<void> _switchSpace(String spaceName) async {
    setState(() => _isLoading = true);
    try {
      final storage = await DatabaseService().storage;
      await storage.switchSpace(spaceName: spaceName);
      setState(() {
        _currentSpace = spaceName;
      });
      await _loadSpaceData();
      _showSuccess('Switched to $spaceName');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to switch space: $e');
    }
  }

  Future<void> _loadSpaceData() async {
    setState(() => _isLoading = true);
    try {
      final storage = await DatabaseService().storage;

      // Create a simple key-value table for demonstration
      await storage.setValue('_table_created', 'true');

      final data = await storage.query('settings').get();
      setState(() {
        _spaceData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load data: $e');
    }
  }

  Future<void> _addData() async {
    if (_keyController.text.isEmpty || _valueController.text.isEmpty) {
      _showError('Key and value are required');
      return;
    }

    try {
      final storage = await DatabaseService().storage;
      await storage.insert(
        'settings',
        {
          'key': _keyController.text,
          'value': _valueController.text,
        },
      );

      _keyController.clear();
      _valueController.clear();

      _showSuccess('Data added to $_currentSpace');
      await _loadSpaceData();
    } catch (e) {
      _showError('Failed to add data: $e');
    }
  }

  Future<void> _deleteData(String key) async {
    try {
      final storage = await DatabaseService().storage;
      final query = storage.query('settings');
      query.where('key', '=', key);
      await query.delete();
      _showSuccess('Data deleted');
      await _loadSpaceData();
    } catch (e) {
      _showError('Failed to delete data: $e');
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
        title: const Text('Multi-Space Architecture'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Current Space',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _currentSpace,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Switch Space',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _switchSpace('user_1'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentSpace == 'user_1' ? Colors.blue : null,
                      ),
                      child: const Text('User 1'),
                    ),
                    ElevatedButton(
                      onPressed: () => _switchSpace('user_2'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentSpace == 'user_2' ? Colors.blue : null,
                      ),
                      child: const Text('User 2'),
                    ),
                    ElevatedButton(
                      onPressed: () => _switchSpace('user_3'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentSpace == 'user_3' ? Colors.blue : null,
                      ),
                      child: const Text('User 3'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Add Data to Current Space',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _keyController,
                  decoration: const InputDecoration(
                    labelText: 'Key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _valueController,
                  decoration: const InputDecoration(
                    labelText: 'Value',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addData,
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Current Space'),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Data in $_currentSpace',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _spaceData.isEmpty
                    ? const Center(
                        child: Text('No data in this space. Add some above!'),
                      )
                    : ListView.builder(
                        itemCount: _spaceData.length,
                        itemBuilder: (context, index) {
                          final item = _spaceData[index];
                          final key = item['key'] as String? ?? '';
                          final value = item['value'] as String? ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              title: Text(key),
                              subtitle: Text(value),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _deleteData(key),
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

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}
