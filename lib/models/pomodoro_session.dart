import 'package:hive/hive.dart';

part 'pomodoro_session.g.dart';

@HiveType(typeId: 0)
class PomodoroSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime startTime;

  @HiveField(2)
  final DateTime? endTime;

  @HiveField(3)
  final SessionType type;

  @HiveField(4)
  final bool completed;

  @HiveField(5)
  final int durationSeconds;

  @HiveField(6)
  final String? note;

  PomodoroSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.type,
    required this.completed,
    required this.durationSeconds,
    this.note,
  });

  // Computed — don't rely on stored durationSeconds for elapsed time
  Duration get duration => Duration(seconds: durationSeconds);

  // Consistency helper
  bool get isConsistent => completed == (endTime != null);
}

@HiveType(typeId: 1)
enum SessionType {
  @HiveField(0)
  focus,

  @HiveField(1)
  shortBreak,

  @HiveField(2)
  longBreak,
}

extension SessionTypeExtension on SessionType {
  // Renamed from 'name' to avoid shadowing Dart's built-in enum .name getter
  String get displayName {
    switch (this) {
      case SessionType.focus:
        return 'Focus';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  String get emoji {
    switch (this) {
      case SessionType.focus:
        return '🍅';
      case SessionType.shortBreak:
        return '☕';
      case SessionType.longBreak:
        return '🌿'; // Fixed: was 🎯 which looks like another focus icon
    }
  }

  int get defaultDuration {
    switch (this) {
      case SessionType.focus:
        return 25 * 60;
      case SessionType.shortBreak:
        return 5 * 60;
      case SessionType.longBreak:
        return 15 * 60;
    }
  }
}
