/// Represents a query condition that can be nested.
class QueryCondition {
  final List<_ConditionClause> _clauses = [];

  /// Adds a WHERE clause.
  void where(String field, String operator, dynamic value) {
    _clauses.add(
      _ConditionClause(
        type: _ClauseType.where,
        field: field,
        operator: operator,
        value: value,
      ),
    );
  }

  /// Adds a WHERE field = value clause.
  void whereEqual(String field, dynamic value) {
    where(field, '=', value);
  }

  /// Adds a WHERE field IN values clause.
  void whereIn(String field, List<dynamic> values) {
    _clauses.add(
      _ConditionClause(
        type: _ClauseType.whereIn,
        field: field,
        value: values,
      ),
    );
  }

  /// Adds a custom condition function.
  void whereCustom(
    bool Function(Map<String, dynamic> record) predicate,
  ) {
    _clauses.add(
      _ConditionClause(
        type: _ClauseType.custom,
        customPredicate: predicate,
      ),
    );
  }

  /// Adds an OR operator.
  void or() {
    _clauses.add(_ConditionClause(type: _ClauseType.or));
  }

  /// Adds an AND operator.
  void and() {
    _clauses.add(_ConditionClause(type: _ClauseType.and));
  }

  /// Adds a nested condition.
  void condition(QueryCondition condition) {
    _clauses.add(
      _ConditionClause(
        type: _ClauseType.nested,
        nestedCondition: condition,
      ),
    );
  }

  /// Adds a nested condition with OR.
  void orCondition(QueryCondition condition) {
    or();
    this.condition(condition);
  }
}

enum _ClauseType { where, whereIn, custom, or, and, nested }

class _ConditionClause {
  _ConditionClause({
    required this.type,
    this.field,
    this.operator,
    this.value,
    this.customPredicate,
    this.nestedCondition,
  });
  final _ClauseType type;
  final String? field;
  final String? operator;
  final dynamic value;
  final bool Function(Map<String, dynamic>)? customPredicate;
  final QueryCondition? nestedCondition;
}
