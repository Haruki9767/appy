import 'dart:convert';
import 'package:intl/intl.dart';
import 'storage_service.dart';
import 'statistics_service.dart';
import '../models/pomodoro_session.dart';

class ReportService {
  static Future<String> generateMonthlyReport() async {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);
    final sessions = StorageService.getAllSessions();
    final monthSessions = sessions.where((s) {
      return s.startTime.month == now.month &&  // ✅ FIXED: DateTime
             s.startTime.year == now.year &&    // ✅ FIXED: DateTime
             s.type == 'focus' &&
             s.completed;
    }).toList();

    final totalMinutes = monthSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);  // ✅ FIXED: durationMinutes
    final dailyAvg = monthSessions.isEmpty ? 0 : totalMinutes / 30;
    final streak = StatisticsService.getStreak();
    final subjects = _getSubjects(monthSessions);
    final achievements = await StorageService.getUnlockedAchievements();

    final report = {
      'title': 'Monthly Report - $monthName',
      'generated': DateTime.now().toIso8601String(),
      'summary': {
        'totalHours': (totalMinutes / 60).toStringAsFixed(1),
        'dailyAverage': dailyAvg.toStringAsFixed(1),
        'longestStreak': streak,
        'sessions': monthSessions.length,
        'subjects': subjects,
        'achievements': achievements.length,
      },
      'details': {
        'sessions': monthSessions.map((s) => {
          'date': DateFormat('yyyy-MM-dd').format(s.startTime),  // ✅ FIXED: DateTime
          'duration': s.durationMinutes,  // ✅ FIXED: durationMinutes
          'note': s.note ?? '',
          'subject': s.subject ?? '',
        }).toList(),
      }
    };

    return jsonEncode(report);
  }

  static Future<String> generateYearlyReport() async {
    final now = DateTime.now();
    final year = now.year;
    final sessions = StorageService.getAllSessions();
    final yearSessions = sessions.where((s) {
      return s.startTime.year == year &&  // ✅ FIXED: DateTime
             s.type == 'focus' &&
             s.completed;
    }).toList();

    final monthlyBreakdown = <String, int>{};
    for (int month = 1; month <= 12; month++) {
      final monthSessions = yearSessions.where((s) => s.startTime.month == month).toList();  // ✅ FIXED: DateTime
      final totalMins = monthSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);  // ✅ FIXED: durationMinutes
      monthlyBreakdown[DateFormat('MMM').format(DateTime(year, month))] = totalMins;
    }

    final totalMinutes = yearSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);  // ✅ FIXED: durationMinutes
    final streak = StatisticsService.getStreak();

    final report = {
      'title': 'Yearly Report - $year',
      'generated': DateTime.now().toIso8601String(),
      'summary': {
        'totalHours': (totalMinutes / 60).toStringAsFixed(1),
        'longestStreak': streak,
        'sessions': yearSessions.length,
        'monthlyBreakdown': monthlyBreakdown,
        'totalAchievements': (await StorageService.getUnlockedAchievements()).length,
      }
    };

    return jsonEncode(report);
  }

  static List<String> _getSubjects(List<PomodoroSession> sessions) {
    final subjects = sessions
        .map((s) => s.subject)
        .where((s) => s != null && s!.isNotEmpty)
        .toSet()
        .cast<String>()
        .toList();
    return subjects;
  }
}