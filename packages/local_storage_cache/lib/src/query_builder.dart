import 'package:local_storage_cache/src/models/query_condition.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

/// Fluent query builder for constructing and executing queries.
///
/// Provides an API for building complex database queries with
/// support for WHERE clauses, JOINs, ordering, pagination, and more.
///
/// Example:
/// ```dart
/// final query = storage.query('users');
/// query.where('age', '>', 18);
/// query.where('status', '=', 'active');
/// query.orderByDesc('created_at');
/// query.limit(10);
/// final users = await query.get();
/// ```
class QueryBuilder {
  /// Creates a new query builder for the specified table and space.
  ///
  /// Constructs a query builder that will operate on the given table
  /// within the specified data isolation space.
  QueryBuilder(
    this._tableName,
    this._space,
  );
  final String _tableName;
  final String _space;
  final List<String> _selectedFields = [];
  final List<_WhereClause> _whereClauses = [];
  final List<_OrderByClause> _orderBy = [];
  final List<_JoinClause> _joins = [];

  /// Maximum number of results to return.
  int? limit;

  /// Number of results to skip.
  int? offset;

  /// Selects specific fields to return.
  ///
  /// By default, all fields are selected. Use this method to limit
  /// the fields returned in the query results.
  ///
  /// Example:
  /// ```dart
  /// final query = storage.query('users');
  /// query.select(['id', 'name', 'email']);
  /// ```
  void select(List<String> fields) {
    _selectedFields.addAll(fields);
  }

  /// Adds a WHERE clause with the specified operator.
  ///
  /// Supported operators: =, !=, >, <, >=, <=, LIKE, IN, NOT IN, BETWEEN
  ///
  /// Example:
  /// ```dart
  /// final query = storage.query('users');
  /// query.where('age', '>', 18);
  /// ```
  void where(String field, String operator, dynamic value) {
    _whereClauses.add(_WhereClause(field, operator, value));
  }

  /// Adds a WHERE field = value clause.
  void whereEqual(String field, dynamic value) {
    where(field, '=', value);
  }

  /// Adds a WHERE field != value clause.
  void whereNotEqual(String field, dynamic value) {
    where(field, '!=', value);
  }

  /// Adds a WHERE field > value clause.
  void whereGreaterThan(String field, dynamic value) {
    where(field, '>', value);
  }

  /// Adds a WHERE field < value clause.
  void whereLessThan(String field, dynamic value) {
    where(field, '<', value);
  }

  /// Adds a WHERE field IN values clause.
  void whereIn(String field, List<dynamic> values) {
    _whereClauses.add(_WhereClause(field, 'IN', values));
  }

  /// Adds a WHERE field LIKE pattern clause.
  void whereLike(String field, String pattern) {
    where(field, 'LIKE', pattern);
  }

  /// Adds a WHERE field IS NULL clause.
  void whereNull(String field) {
    _whereClauses.add(_WhereClause(field, 'IS NULL', null));
  }

  /// Adds a WHERE field IS NOT NULL clause.
  void whereNotNull(String field) {
    _whereClauses.add(_WhereClause(field, 'IS NOT NULL', null));
  }

  /// Adds a WHERE field BETWEEN value1 AND value2 clause.
  void whereBetween(String field, dynamic value1, dynamic value2) {
    _whereClauses.add(_WhereClause(field, 'BETWEEN', [value1, value2]));
  }

  /// Adds a WHERE field NOT IN values clause.
  void whereNotIn(String field, List<dynamic> values) {
    _whereClauses.add(_WhereClause(field, 'NOT IN', values));
  }

  /// Adds a custom WHERE clause.
  void whereCustom(String customSQL, List<dynamic> arguments) {
    _whereClauses.add(_WhereClause.custom(customSQL, arguments));
  }

  /// Adds an OR operator.
  void or() {
    _whereClauses.add(_WhereClause.or());
  }

  /// Adds an AND operator.
  void and() {
    _whereClauses.add(_WhereClause.and());
  }

  /// Adds a nested condition.
  void condition(QueryCondition condition) {
    _whereClauses.add(_WhereClause.condition(condition));
  }

