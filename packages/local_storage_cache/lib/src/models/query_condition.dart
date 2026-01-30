/// Represents a query condition that can be nested.
class QueryCondition {
  final List<ConditionClause> _clauses = [];

  /// Adds a WHERE clause.
  void where(String field, String operator, dynamic value) {
    _clauses.add(
      ConditionClause(
        type: ClauseType.where,
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
      ConditionClause(
        type: ClauseType.whereIn,
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
      ConditionClause(
        type: ClauseType.custom,
        customPredicate: predicate,
      ),
    );
  }

  /// Adds an OR operator.
  void or() {
    _clauses.add(ConditionClause(type: ClauseType.or));
  }

  /// Adds an AND operator.
  void and() {
    _clauses.add(ConditionClause(type: ClauseType.and));
  }

  /// Adds a nested condition.
  void condition(QueryCondition condition) {
    _clauses.add(
      ConditionClause(
        type: ClauseType.nested,
        nestedCondition: condition,
      ),
    );
  }

  /// Adds a nested condition with OR.
  void orCondition(QueryCondition condition) {
    or();
    this.condition(condition);
  }

  /// Gets the list of clauses for SQL generation.
  List<ConditionClause> get clauses => _clauses;
}

/// Type of clause in a query condition.
enum ClauseType {
  /// A WHERE clause with field, operator, and value.
  where,

  /// A WHERE IN clause with field and list of values.
  whereIn,

  /// A custom predicate clause.
  custom,

  /// An OR logical operator.
  or,

  /// An AND logical operator.
  and,

  /// A nested condition clause.
  nested,
}

/// Represents a clause in a query condition.
class ConditionClause {
  /// Creates a condition clause.
  ConditionClause({
    required this.type,
    this.field,
    this.operator,
    this.value,
    this.customPredicate,
    this.nestedCondition,
  });

  /// The type of clause.
  final ClauseType type;

  /// The field name for WHERE clauses.
  final String? field;

  /// The operator for WHERE clauses.
  final String? operator;

  /// The value for WHERE clauses.
  final dynamic value;

  /// Custom predicate function for custom clauses.
  final bool Function(Map<String, dynamic>)? customPredicate;

  /// Nested condition for nested clauses.
  final QueryCondition? nestedCondition;
}
