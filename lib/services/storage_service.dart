import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pomodoro_session.dart';

class StorageService {
  static const String _sessionsBoxName = 'pomodoro_sessions';
  static const String _lastResetKey = 'last_daily_reset';

  static Box<PomodoroSession>? _sessionsBox;
  static SharedPreferences? _prefs;

  static bool get _isReady => _sessionsBox != null && _prefs != null;

  // FIX: throws instead of silently returning null if not initialized
  static Box<PomodoroSession> get _box {
    if (_sessionsBox == null) {
      throw StateError('StorageService not initialized. Call StorageService.init() first.');
    }
    return _sessionsBox!;
  }

  static SharedPreferences get _p {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }

  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PomodoroSessionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SessionTypeAdapter());
      }

      _sessionsBox = await Hive.openBox<PomodoroSession>(_sessionsBoxName);
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // Rethrow so main() can handle it gracefully rather than silently failing
      throw Exception('StorageService.init() failed: $e');
    }
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  static Future<void> saveSession(PomodoroSession session) async {
    await _box.put(session.id, session);
  }

  static List<PomodoroSession> getAllSessions() {
    return _box.values.toList();
  }

  static List<PomodoroSession> getTodaySessions() {
    final today = _dateKey(DateTime.now());
    return _box.values
        .where((s) => _dateKey(s.startTime) == today)
        .toList();
  }

  static List<PomodoroSession> getSessionsInRange(DateTime start, DateTime end) {
    return _box.values.where((s) {
      // FIX: use >= start (was strict isAfter, missing exact-midnight sessions)
      return !s.startTime.isBefore(start) && s.startTime.isBefore(end);
    }).toList();
  }

  static Future<void> clearAll() async {
    await _box.clear();
    await _p.clear();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  static Future<void> setSetting(String key, dynamic value) async {
    if (value is int)         await _p.setInt(key, value);
    else if (value is double) await _p.setDouble(key, value);
    else if (value is bool)   await _p.setBool(key, value);
    else if (value is String) await _p.setString(key, value);
    // FIX: unsupported types throw clearly rather than silently no-op
    else throw ArgumentError('Unsupported setting type: ${value.runtimeType}');
  }

  // FIX: return non-nullable T — defaultValue is always returned on miss,
  // so nullable return type was misleading
  static T getSetting<T>(String key, T defaultValue) {
    try {
      if (T == int)    return (_p.getInt(key)    ?? defaultValue) as T;
      if (T == double) return (_p.getDouble(key) ?? defaultValue) as T;
      if (T == bool)   return (_p.getBool(key)   ?? defaultValue) as T;
      if (T == String) return (_p.getString(key) ?? defaultValue) as T;
    } catch (_) {
      // Key exists but wrong type — return default
    }
    return defaultValue;
  }

  // ── Daily reset tracking ──────────────────────────────────────────────────

  static String getLastResetDate() {
    return getSetting<String>(_lastResetKey, '');
  }

  static Future<void> setLastResetDate(String date) async {
    await setSetting(_lastResetKey, date);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// Add these to the StorageService class

// ── Achievements ──────────────────────────────────────────────────────────────

static const String _achievementsKey = 'unlocked_achievements';

static Future<List<String>> getUnlockedAchievements() async {
  return _p.getStringList(_achievementsKey) ?? [];
}

static Future<void> saveUnlockedAchievements(List<String> achievements) async {
  await _p.setStringList(_achievementsKey, achievements);
}

static Future<void> addUnlockedAchievement(String id) async {
  final current = await getUnlockedAchievements();
  if (!current.contains(id)) {
    current.add(id);
    await saveUnlockedAchievements(current);
  }
}

// ── Goals ────────────────────────────────────────────────────────────────────

static Future<int> getGoal(String key, int defaultValue) async {
  return _p.getInt(key) ?? defaultValue;
}

static Future<void> setGoal(String key, int value) async {
  await _p.setInt(key, value);
}