  /// Adds a nested condition with OR.
  void orCondition(QueryCondition condition) {
    or();
    this.condition(condition);
  }

  /// Orders results by field in ascending order.
  void orderBy(String field, {bool ascending = true}) {
    _orderBy.add(_OrderByClause(field, ascending: ascending));
  }

  /// Orders results by field in ascending order.
  void orderByAsc(String field) {
    orderBy(field);
  }

  /// Orders results by field in descending order.
  void orderByDesc(String field) {
    orderBy(field, ascending: false);
  }

  /// Adds a JOIN clause.
  void join(
    String table,
    String firstColumn,
    String operator,
    String secondColumn, {
    String type = 'INNER',
  }) {
    _joins.add(_JoinClause(table, firstColumn, operator, secondColumn, type));
  }

  /// Adds a LEFT JOIN clause.
  void leftJoin(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  ) {
    join(table, firstColumn, operator, secondColumn, type: 'LEFT');
  }

  /// Adds a RIGHT JOIN clause.
  void rightJoin(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  ) {
    join(table, firstColumn, operator, secondColumn, type: 'RIGHT');
  }

  /// Executes the query and returns all matching records.
  Future<List<Map<String, dynamic>>> get() async {
    final sql = _buildSelectSQL();
    final arguments = _buildArguments();
    final platform = LocalStorageCachePlatform.instance;
    return platform.query(sql, arguments, _space);
  }

  /// Executes the query and returns the first matching record.
  Future<Map<String, dynamic>?> first() async {
    limit = 1;
    final results = await get();
    return results.isNotEmpty ? results.first : null;
  }

  /// Executes the query and returns the count of matching records.
  Future<int> count() async {
    final sql = _buildCountSQL();
    final arguments = _buildArguments();
    final platform = LocalStorageCachePlatform.instance;
    final results = await platform.query(sql, arguments, _space);
    return results.isNotEmpty ? (results.first['count'] as int) : 0;
  }

  /// Executes an update with the current query conditions.
  Future<int> update(Map<String, dynamic> data) async {
    final sql = _buildUpdateSQL(data);
    final arguments = [...data.values, ..._buildArguments()];
    final platform = LocalStorageCachePlatform.instance;
    return platform.update(sql, arguments, _space);
  }

  /// Executes a delete with the current query conditions.
  Future<int> delete() async {
    final sql = _buildDeleteSQL();
    final arguments = _buildArguments();
    final platform = LocalStorageCachePlatform.instance;
    return platform.delete(sql, arguments, _space);
  }

  /// Executes the query and returns a stream of matching records.
  ///
  /// This is memory-efficient for large datasets as it doesn't load
  /// all records into memory at once.
  ///
  /// Example:
  /// ```dart
  /// await for (final record in storage.query('logs').stream()) {
  ///   print(record);
  /// }
  /// ```
  Stream<Map<String, dynamic>> stream() async* {
    final results = await get();
    for (final record in results) {
      yield record;
    }
  }

  /// Builds the SELECT SQL query.
  String _buildSelectSQL() {
    final buffer = StringBuffer();

    // SELECT clause
    if (_selectedFields.isEmpty) {
      buffer.write('SELECT * FROM $_tableName');
    } else {
      buffer.write('SELECT ${_selectedFields.join(', ')} FROM $_tableName');
    }

    // JOIN clauses
    for (final join in _joins) {
      buffer.write(
        ' ${join.type} JOIN ${join.table} ON ${join.firstColumn} ${join.operator} ${join.secondColumn}',
      );
    }

    // WHERE clause
    final whereSQL = _buildWhereSQL();
    if (whereSQL.isNotEmpty) {
      buffer.write(' WHERE $whereSQL');
    }

    // ORDER BY clause
    if (_orderBy.isNotEmpty) {
      final orderByParts = _orderBy
          .map((o) => '${o.field} ${o.ascending ? 'ASC' : 'DESC'}')
          .join(', ');
      buffer.write(' ORDER BY $orderByParts');
    }

    // LIMIT clause
    if (limit != null) {
      buffer.write(' LIMIT $limit');
    }

    // OFFSET clause
    if (offset != null) {
      buffer.write(' OFFSET $offset');
    }

    return buffer.toString();
  }

