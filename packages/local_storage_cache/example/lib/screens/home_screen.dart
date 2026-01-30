import 'package:flutter/material.dart';
import 'package:local_storage_cache_example/services/database_service.dart';

/// Screen demonstrating basic CRUD operations.
class HomeScreen extends StatefulWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _users = [];
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final storage = await DatabaseService().storage;
      final query = storage.query('users');
      query.orderBy('created_at', ascending: false);
      final users = await query.get();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load users: $e');
    }
  }

  Future<void> _addUser() async {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty) {
      _showError('Username and email are required');
      return;
    }

    try {
      final storage = await DatabaseService().storage;
      await storage.insert(
        'users',
        {
          'username': _usernameController.text,
          'email': _emailController.text,
          'age': _ageController.text.isEmpty
              ? null
              : int.parse(_ageController.text),
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      _usernameController.clear();
      _emailController.clear();
      _ageController.clear();

      _showSuccess('User added successfully');
      await _loadUsers();
    } catch (e) {
      _showError('Failed to add user: $e');
    }
  }

  Future<void> _updateUser(Map<String, dynamic> user) async {
    final username = user['username'] as String?;
    final email = user['email'] as String?;
    final age = user['age'];

    final usernameController = TextEditingController(text: username);
    final emailController = TextEditingController(text: email);
    final ageController = TextEditingController(text: age?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      try {
        final storage = await DatabaseService().storage;
        final query = storage.query('users');
        query.where('id', '=', user['id']);
        await query.update({
          'username': usernameController.text,
          'email': emailController.text,
          'age':
              ageController.text.isEmpty ? null : int.parse(ageController.text),
        });
        _showSuccess('User updated successfully');
        await _loadUsers();
      } catch (e) {
        _showError('Failed to update user: $e');
      }
    }
  }

  Future<void> _deleteUser(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
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

    if (confirmed ?? false) {
      try {
        final storage = await DatabaseService().storage;
        final query = storage.query('users');
        query.where('id', '=', id);
        await query.delete();
        _showSuccess('User deleted successfully');
        await _loadUsers();
      } catch (e) {
        _showError('Failed to delete user: $e');
      }
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
        title: const Text('Basic CRUD Operations'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add New User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addUser,
                      icon: const Icon(Icons.add),
                      label: const Text('Add User'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text('No users yet. Add one above!'),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final username = user['username'] as String? ?? '';
                          final email = user['email'] as String? ?? '';
                          final age = user['age'];
                          final id = user['id'] as int? ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  username.isNotEmpty
                                      ? username[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(username),
                              subtitle: Text(
                                '$email${age != null ? ' • Age: $age' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _updateUser(user),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteUser(id),
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

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
