import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'pomodoro_session.g.dart';

@HiveType(typeId: 0)
class PomodoroSession {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String date;
  
  @HiveField(2)
  final String type; // focus, shortBreak, longBreak, stopwatch, countdown, candle, ice
  
  @HiveField(3)
  final int durationMinutes;
  
  @HiveField(4)
  final bool completed;
  
  @HiveField(5)
  final String? note;
  
  @HiveField(6)
  final DateTime startTime;  // ✅ CHANGED: String to DateTime
  
  @HiveField(7)
  final DateTime? endTime;   // ✅ CHANGED: String? to DateTime?
  
  @HiveField(8)
  final String? subject;
  
  @HiveField(9)
  final List<String> tags;
  
  @HiveField(10)
  final String? projectId;

  PomodoroSession({
    String? id,
    required this.date,
    required this.type,
    required this.durationMinutes,
    required this.completed,
    this.note,
    required this.startTime,
    this.endTime,
    this.subject,
    this.tags = const [],
    this.projectId,
  }) : id = id ?? const Uuid().v4();
}

@HiveType(typeId: 1)
enum SessionType {
  @HiveField(0)
  focus,
  @HiveField(1)
  shortBreak,
  @HiveField(2)
  longBreak,
  @HiveField(3)
  stopwatch,
  @HiveField(4)
  countdown,
  @HiveField(5)
  candle,
  @HiveField(6)
  ice,
}

extension SessionTypeExtension on SessionType {
  String get displayName {
    switch (this) {
      case SessionType.focus:
        return 'Focus';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
      case SessionType.stopwatch:
        return 'Stopwatch';
      case SessionType.countdown:
        return 'Countdown';
      case SessionType.candle:
        return 'Burning Candle';
      case SessionType.ice:
        return 'Melting Ice';
    }
  }

  String get emoji {
    switch (this) {
      case SessionType.focus:
        return '🍅';
      case SessionType.shortBreak:
        return '☕';
      case SessionType.longBreak:
        return '🌿';
      case SessionType.stopwatch:
        return '⏱️';
      case SessionType.countdown:
        return '⏳';
      case SessionType.candle:
        return '🕯️';
      case SessionType.ice:
        return '🧊';
    }
  }

  String get color {
    switch (this) {
      case SessionType.focus:
        return '#FF6B6B';
      case SessionType.shortBreak:
        return '#4ECDC4';
      case SessionType.longBreak:
        return '#A78BFA';
      case SessionType.stopwatch:
        return '#F59E0B';
      case SessionType.countdown:
        return '#EF4444';
      case SessionType.candle:
        return '#FF9F1C';
      case SessionType.ice:
        return '#4FC3F7';
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
      case SessionType.stopwatch:
        return 25 * 60;
      case SessionType.countdown:
        return 25 * 60;
      case SessionType.candle:
        return 25 * 60;
      case SessionType.ice:
        return 25 * 60;
    }
  }
}