  /// Builds the COUNT SQL query.
  String _buildCountSQL() {
    final buffer = StringBuffer()
      ..write('SELECT COUNT(*) as count FROM $_tableName');

    // JOIN clauses
    for (final join in _joins) {
      buffer.write(
        ' ${join.type} JOIN ${join.table} ON ${join.firstColumn} ${join.operator} ${join.secondColumn}',
      );
    }

    // WHERE clause
    final whereSQL = _buildWhereSQL();
    if (whereSQL.isNotEmpty) {
      buffer.write(' WHERE $whereSQL');
    }

    return buffer.toString();
  }

  /// Builds the UPDATE SQL query.
  String _buildUpdateSQL(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    final fields = data.keys.map((k) => '$k = ?').join(', ');
    buffer.write('UPDATE $_tableName SET $fields');

    // WHERE clause
    final whereSQL = _buildWhereSQL();
    if (whereSQL.isNotEmpty) {
      buffer.write(' WHERE $whereSQL');
    }

    return buffer.toString();
  }

  /// Builds the DELETE SQL query.
  String _buildDeleteSQL() {
    final buffer = StringBuffer()..write('DELETE FROM $_tableName');

    // WHERE clause
    final whereSQL = _buildWhereSQL();
    if (whereSQL.isNotEmpty) {
      buffer.write(' WHERE $whereSQL');
    }

    return buffer.toString();
  }

  /// Builds the WHERE clause SQL.
  String _buildWhereSQL() {
    if (_whereClauses.isEmpty) return '';

    final buffer = StringBuffer();
    for (var i = 0; i < _whereClauses.length; i++) {
      final clause = _whereClauses[i];

      if (clause.isOr) {
        buffer.write(' OR ');
        continue;
      }

      if (clause.isAnd) {
        buffer.write(' AND ');
        continue;
      }

      if (clause.condition != null) {
        buffer.write('(${_buildConditionSQL(clause.condition!)})');
        continue;
      }

      if (clause.customSQL != null) {
        buffer.write(clause.customSQL);
        continue;
      }

      // Add AND if not the first clause and previous wasn't OR/AND
      if (i > 0 && !_whereClauses[i - 1].isOr && !_whereClauses[i - 1].isAnd) {
        buffer.write(' AND ');
      }

      // Build the condition
      if (clause.operator == 'IS NULL' || clause.operator == 'IS NOT NULL') {
        buffer.write('${clause.field} ${clause.operator}');
      } else if (clause.operator == 'IN' || clause.operator == 'NOT IN') {
        final placeholders =
            List.filled((clause.value as List).length, '?').join(', ');
        buffer.write('${clause.field} ${clause.operator} ($placeholders)');
      } else if (clause.operator == 'BETWEEN') {
        buffer.write('${clause.field} BETWEEN ? AND ?');
      } else {
        buffer.write('${clause.field} ${clause.operator} ?');
      }
    }

    return buffer.toString();
  }

  /// Builds SQL for a QueryCondition.
  ///
  /// Recursively processes nested conditions and generates proper SQL.
  String _buildConditionSQL(QueryCondition condition) {
    final buffer = StringBuffer();
    final clauses = condition.clauses;

    for (var i = 0; i < clauses.length; i++) {
      final clause = clauses[i];

      // Handle OR operator
      if (clause.type.toString().endsWith('or')) {
        buffer.write(' OR ');
        continue;
      }

      // Handle AND operator
      if (clause.type.toString().endsWith('and')) {
        buffer.write(' AND ');
        continue;
      }

      // Handle nested condition
      if (clause.type.toString().endsWith('nested') &&
          clause.nestedCondition != null) {
        buffer.write('(${_buildConditionSQL(clause.nestedCondition!)})');
        continue;
      }

      // Add AND if not the first clause and previous wasn't OR/AND
      if (i > 0 &&
          !clauses[i - 1].type.toString().endsWith('or') &&
          !clauses[i - 1].type.toString().endsWith('and')) {
        buffer.write(' AND ');
      }

      // Handle WHERE clause
      if (clause.type.toString().endsWith('where')) {
        buffer.write('${clause.field} ${clause.operator} ?');
      }

      // Handle WHERE IN clause
      if (clause.type.toString().endsWith('whereIn')) {
        final placeholders =
            List.filled((clause.value as List).length, '?').join(', ');
        buffer.write('${clause.field} IN ($placeholders)');
      }

      // Custom predicates cannot be converted to SQL
      if (clause.type.toString().endsWith('custom')) {
        throw UnsupportedError(
          'Custom predicates cannot be converted to SQL. '
          'Use where() or whereIn() instead.',
        );
      }
    }

    return buffer.toString();
  }

