import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 3)
class Achievement {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String icon;
  
  @HiveField(2)
  final String title;
  
  @HiveField(3)
  final String description;
  
  @HiveField(4)
  final String category;
  
  @HiveField(5)
  final int requiredValue;
  
  @HiveField(6)
  final bool unlocked;
  
  @HiveField(7)
  final String? unlockedAt;

  Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.category,
    required this.requiredValue,
    this.unlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? icon,
    String? title,
    String? description,
    String? category,
    int? requiredValue,
    bool? unlocked,
    String? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      requiredValue: requiredValue ?? this.requiredValue,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}