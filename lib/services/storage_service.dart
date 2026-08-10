import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pomodoro_session.dart';

class StorageService {
  static const String _sessionsBoxName = 'pomodoro_sessions';

  static Box<PomodoroSession>? _sessionsBox;
  static SharedPreferences? _prefs;

  // Initialize storage
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Hive adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PomodoroSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionTypeAdapter());
    }

    _sessionsBox = await Hive.openBox<PomodoroSession>(_sessionsBoxName);
    _prefs = await SharedPreferences.getInstance();
  }

  // Session methods
  static Future<void> saveSession(PomodoroSession session) async {
    await _sessionsBox?.put(session.id, session);
  }

  static List<PomodoroSession> getAllSessions() {
    return _sessionsBox?.values.toList() ?? [];
  }

  static List<PomodoroSession> getTodaySessions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _sessionsBox?.values.where((session) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      return sessionDate == today;
    }).toList() ?? [];
  }

  static List<PomodoroSession> getSessionsInRange(DateTime start, DateTime end) {
    return _sessionsBox?.values.where((session) {
      return session.startTime.isAfter(start) && session.startTime.isBefore(end);
    }).toList() ?? [];
  }

  // Settings methods
  static Future<void> setSetting(String key, dynamic value) async {
    if (value is int) {
      await _prefs?.setInt(key, value);
    } else if (value is double) {
      await _prefs?.setDouble(key, value);
    } else if (value is bool) {
      await _prefs?.setBool(key, value);
    } else if (value is String) {
      await _prefs?.setString(key, value);
    }
  }

  static T? getSetting<T>(String key, T defaultValue) {
    if (T == int) {
      return (_prefs?.getInt(key) ?? defaultValue) as T;
    } else if (T == double) {
      return (_prefs?.getDouble(key) ?? defaultValue) as T;
    } else if (T == bool) {
      return (_prefs?.getBool(key) ?? defaultValue) as T;
    } else if (T == String) {
      return (_prefs?.getString(key) ?? defaultValue) as T;
    }
    return defaultValue;
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _sessionsBox?.clear();
    await _prefs?.clear();
  }
}
