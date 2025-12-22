import 'package:meta/meta.dart';

@immutable
class ExpenseCategory {
  const ExpenseCategory({
    this.id,
    required this.name,
    this.description,
  });

  final String? id;
  final String name;
  final String? description;

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? description,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseCategory &&
        other.id == id &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(id, name, description);
}
