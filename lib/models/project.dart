import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'project.g.dart';

@HiveType(typeId: 2)
class Project {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? subject;

  @HiveField(4)
  String priority;

  @HiveField(5)
  String status;

  @HiveField(6)
  String? deadline;

  @HiveField(7)
  int progress;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  String type;

  @HiveField(10)
  String createdAt;

  Project({
    String? id,
    required this.title,
    this.description,
    this.subject,
    this.priority = 'medium',
    this.status = 'notstarted',
    this.deadline,
    this.progress = 0,
    this.notes,
    required this.type,
    String? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().toIso8601String();

  // Add this method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'priority': priority,
      'status': status,
      'deadline': deadline,
      'progress': progress,
      'notes': notes,
      'type': type,
      'createdAt': createdAt,
    };
  }

  // Add this factory constructor for JSON deserialization
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'notstarted',
      deadline: json['deadline'] as String?,
      progress: json['progress'] as int? ?? 0,
      notes: json['notes'] as String?,
      type: json['type'] as String? ?? 'project',
      createdAt: json['createdAt'] as String?,
    );
  }
}