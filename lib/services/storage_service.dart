import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pomodoro_session.dart';
import '../models/project.dart';
import '../models/achievement.dart';

class StorageService {
  static const String _sessionsBoxName = 'pomodoro_sessions';
  static const String _projectsBoxName = 'projects';
  static const String _achievementsBoxName = 'achievements';
  static const String _lastResetKey = 'last_daily_reset';
  static const String _achievementsKey = 'unlocked_achievements';

  static Box<PomodoroSession>? _sessionsBox;
  static Box<Project>? _projectsBox;
  static Box<Achievement>? _achievementsBox;
  static SharedPreferences? _prefs;

  static bool get _isReady => _sessionsBox != null && _prefs != null;

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

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PomodoroSessionAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SessionTypeAdapter());
      }

      _sessionsBox = await Hive.openBox<PomodoroSession>(_sessionsBoxName);
      _projectsBox = await Hive.openBox<Project>(_projectsBoxName);
      _achievementsBox = await Hive.openBox<Achievement>(_achievementsBoxName);
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
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
        .where((s) => _dateKey(DateTime.parse(s.startTime)) == today)
        .toList();
  }

  static List<PomodoroSession> getSessionsInRange(DateTime start, DateTime end) {
    return _box.values.where((s) {
      final sessionDate = DateTime.parse(s.startTime);
      return !sessionDate.isBefore(start) && sessionDate.isBefore(end);
    }).toList();
  }

  static Future<void> deleteSession(String id) async {
    await _box.delete(id);
  }

  static Future<void> clearAllSessions() async {
    await _box.clear();
  }

  // ── Projects ──────────────────────────────────────────────────────────────

  static Future<void> saveProject(Project project) async {
    await _projectsBox?.put(project.id, project);
  }

  static List<Project> getAllProjects() {
    return _projectsBox?.values.toList() ?? [];
  }

  static Future<void> deleteProject(String id) async {
    await _projectsBox?.delete(id);
  }

  // ── Achievements ──────────────────────────────────────────────────────────

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

  // ── Settings ──────────────────────────────────────────────────────────────

  static Future<void> setSetting(String key, dynamic value) async {
    if (value is int) {
      await _p.setInt(key, value);
    } else if (value is double) {
      await _p.setDouble(key, value);
    } else if (value is bool) {
      await _p.setBool(key, value);
    } else if (value is String) {
      await _p.setString(key, value);
    } else if (value is List<String>) {
      await _p.setStringList(key, value);
    } else {
      throw ArgumentError('Unsupported setting type: ${value.runtimeType}');
    }
  }

  static T getSetting<T>(String key, T defaultValue) {
    try {
      if (T == int) {
        return (_p.getInt(key) ?? defaultValue) as T;
      }
      if (T == double) {
        return (_p.getDouble(key) ?? defaultValue) as T;
      }
      if (T == bool) {
        return (_p.getBool(key) ?? defaultValue) as T;
      }
      if (T == String) {
        return (_p.getString(key) ?? defaultValue) as T;
      }
      if (T == List<String>) {
        return (_p.getStringList(key) ?? defaultValue) as T;
      }
    } catch (_) {
      // Key exists but wrong type — return default
    }
    return defaultValue;
  }

  static Future<Map<String, dynamic>> getSettings() async {
    return {
      'dailyGoal': _p.getInt('dailyGoal') ?? 2,
      'weeklyGoal': _p.getInt('weeklyGoal') ?? 10,
      'monthlyGoal': _p.getInt('monthlyGoal') ?? 40,
      'focusDuration': _p.getInt('focusDuration') ?? 25,
      'shortBreak': _p.getInt('shortBreak') ?? 5,
      'longBreak': _p.getInt('longBreak') ?? 15,
      'autoStartBreaks': _p.getBool('autoStartBreaks') ?? false,
      'autoStartFocus': _p.getBool('autoStartFocus') ?? false,
      'soundEnabled': _p.getBool('soundEnabled') ?? true,
    };
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  static Future<int> getGoal(String key, int defaultValue) async {
    return _p.getInt(key) ?? defaultValue;
  }

  static Future<void> setGoal(String key, int value) async {
    await _p.setInt(key, value);
  }

  // ── Daily reset tracking ──────────────────────────────────────────────────

  static String getLastResetDate() {
    return getSetting<String>(_lastResetKey, '');
  }

  static Future<void> setLastResetDate(String date) async {
    await setSetting(_lastResetKey, date);
  }

  static Future<void> clearAll() async {
    await _box.clear();
    await _projectsBox?.clear();
    await _achievementsBox?.clear();
    await _p.clear();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}