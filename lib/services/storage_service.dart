import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pomodoro_session.dart';
import '../models/project.dart';
import '../models/achievement.dart';

class StorageService {
  static const String _sessionsBoxName    = 'pomodoro_sessions';
  static const String _projectsBoxName    = 'projects';
  static const String _achievementsBoxName = 'achievements';
  static const String _lastResetKey       = 'last_daily_reset';
  static const String _achievementsKey    = 'unlocked_achievements';

  static Box<PomodoroSession>? _sessionsBox;
  static Box<Project>?         _projectsBox;
  static Box<Achievement>?     _achievementsBox;
  static SharedPreferences?    _prefs;

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

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(PomodoroSessionAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SessionTypeAdapter());

      _sessionsBox     = await Hive.openBox<PomodoroSession>(_sessionsBoxName);
      _projectsBox     = await Hive.openBox<Project>(_projectsBoxName);
      _achievementsBox = await Hive.openBox<Achievement>(_achievementsBoxName);
      _prefs           = await SharedPreferences.getInstance();
    } catch (e) {
      throw Exception('StorageService.init() failed: $e');
    }
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  static Future<void> saveSession(PomodoroSession session) async {
    await _box.put(session.id, session);
  }

  static List<PomodoroSession> getAllSessions() => _box.values.toList();

  static List<PomodoroSession> getTodaySessions() {
    final today = _dateKey(DateTime.now());
    return _box.values.where((s) => _dateKey(s.startTime) == today).toList();
  }

  static List<PomodoroSession> getSessionsInRange(DateTime start, DateTime end) {
    return _box.values
        .where((s) => !s.startTime.isBefore(start) && s.startTime.isBefore(end))
        .toList();
  }

  static Future<void> deleteSession(String id) async => _box.delete(id);

  static Future<void> clearAllSessions() async => _box.clear();

  // ── Projects ──────────────────────────────────────────────────────────────

  static Future<void> saveProject(Project project) async =>
      _projectsBox?.put(project.id, project);

  static List<Project> getAllProjects() => _projectsBox?.values.toList() ?? [];

  static Future<void> deleteProject(String id) async =>
      _projectsBox?.delete(id);

  // ── Achievements ──────────────────────────────────────────────────────────

  static Future<List<String>> getUnlockedAchievements() async =>
      _p.getStringList(_achievementsKey) ?? [];

  static Future<void> saveUnlockedAchievements(List<String> ids) async =>
      _p.setStringList(_achievementsKey, ids);

  static Future<void> addUnlockedAchievement(String id) async {
    final current = await getUnlockedAchievements();
    if (!current.contains(id)) {
      current.add(id);
      await saveUnlockedAchievements(current);
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  static Future<void> setSetting(String key, dynamic value) async {
    if (value is int)          await _p.setInt(key, value);
    else if (value is double)  await _p.setDouble(key, value);
    else if (value is bool)    await _p.setBool(key, value);
    else if (value is String)  await _p.setString(key, value);
    else if (value is List<String>) await _p.setStringList(key, value);
    else throw ArgumentError('Unsupported setting type: ${value.runtimeType}');
  }

  static T getSetting<T>(String key, T defaultValue) {
    try {
      if (T == int)    return (_p.getInt(key)    ?? defaultValue) as T;
      if (T == double) return (_p.getDouble(key) ?? defaultValue) as T;
      if (T == bool)   return (_p.getBool(key)   ?? defaultValue) as T;
      if (T == String) return (_p.getString(key) ?? defaultValue) as T;
      if (T == List<String>) return (_p.getStringList(key) ?? defaultValue) as T;
    } catch (_) {}
    return defaultValue;
  }

  static Future<Map<String, dynamic>> getSettings() async {
    return {
      'dailyGoal':       _p.getInt('dailyGoal')       ?? 2,
      'weeklyGoal':      _p.getInt('weeklyGoal')      ?? 10,
      'monthlyGoal':     _p.getInt('monthlyGoal')     ?? 40,
      'focusDuration':   _p.getInt('focusDuration')   ?? 25,
      'shortBreak':      _p.getInt('shortBreak')       ?? 5,
      'longBreak':       _p.getInt('longBreak')        ?? 15,
      'autoStartBreaks': _p.getBool('autoStartBreaks') ?? false,
      'autoStartFocus':  _p.getBool('autoStartFocus')  ?? false,
      'soundEnabled':    _p.getBool('soundEnabled')    ?? true,
    };
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  static Future<int> getGoal(String key, int defaultValue) async =>
      _p.getInt(key) ?? defaultValue;

  static Future<void> setGoal(String key, int value) async =>
      _p.setInt(key, value);

  // ── Daily reset ───────────────────────────────────────────────────────────

  static String getLastResetDate() => getSetting<String>(_lastResetKey, '');

  static Future<void> setLastResetDate(String date) async =>
      setSetting(_lastResetKey, date);

  // ── Clear all ─────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await _box.clear();
    await _projectsBox?.clear();
    await _achievementsBox?.clear();
    await _p.clear();
  }

  // ── Export / Import ───────────────────────────────────────────────────────
  //
  // Produces / consumes a single JSON string that the caller can write to a
  // file (via file_picker / share_plus) or read back from one.
  // Structure:
  // {
  //   "version": 1,
  //   "exportedAt": "<ISO timestamp>",
  //   "settings": { … },
  //   "unlockedAchievements": [ … ],
  //   "achievementTimestamps": { "<id>": "<ISO>" },
  //   "projects": [ { … } ],
  //   "sessions": [ { … } ]
  // }

  /// Serialise all app data to a JSON string.
  static Future<String> exportData() async {
    final settings = await getSettings();

    // Achievement unlock timestamps stored as individual keys
    final unlockedIds = await getUnlockedAchievements();
    final Map<String, String> timestamps = {};
    for (final id in unlockedIds) {
      final ts = getSetting<String>('unlockedAt_$id', '');
      if (ts.isNotEmpty) timestamps[id] = ts;
    }

    final projects = getAllProjects().map((p) => p.toJson()).toList();

    final sessions = getAllSessions().map((s) => {
      'id':              s.id,
      'date':            s.date,
      'type':            s.type,
      'durationMinutes': s.durationMinutes,
      'completed':       s.completed,
      'note':            s.note,
      'startTime':       s.startTime.toIso8601String(),
      'endTime':         s.endTime?.toIso8601String(),
      'subject':         s.subject,
      'tags':            s.tags,
      'projectId':       s.projectId,
    }).toList();

    final payload = {
      'version':                1,
      'exportedAt':             DateTime.now().toIso8601String(),
      'settings':               settings,
      'unlockedAchievements':   unlockedIds,
      'achievementTimestamps':  timestamps,
      'projects':               projects,
      'sessions':               sessions,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Restore all app data from a JSON string previously produced by [exportData].
  /// Throws [FormatException] if the JSON is invalid or the version is
  /// unrecognised.
  static Future<void> importData(String jsonString) async {
    final Map<String, dynamic> payload =
        jsonDecode(jsonString) as Map<String, dynamic>;

    final version = payload['version'] as int? ?? 0;
    if (version != 1) {
      throw FormatException('Unsupported backup version: $version');
    }

    // ── Wipe existing data first ──────────────────────────────────────────
    await clearAll();

    // ── Settings ──────────────────────────────────────────────────────────
    final settings = payload['settings'] as Map<String, dynamic>? ?? {};
    for (final entry in settings.entries) {
      await setSetting(entry.key, entry.value);
    }

    // ── Achievements ──────────────────────────────────────────────────────
    final unlockedIds =
        (payload['unlockedAchievements'] as List<dynamic>? ?? [])
            .cast<String>();
    await saveUnlockedAchievements(unlockedIds);

    final timestamps =
        (payload['achievementTimestamps'] as Map<String, dynamic>? ?? {})
            .cast<String, String>();
    for (final entry in timestamps.entries) {
      await setSetting('unlockedAt_${entry.key}', entry.value);
    }

    // ── Projects ──────────────────────────────────────────────────────────
    final projectsJson =
        (payload['projects'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    for (final json in projectsJson) {
      final project = Project.fromJson(json);
      await saveProject(project);
    }

    // ── Sessions ──────────────────────────────────────────────────────────
    final sessionsJson =
        (payload['sessions'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    for (final json in sessionsJson) {
      final session = PomodoroSession(
        id:              json['id'] as String?,
        date:            json['date'] as String,
        type:            json['type'] as String,
        durationMinutes: json['durationMinutes'] as int,
        completed:       json['completed'] as bool,
        note:            json['note'] as String?,
        startTime:       DateTime.parse(json['startTime'] as String),
        endTime:         json['endTime'] != null
                             ? DateTime.parse(json['endTime'] as String)
                             : null,
        subject:         json['subject'] as String?,
        tags:            (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        projectId:       json['projectId'] as String?,
      );
      await saveSession(session);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
