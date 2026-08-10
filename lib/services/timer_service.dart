import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pomodoro_session.dart';

enum TimerState {
  idle,
  running,
  paused,
  completed,
}

class TimerService extends ChangeNotifier {
  TimerState _state = TimerState.idle;
  SessionType _currentType = SessionType.focus;
  int _remainingSeconds = SessionType.focus.defaultDuration;
  int _totalSeconds = SessionType.focus.defaultDuration;
  int _completedPomodoros = 0;
  Timer? _timer;

  // Getters
  TimerState get state => _state;
  SessionType get currentType => _currentType;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  int get completedPomodoros => _completedPomodoros;
  double get progress => 1 - (_remainingSeconds / _totalSeconds);

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isIdle => _state == TimerState.idle;

  // Start timer
  void start() {
    if (_state == TimerState.running) return;

    _state = TimerState.running;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _complete();
      }
    });
  }

  // Pause timer
  void pause() {
    if (_state != TimerState.running) return;

    _timer?.cancel();
    _state = TimerState.paused;
    notifyListeners();
  }

  // Resume timer
  void resume() {
    if (_state != TimerState.paused) return;
    start();
  }

  // Stop/Reset timer
  void stop() {
    _timer?.cancel();
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    notifyListeners();
  }

  // Complete current session
  void _complete() {
    _timer?.cancel();
    _state = TimerState.completed;

    if (_currentType == SessionType.focus) {
      _completedPomodoros++;
    }

    notifyListeners();
  }

  // Skip to next session
  void skip() {
    _timer?.cancel();
    _nextSession();
  }

  // Switch to next session type
  void _nextSession() {
    if (_currentType == SessionType.focus) {
      // After focus, alternate between short and long breaks
      if (_completedPomodoros % 4 == 0 && _completedPomodoros > 0) {
        _currentType = SessionType.longBreak;
      } else {
        _currentType = SessionType.shortBreak;
      }
    } else {
      // After any break, go back to focus
      _currentType = SessionType.focus;
    }

    _totalSeconds = _currentType.defaultDuration;
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    notifyListeners();
  }

  // Manually switch session type
  void switchType(SessionType type) {
    if (_state == TimerState.running) return;

    _currentType = type;
    _totalSeconds = type.defaultDuration;
    _remainingSeconds = _totalSeconds;
    _state = TimerState.idle;
    notifyListeners();
  }

  // Continue to next session automatically
  void continueToNext() {
    _nextSession();
  }

  // Reset daily stats
  void resetDailyStats() {
    _completedPomodoros = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
