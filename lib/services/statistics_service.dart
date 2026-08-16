import '../models/pomodoro_session.dart';
import 'storage_service.dart';

class StatisticsService {
  static Map<String, dynamic> getTodayStats() {
    final sessions = StorageService.getTodaySessions();
    return _summarize(sessions);
  }

  static Map<String, dynamic> getWeekStats() {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final sessions = StorageService.getSessionsInRange(weekStart, weekEnd);
    final summary = _summarize(sessions);
    final focusCount = summary['focusSessions'] as int;
    summary['dailyAverage'] = focusCount > 0 ? (focusCount / 7) : 0.0;
    return summary;
  }

  static Map<String, dynamic> getMonthStats() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final sessions = StorageService.getSessionsInRange(monthStart, monthEnd);
    final summary = _summarize(sessions);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final focusCount = summary['focusSessions'] as int;
    summary['dailyAverage'] = focusCount > 0 ? (focusCount / daysInMonth) : 0.0;
    return summary;
  }

  static Map<String, dynamic> getYearStats() {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year + 1, 1, 1);
    final sessions = StorageService.getSessionsInRange(yearStart, yearEnd);
    return _summarize(sessions);
  }

  static Map<String, dynamic> getTotalStats() {
    final sessions = StorageService.getAllSessions();
    final summary = _summarize(sessions);
    final totalSecs = (summary['totalFocusSeconds'] as int);
    summary['totalFocusHours'] = (totalSecs / 3600);
    return summary;
  }

  static int getStreak() {
    final sessions = StorageService.getAllSessions();
    final focusSessions = sessions.where((s) => s.type == SessionType.focus && s.completed).toList();
    if (focusSessions.isEmpty) return 0;
    
    final days = focusSessions.map((s) => _dateKey(s.startTime)).toSet().toList();
    days.sort((a, b) => b.compareTo(a));
    
    if (days.isEmpty) return 0;
    
    int streak = 0;
    DateTime current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);
    
    for (final day in days) {
      final parts = day.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final diff = current.difference(date).inDays;
      if (diff <= 1) {
        streak++;
        current = date;
      } else {
        break;
      }
    }
    return streak;
  }

  static int getYearTotalMinutes() {
    final sessions = StorageService.getAllSessions();
    final now = DateTime.now();
    return sessions
        .where((s) => s.startTime.year == now.year && s.type == SessionType.focus && s.completed)
        .fold<int>(0, (sum, s) => sum + (s.durationSeconds ~/ 60));
  }

  static List<Map<String, dynamic>> getLast7DaysData() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final sessions = StorageService.getSessionsInRange(dayStart, dayEnd);
      final focusCount = sessions
          .where((s) => s.type == SessionType.focus && s.completed)
          .length;
      final totalMins = sessions
          .where((s) => s.type == SessionType.focus && s.completed)
          .fold<int>(0, (sum, s) => sum + (s.durationSeconds ~/ 60));
      return {
        'date': date,
        'dayName': _dayName(date.weekday),
        'focusSessions': focusCount,
        'totalMinutes': totalMins,
      };
    });
  }

  static Map<String, dynamic> _summarize(List<PomodoroSession> sessions) {
    int focusCount = 0, focusSecs = 0, breakCount = 0, totalCompleted = 0;

    for (final s in sessions) {
      if (!s.completed) continue;
      totalCompleted++;
      if (s.type == SessionType.focus) {
        focusCount++;
        focusSecs += s.durationSeconds;
      } else {
        breakCount++;
      }
    }

    return {
      'focusSessions': focusCount,
      'totalFocusMinutes': (focusSecs / 60).round(),
      'totalFocusSeconds': focusSecs,
      'breakSessions': breakCount,
      'totalSessions': totalCompleted,
      'todayFocusMinutes': (focusSecs / 60).round(),
    };
  }

  static String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}