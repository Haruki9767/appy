import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pomodoro_session.dart';

enum TimerState { idle, running, paused, completed }

class TimerService extends ChangeNotifier {
  TimerState _state = TimerState.idle;
  SessionType _currentType = SessionType.focus;
  int _remainingSeconds = SessionType.focus.defaultDuration;
  int _totalSeconds = SessionType.focus.defaultDuration;
  int _completedPomodoros = 0;
  DateTime? _sessionStartTime;
  Timer? _timer;

  TimerState get state => _state;
  SessionType get currentType => _currentType;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get completedPomodoros => _completedPomodoros;
  DateTime? get sessionStartTime => _sessionStartTime;

  double get progress =>
      _totalSeconds == 0 ? 0.0 : (1 - (_remainingSeconds / _totalSeconds)).clamp(0.0, 1.0);

  String get formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isIdle => _state == TimerState.idle;

  void start() {
    if (_state == TimerState.running) return;
    _timer?.cancel();
    _sessionStartTime ??= DateTime.now();
    _state = TimerState.running;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _complete();
      }
    });
  }

  void pause() {
    if (_state != TimerState.running) return;
    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
  }

  void resume() {
    if (_state != TimerState.paused) return;
    start();
  }

  void stop() {
    _timer?.cancel();
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    _sessionStartTime = null;
    notifyListeners();
  }

  void _complete() {
    _timer?.cancel();
    _state = TimerState.completed;
    notifyListeners();
  }

  void skip() {
    _timer?.cancel();
    if (_currentType == SessionType.focus) {
      _completedPomodoros++;
    }
    _sessionStartTime = null;
    _nextSession();
  }

  void _nextSession() {
    if (_currentType == SessionType.focus) {
      if (_completedPomodoros > 0 && _completedPomodoros % 4 == 0) {
        _currentType = SessionType.longBreak;
      } else {
        _currentType = SessionType.shortBreak;
      }
    } else {
      _currentType = SessionType.focus;
    }
    _totalSeconds = _currentType.defaultDuration;
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    _sessionStartTime = null;
    notifyListeners();
  }

  void switchType(SessionType type) {
    if (_state == TimerState.running) return;
    _timer?.cancel();
    _currentType = type;
    _totalSeconds = type.defaultDuration;
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    _sessionStartTime = null;
    notifyListeners();
  }

  void continueToNext() {
    if (_currentType == SessionType.focus) {
      _completedPomodoros++;
    }
    _nextSession();
  }

  void resetDailyStatsIfNeeded(String lastResetDate) {
    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    if (lastResetDate != today) {
      _completedPomodoros = 0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}