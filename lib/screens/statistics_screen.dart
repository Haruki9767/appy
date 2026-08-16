import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pomodoro_session.dart';
import '../services/timer_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_timer.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, timerService, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FocusFlow'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildModeSelector(context, timerService),
                    const SizedBox(height: 40),
                    CircularTimer(
                      progress: timerService.progress,
                      timeText: timerService.formattedTime,
                      sessionType: timerService.currentType,
                      completedPomodoros: timerService.completedPomodoros,
                    ),
                    const SizedBox(height: 40),
                    _buildControls(context, timerService),
                    const SizedBox(height: 40),
                    _buildTodayStats(timerService),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context, 0),
        );
      },
    );
  }

  Widget _buildModeSelector(BuildContext context, TimerService t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _modeCard(context, t, SessionType.focus),
        const SizedBox(width: 12),
        _modeCard(context, t, SessionType.shortBreak),
        const SizedBox(width: 12),
        _modeCard(context, t, SessionType.longBreak),
      ],
    );
  }

  Widget _modeCard(BuildContext context, TimerService t, SessionType type) {
    final isSelected = t.currentType == type;
    final color = _colorForType(type);
    final minutes = type.defaultDuration ~/ 60;

    return GestureDetector(
      onTap: () => t.switchType(type),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: isSelected ? 1.08 : 1.0,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: isSelected ? _gradientForType(type) : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isSelected ? color.withOpacity(0.25) : Colors.grey.withOpacity(0.08),
                blurRadius: isSelected ? 12 : 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(type.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                type.displayName.split(' ')[0],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              Text(
                '${minutes}min',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, TimerService t) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleMain(context, t),
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorForType(t.currentType),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_mainIcon(t)),
                const SizedBox(width: 12),
                Text(_mainLabel(t), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        if (t.isRunning || t.isPaused) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () => t.stop(), icon: const Icon(Icons.stop), iconSize: 32, color: AppTheme.textSecondary),
              const SizedBox(width: 24),
              IconButton(onPressed: () => t.skip(), icon: const Icon(Icons.skip_next), iconSize: 32, color: AppTheme.textSecondary),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTodayStats(TimerService t) {
    final todaySessions = StorageService.getTodaySessions();
    final todayMins = todaySessions
        .where((s) => s.type == 'focus' && s.completed)
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);  // ✅ FIXED: durationMinutes

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('🍅', '${t.completedPomodoros}', 'Completed'),
          _divider(),
          _statItem('⏱️', '$todayMins', 'Minutes'),
          _divider(),
          _statItem('🔥', t.completedPomodoros >= 4 ? '${t.completedPomodoros ~/ 4}' : '0', 'Streaks'),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 24)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
  ]);

  Widget _divider() => Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.15));

  Widget _buildBottomNav(BuildContext context, int activeIndex) {
    final items = [
      (Icons.timer, 'Timer', () {}),
      (Icons.bar_chart, 'Stats', () => Navigator.pushNamed(context, '/statistics')),
      (Icons.settings, 'Settings', () => Navigator.pushNamed(context, '/settings')),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final isActive = e.key == activeIndex;
              final (icon, label, onTap) = e.value;
              return InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: isActive ? AppTheme.focusRed : AppTheme.textSecondary, size: 28),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(
                        fontSize: 12,
                        color: isActive ? AppTheme.focusRed : AppTheme.textSecondary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleMain(BuildContext context, TimerService t) {
    if (t.isRunning) {
      t.pause();
    } else if (t.isPaused) {
      t.resume();
    } else if (t.state == TimerState.completed) {
      _saveCompletedSession(t);
      t.continueToNext();
    } else {
      t.start();
    }
  }

  void _saveCompletedSession(TimerService t) async {
    final start = t.sessionStartTime ?? DateTime.now().subtract(Duration(seconds: t.totalSeconds));
    final end = DateTime.now();
    final actualSecs = end.difference(start).inSeconds;

    final session = PomodoroSession(
      id: '${DateTime.now().millisecondsSinceEpoch}_${t.currentType.name}',
      date: _dateKey(DateTime.now()),
      type: t.currentType.name,
      durationMinutes: (actualSecs / 60).ceil(),  // ✅ FIXED: use durationMinutes
      completed: true,
      startTime: start,  // ✅ FIXED: DateTime
      endTime: end,      // ✅ FIXED: DateTime
    );

    try {
      await StorageService.saveSession(session);
    } catch (e) {
      debugPrint('Failed to save session: $e');
    }
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  IconData _mainIcon(TimerService t) {
    if (t.isRunning) return Icons.pause;
    if (t.isPaused) return Icons.play_arrow;
    if (t.state == TimerState.completed) return Icons.skip_next;
    return Icons.play_arrow;
  }

  String _mainLabel(TimerService t) {
    if (t.isRunning) return 'Pause';
    if (t.isPaused) return 'Resume';
    if (t.state == TimerState.completed) return 'Next Session';
    return 'Start ${t.currentType.displayName}';
  }

  Color _colorForType(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return AppTheme.focusRed;
      case SessionType.shortBreak:
        return AppTheme.breakGreen;
      case SessionType.longBreak:
        return AppTheme.longBreakPurple;
      case SessionType.stopwatch:
        return AppTheme.warningYellow;
      case SessionType.countdown:
        return AppTheme.errorRed;
      case SessionType.candle:
        return const Color(0xFFFF9F1C);
      case SessionType.ice:
        return const Color(0xFF4FC3F7);
    }
  }

  LinearGradient _gradientForType(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return AppTheme.getFocusGradient();
      case SessionType.shortBreak:
        return AppTheme.getBreakGradient();
      case SessionType.longBreak:
        return AppTheme.getLongBreakGradient();
      case SessionType.stopwatch:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SessionType.countdown:
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SessionType.candle:
        return const LinearGradient(
          colors: [Color(0xFFFF9F1C), Color(0xFFFFB347)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SessionType.ice:
        return const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF81D4FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}