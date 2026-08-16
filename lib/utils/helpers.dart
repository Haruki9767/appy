import '../models/pomodoro_session.dart';

String todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String formatTime(int seconds) {
  final minutes = (seconds / 60).floor();
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}

String formatHours(int minutes) {
  if (minutes == 0) return '0m';
  if (minutes < 60) return '${minutes}m';
  final hours = (minutes / 60).floor();
  final remainingMinutes = minutes % 60;
  return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
}

int getTotalHours(List<PomodoroSession> sessions) {
  return sessions
      .where((s) => s.type == 'focus' && s.completed)
      .fold<int>(0, (sum, s) => sum + s.durationMinutes) ~/ 60;
}

int getTodayMins(List<PomodoroSession> sessions) {
  final today = todayKey();
  return sessions
      .where((s) => s.date == today && s.type == 'focus' && s.completed)
      .fold<int>(0, (sum, s) => sum + s.durationMinutes);
}

int getWeekMins(List<PomodoroSession> sessions) {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  return sessions
      .where((s) => s.type == 'focus' && s.completed)
      .where((s) {
        final date = DateTime.parse(s.date);
        return date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart);
      })
      .fold<int>(0, (sum, s) => sum + s.durationMinutes);
}

int getMonthMins(List<PomodoroSession> sessions) {
  final now = DateTime.now();
  return sessions
      .where((s) => s.type == 'focus' && s.completed)
      .where((s) {
        final date = DateTime.parse(s.date);
        return date.month == now.month && date.year == now.year;
      })
      .fold<int>(0, (sum, s) => sum + s.durationMinutes);
}

int getYearMins(List<PomodoroSession> sessions) {
  final now = DateTime.now();
  return sessions
      .where((s) => s.type == 'focus' && s.completed)
      .where((s) {
        final date = DateTime.parse(s.date);
        return date.year == now.year;
      })
      .fold<int>(0, (sum, s) => sum + s.durationMinutes);
}

int getStreak(List<PomodoroSession> sessions) {
  final focusSessions = sessions.where((s) => s.type == 'focus' && s.completed).toList();
  if (focusSessions.isEmpty) return 0;
  
  final days = focusSessions.map((s) => s.date).toSet().toList();
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

int getAverageSession(List<PomodoroSession> sessions) {
  final completed = sessions.where((s) => s.type == 'focus' && s.completed).toList();
  if (completed.isEmpty) return 0;
  final total = completed.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  return total ~/ completed.length;
}

Map<String, int> getDailySessions(List<PomodoroSession> sessions, int days) {
  final result = <String, int>{};
  final now = DateTime.now();
  
  for (int i = days - 1; i >= 0; i--) {
    final date = now.subtract(Duration(days: i));
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dayMins = sessions
        .where((s) => s.date == key && s.type == 'focus' && s.completed)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
    result[key] = dayMins;
  }
  
  return result;
}

String formatDate(String dateKey) {
  final parts = dateKey.split('-');
  final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  return '${date.month}/${date.day}';
}

String getMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return months[month - 1];
}