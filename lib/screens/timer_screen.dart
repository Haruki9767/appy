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
      builder: (context, timerService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FocusFlow'),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // Open drawer or menu
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                    _buildControlButtons(context, timerService),
                    const SizedBox(height: 40),
                    _buildTodayStats(context, timerService),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildModeSelector(BuildContext context, TimerService timerService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeCard(
          context,
          SessionType.focus,
          timerService.currentType == SessionType.focus,
          () => timerService.switchType(SessionType.focus),
        ),
        const SizedBox(width: 12),
        _buildModeCard(
          context,
          SessionType.shortBreak,
          timerService.currentType == SessionType.shortBreak,
          () => timerService.switchType(SessionType.shortBreak),
        ),
        const SizedBox(width: 12),
        _buildModeCard(
          context,
          SessionType.longBreak,
          timerService.currentType == SessionType.longBreak,
          () => timerService.switchType(SessionType.longBreak),
        ),
      ],
    );
  }

  Widget _buildModeCard(
    BuildContext context,
    SessionType type,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final gradient = _getGradientForType(type);
    final minutes = type.defaultDuration ~/ 60;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isSelected ? 1.1 : 1.0,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? _getMainColorForType(type).withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.1),
                blurRadius: isSelected ? 15 : 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 4),
              Text(
                type.name.split(' ')[0],
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

  Widget _buildControlButtons(BuildContext context, TimerService timerService) {
    return Column(
      children: [
        // Main button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleMainButton(timerService),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getMainColorForType(timerService.currentType),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getMainButtonIcon(timerService)),
                const SizedBox(width: 12),
                Text(
                  _getMainButtonText(timerService),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Secondary buttons
        if (timerService.isRunning || timerService.isPaused)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => timerService.stop(),
                icon: const Icon(Icons.stop),
                iconSize: 32,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: () => timerService.skip(),
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTodayStats(BuildContext context, TimerService timerService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '🍅',
            '${timerService.completedPomodoros}',
            'Completed',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            '⏱️',
            '${timerService.completedPomodoros * 25}',
            'Minutes',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            '🔥',
            timerService.completedPomodoros >= 4 ? '${timerService.completedPomodoros ~/ 4}' : '0',
            'Streaks',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.timer, 'Timer', true, () {}),
              _buildNavItem(Icons.bar_chart, 'Stats', false, () {
                Navigator.pushNamed(context, '/statistics');
              }),
              _buildNavItem(Icons.settings, 'Settings', false, () {
                Navigator.pushNamed(context, '/settings');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.focusRed : AppTheme.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppTheme.focusRed : AppTheme.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMainButton(TimerService timerService) {
    if (timerService.isRunning) {
      timerService.pause();
    } else if (timerService.isPaused) {
      timerService.resume();
    } else if (timerService.state == TimerState.completed) {
      _saveCompletedSession(timerService);
      timerService.continueToNext();
    } else {
      timerService.start();
    }
  }

  void _saveCompletedSession(TimerService timerService) {
    final session = PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now().subtract(Duration(seconds: timerService.totalSeconds)),
      endTime: DateTime.now(),
      type: timerService.currentType,
      completed: true,
      durationSeconds: timerService.totalSeconds,
    );
    StorageService.saveSession(session);
  }

  IconData _getMainButtonIcon(TimerService timerService) {
    if (timerService.isRunning) return Icons.pause;
    if (timerService.isPaused) return Icons.play_arrow;
    if (timerService.state == TimerState.completed) return Icons.skip_next;
    return Icons.play_arrow;
  }

  String _getMainButtonText(TimerService timerService) {
    if (timerService.isRunning) return 'Pause';
    if (timerService.isPaused) return 'Resume';
    if (timerService.state == TimerState.completed) return 'Next Session';
    return 'Start ${timerService.currentType.name}';
  }

  LinearGradient _getGradientForType(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return AppTheme.getFocusGradient();
      case SessionType.shortBreak:
        return AppTheme.getBreakGradient();
      case SessionType.longBreak:
        return AppTheme.getLongBreakGradient();
    }
  }

  Color _getMainColorForType(SessionType type) {
    switch (type) {
      case SessionType.focus:
        return AppTheme.focusRed;
      case SessionType.shortBreak:
        return AppTheme.breakGreen;
      case SessionType.longBreak:
        return AppTheme.longBreakPurple;
    }
  }
}
