import '../models/pomodoro_session.dart';
import 'storage_service.dart';

class StatisticsService {
  // Get today's statistics
  static Map<String, dynamic> getTodayStats() {
    final sessions = StorageService.getTodaySessions();
    
    final focusSessions = sessions.where((s) => s.type == SessionType.focus && s.completed).length;
    final totalFocusTime = sessions
        .where((s) => s.type == SessionType.focus && s.completed)
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
    
    final breakSessions = sessions
        .where((s) => (s.type == SessionType.shortBreak || s.type == SessionType.longBreak) && s.completed)
        .length;
    
    return {
      'focusSessions': focusSessions,
      'totalFocusMinutes': (totalFocusTime / 60).round(),
      'breakSessions': breakSessions,
      'totalSessions': sessions.where((s) => s.completed).length,
    };
  }

  // Get this week's statistics
  static Map<String, dynamic> getWeekStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekEnd = weekStartDate.add(const Duration(days: 7));
    
    final sessions = StorageService.getSessionsInRange(weekStartDate, weekEnd);
    
    final focusSessions = sessions.where((s) => s.type == SessionType.focus && s.completed).length;
    final totalFocusTime = sessions
        .where((s) => s.type == SessionType.focus && s.completed)
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
    
    return {
      'focusSessions': focusSessions,
      'totalFocusMinutes': (totalFocusTime / 60).round(),
      'dailyAverage': focusSessions > 0 ? (focusSessions / 7).toStringAsFixed(1) : '0',
    };
  }

  // Get daily data for the past 7 days
  static List<Map<String, dynamic>> getLast7DaysData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final sessions = StorageService.getSessionsInRange(dayStart, dayEnd);
      final focusSessions = sessions.where((s) => s.type == SessionType.focus && s.completed).length;
      
      data.add({
        'date': date,
        'dayName': _getDayName(date.weekday),
        'focusSessions': focusSessions,
      });
    }
    
    return data;
  }

  static String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // Get total statistics
  static Map<String, dynamic> getTotalStats() {
    final sessions = StorageService.getAllSessions();
    
    final focusSessions = sessions.where((s) => s.type == SessionType.focus && s.completed).length;
    final totalFocusTime = sessions
        .where((s) => s.type == SessionType.focus && s.completed)
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);
    
    final totalHours = (totalFocusTime / 3600).round();
    
    return {
      'totalFocusSessions': focusSessions,
      'totalFocusHours': totalHours,
      'totalSessions': sessions.where((s) => s.completed).length,
    };
  }
}
