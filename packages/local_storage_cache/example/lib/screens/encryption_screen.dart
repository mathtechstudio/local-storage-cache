import 'package:flutter/material.dart';
import 'package:local_storage_cache/local_storage_cache.dart';

/// Screen demonstrating encrypted storage.
class EncryptionScreen extends StatefulWidget {
  /// Creates the encryption screen.
  const EncryptionScreen({super.key});

  @override
  State<EncryptionScreen> createState() => _EncryptionScreenState();
}

class _EncryptionScreenState extends State<EncryptionScreen> {
  StorageEngine? _encryptedStorage;
  List<Map<String, dynamic>> _sensitiveData = [];
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeEncryptedStorage();
  }

  Future<void> _initializeEncryptedStorage() async {
    setState(() => _isLoading = true);
    try {
      _encryptedStorage = StorageEngine(
        config: const StorageConfig(
          databaseName: 'encrypted_example.db',
          encryption: EncryptionConfig(
            enabled: true,
            algorithm: EncryptionAlgorithm.aes256GCM,
            useSecureStorage: true,
          ),
        ),
        schemas: const [
          TableSchema(
            name: 'sensitive_data',
            fields: [
              FieldSchema(
                name: 'value',
                type: DataType.text,
                nullable: false,
                encrypted: true, // Field-level encryption
              ),
            ],
            primaryKeyConfig: PrimaryKeyConfig(
              name: 'key',
              type: PrimaryKeyType.uuid,
            ),
          ),
        ],
      );

      await _encryptedStorage!.initialize();
      setState(() => _isInitialized = true);
      await _loadData();
      _showSuccess('Encrypted storage initialized');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to initialize encrypted storage: $e');
    }
  }

  Future<void> _loadData() async {
    if (!_isInitialized) return;

    setState(() => _isLoading = true);
    try {
      final data = await _encryptedStorage!.query('sensitive_data').get();
      setState(() {
        _sensitiveData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load data: $e');
    }
  }

  Future<void> _addData() async {
    if (!_isInitialized) {
      _showError('Storage not initialized');
      return;
    }

    if (_keyController.text.isEmpty || _valueController.text.isEmpty) {
      _showError('Key and value are required');
      return;
    }

    try {
      await _encryptedStorage!.insert(
        'sensitive_data',
        {
          'key': _keyController.text,
          'value': _valueController.text,
        },
      );

      _keyController.clear();
      _valueController.clear();

      _showSuccess('Encrypted data added');
      await _loadData();
    } catch (e) {
      _showError('Failed to add data: $e');
    }
  }

  Future<void> _deleteData(String key) async {
    if (!_isInitialized) return;

    try {
      final query = _encryptedStorage!.query('sensitive_data');
      query.where('key', '=', key);
      await query.delete();
      _showSuccess('Data deleted');
      await _loadData();
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
        title: const Text('Encrypted Storage'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.green.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock,
                          size: 48,
                          color: Colors.green,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Encryption Enabled',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Algorithm: AES-256-GCM\nField-level encryption active',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Sensitive Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _keyController,
                  decoration: const InputDecoration(
                    labelText: 'Key (e.g., ssn, credit_card)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _valueController,
                  decoration: const InputDecoration(
                    labelText: 'Sensitive Value',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _addData : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Encrypted Data'),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Encrypted Data (values are encrypted at rest)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_isInitialized
                    ? const Center(
                        child: Text('Initializing encrypted storage...'),
                      )
                    : _sensitiveData.isEmpty
                        ? const Center(
                            child:
                                Text('No encrypted data yet. Add some above!'),
                          )
                        : ListView.builder(
                            itemCount: _sensitiveData.length,
                            itemBuilder: (context, index) {
                              final item = _sensitiveData[index];
                              final key = item['key'] as String?;
                              final value = item['value'] as String?;

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.lock,
                                    color: Colors.green,
                                  ),
                                  title: Text(key ?? 'N/A'),
                                  subtitle: Text(
                                    value ?? 'N/A',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deleteData(key ?? ''),
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
    _encryptedStorage?.close();
    super.dispose();
  }
}
