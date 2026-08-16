import '../models/pomodoro_session.dart';
import 'storage_service.dart';

class StatisticsService {
  static Map<String, dynamic> getTodayStats() {
    final sessions = StorageService.getTodaySessions();
    return _summarize(sessions);
  }

  static Map<String, dynamic> getWeekStats() {
    final now = DateTime.now();
    // Start of current Monday
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final sessions = StorageService.getSessionsInRange(weekStart, weekEnd);
    final summary = _summarize(sessions);

    final focusCount = summary['focusSessions'] as int;
    // FIX: dailyAverage is a double, not a String, so callers can do arithmetic
    summary['dailyAverage'] = focusCount > 0
        ? double.parse((focusCount / 7).toStringAsFixed(1))
        : 0.0;
    return summary;
  }

  static Map<String, dynamic> getTotalStats() {
    final sessions = StorageService.getAllSessions();
    final summary = _summarize(sessions);
    final totalSecs = (summary['totalFocusSeconds'] as int);
    summary['totalFocusHours'] = (totalSecs / 3600).round();
    return summary;
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
      return {
        'date': date,
        'dayName': _dayName(date.weekday),
        'focusSessions': focusCount,
      };
    });
  }

  // FIX: single-pass summary instead of iterating sessions 3 times
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
    };
  }

  static String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1).clamp(0, 6)];
  }
}