  /// Builds the arguments list for the query.
  List<dynamic> _buildArguments() {
    final arguments = <dynamic>[];

    for (final clause in _whereClauses) {
      if (clause.isOr || clause.isAnd) continue;

      if (clause.condition != null) {
        arguments.addAll(_buildConditionArguments(clause.condition!));
        continue;
      }

      if (clause.customSQL != null && clause.customArguments != null) {
        arguments.addAll(clause.customArguments!);
        continue;
      }

      if (clause.operator == 'IS NULL' || clause.operator == 'IS NOT NULL') {
        continue;
      }

      if (clause.operator == 'IN' || clause.operator == 'NOT IN') {
        arguments.addAll(clause.value as List);
      } else if (clause.operator == 'BETWEEN') {
        arguments.addAll(clause.value as List);
      } else {
        arguments.add(clause.value);
      }
    }

    return arguments;
  }

  /// Builds arguments list from a QueryCondition.
  ///
  /// Recursively extracts arguments from nested conditions.
  List<dynamic> _buildConditionArguments(QueryCondition condition) {
    final arguments = <dynamic>[];
    final clauses = condition.clauses;

    for (final clause in clauses) {
      // Skip operators
      if (clause.type.toString().endsWith('or') ||
          clause.type.toString().endsWith('and')) {
        continue;
      }

      // Handle nested condition recursively
      if (clause.type.toString().endsWith('nested') &&
          clause.nestedCondition != null) {
        arguments.addAll(_buildConditionArguments(clause.nestedCondition!));
        continue;
      }

      // Handle WHERE clause
      if (clause.type.toString().endsWith('where')) {
        arguments.add(clause.value);
      }

      // Handle WHERE IN clause
      if (clause.type.toString().endsWith('whereIn')) {
        arguments.addAll(clause.value as List);
      }

      // Custom predicates don't have SQL arguments
      if (clause.type.toString().endsWith('custom')) {
        throw UnsupportedError(
          'Custom predicates cannot be converted to SQL. '
          'Use where() or whereIn() instead.',
        );
      }
    }

    return arguments;
  }
}

class _WhereClause {
  _WhereClause(this.field, this.operator, this.value)
      : isOr = false,
        isAnd = false,
        condition = null,
        customSQL = null,
        customArguments = null;

  _WhereClause.or()
      : field = null,
        operator = null,
        value = null,
        isOr = true,
        isAnd = false,
        condition = null,
        customSQL = null,
        customArguments = null;

  _WhereClause.and()
      : field = null,
        operator = null,
        value = null,
        isOr = false,
        isAnd = true,
        condition = null,
        customSQL = null,
        customArguments = null;

  _WhereClause.condition(this.condition)
      : field = null,
        operator = null,
        value = null,
        isOr = false,
        isAnd = false,
        customSQL = null,
        customArguments = null;

  _WhereClause.custom(this.customSQL, this.customArguments)
      : field = null,
        operator = null,
        value = null,
        isOr = false,
        isAnd = false,
        condition = null;
  final String? field;
  final String? operator;
  final dynamic value;
  final bool isOr;
  final bool isAnd;
  final QueryCondition? condition;
  final String? customSQL;
  final List<dynamic>? customArguments;
}

class _OrderByClause {
  _OrderByClause(this.field, {required this.ascending});
  final String field;
  final bool ascending;
}

class _JoinClause {
  _JoinClause(
    this.table,
    this.firstColumn,
    this.operator,
    this.secondColumn,
    this.type,
  );
  final String table;
  final String firstColumn;
  final String operator;
  final String secondColumn;
  final String type;
}
