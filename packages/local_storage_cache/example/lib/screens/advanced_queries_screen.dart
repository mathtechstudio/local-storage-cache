import 'package:flutter/material.dart';
import 'package:local_storage_cache_example/services/database_service.dart';

/// Screen demonstrating advanced query operations.
class AdvancedQueriesScreen extends StatefulWidget {
  /// Creates the advanced queries screen.
  const AdvancedQueriesScreen({super.key});

  @override
  State<AdvancedQueriesScreen> createState() => _AdvancedQueriesScreenState();
}

class _AdvancedQueriesScreenState extends State<AdvancedQueriesScreen> {
  List<Map<String, dynamic>> _results = [];
  String _currentQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSampleData();
  }

  Future<void> _initializeSampleData() async {
    try {
      final storage = await DatabaseService().storage;

      // Check if products exist
      final count = await storage.query('products').count();
      if (count == 0) {
        // Add sample products
        await storage.batchInsert(
          'products',
          [
            {
              'name': 'Laptop',
              'price': 1200,
              'stock': 10,
              'category': 'Electronics',
            },
            {
              'name': 'Mouse',
              'price': 25,
              'stock': 50,
              'category': 'Electronics',
            },
            {
              'name': 'Keyboard',
              'price': 75,
              'stock': 30,
              'category': 'Electronics',
            },
            {
              'name': 'Desk',
              'price': 300,
              'stock': 5,
              'category': 'Furniture',
            },
            {
              'name': 'Chair',
              'price': 150,
              'stock': 15,
              'category': 'Furniture',
            },
            {
              'name': 'Book',
              'price': 20,
              'stock': 100,
              'category': 'Books',
            },
          ],
        );
      }
    } catch (e) {
      debugPrint('Error initializing sample data: $e');
    }
  }

  Future<void> _runQuery(
    String queryName,
    Future<List<Map<String, dynamic>>> Function() query,
  ) async {
    setState(() {
      _isLoading = true;
      _currentQuery = queryName;
    });

    try {
      final results = await query();
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Query failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Queries'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Query Examples',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _runQuery(
                        'All Products',
                        () async {
                          final storage = await DatabaseService().storage;
                          return storage.query('products').get();
                        },
                      ),
                      child: const Text('All Products'),
                    ),
                    ElevatedButton(
                      onPressed: () => _runQuery(
                        'Price > 50',
                        () async {
                          final storage = await DatabaseService().storage;
                          final query = storage.query('products');
                          query.where('price', '>', 50);
                          return query.get();
                        },
                      ),
                      child: const Text('Price > 50'),
                    ),
                    ElevatedButton(
                      onPressed: () => _runQuery(
                        'Electronics',
                        () async {
                          final storage = await DatabaseService().storage;
                          final query = storage.query('products');
                          query.where('category', '=', 'Electronics');
                          return query.get();
                        },
                      ),
                      child: const Text('Electronics'),
                    ),
                    ElevatedButton(
                      onPressed: () => _runQuery(
                        'Low Stock',
                        () async {
                          final storage = await DatabaseService().storage;
                          final query = storage.query('products');
                          query.where('stock', '<', 20);
                          query.orderBy('stock');
                          return query.get();
                        },
                      ),
                      child: const Text('Low Stock'),
                    ),
                    ElevatedButton(
                      onPressed: () => _runQuery(
                        'Price Range',
                        () async {
                          final storage = await DatabaseService().storage;
                          final query = storage.query('products');
                          query.whereBetween('price', 20, 100);
                          return query.get();
                        },
                      ),
                      child: const Text('Price 20-100'),
                    ),
                    ElevatedButton(
                      onPressed: () => _runQuery(
                        'Multiple Categories',
                        () async {
                          final storage = await DatabaseService().storage;
                          final query = storage.query('products');
                          query.whereIn('category', ['Electronics', 'Books']);
                          return query.get();
                        },
                      ),
                      child: const Text('Electronics or Books'),
                    ),
                    ElevatedButton(
                      onPressed: () => _runQuery(
                        'Top 3 Expensive',
                        () async {
                          final storage = await DatabaseService().storage;
                          final query = storage.query('products');
                          query.orderBy('price', ascending: false);
                          query.limit = 3;
                          return query.get();
                        },
                      ),
                      child: const Text('Top 3 Expensive'),
                    ),
                    ElevatedButton(
                      onPressed: () => _runQuery(
                        'Complex Query',
                        () async {
                          final storage = await DatabaseService().storage;
                          final query = storage.query('products');
                          query.where('price', '>', 50);
                          query.where('stock', '>', 10);
                          query.orderBy('price');
                          query.limit = 5;
                          return query.get();
                        },
                      ),
                      child: const Text('Complex Query'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          if (_currentQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Results for: $_currentQuery',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Text('No results. Try running a query above!'),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final name = item['name'] as String?;
                          final category = item['category'] as String?;
                          final price = item['price'] as num?;
                          final stock = item['stock'] as int?;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              title: Text(name ?? 'N/A'),
                              subtitle: Text(
                                'Category: ${category ?? 'N/A'}\n'
                                'Price: \$${price?.toStringAsFixed(2) ?? '0.00'}\n'
                                'Stock: ${stock ?? 0}',
                              ),
                              isThreeLine: true,
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
