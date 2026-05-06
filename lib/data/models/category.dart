class AppCategory {
  final String id;
  final String userId;
  final String name;
  final String type; // 'income' | 'expense'
  final String icon;
  final String colorHex;
  final bool isDefault;
  final DateTime createdAt;

  const AppCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorHex,
    required this.isDefault,
    required this.createdAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String,
      colorHex: map['color_hex'] as String,
      isDefault: map['is_default'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'name': name,
      'type': type,
      'icon': icon,
      'color_hex': colorHex,
      'is_default': isDefault,
    };
  }
}
