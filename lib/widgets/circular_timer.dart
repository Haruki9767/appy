import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/pomodoro_session.dart';
import '../theme/app_theme.dart';

class CircularTimer extends StatelessWidget {
  final double progress;
  final String timeText;
  final SessionType sessionType;
  final int completedPomodoros;

  const CircularTimer({
    super.key,
    required this.progress,
    required this.timeText,
    required this.sessionType,
    this.completedPomodoros = 0,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.7;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TimerPainter(
          // FIX: clamp progress here too as a safety net
          progress: progress.clamp(0.0, 1.0),
          gradient: _gradient(),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(timeText,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: _color())),
              const SizedBox(height: 12),
              if (sessionType == SessionType.focus)
                _pomodoroIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pomodoroIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < (completedPomodoros % 4);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppTheme.focusRed : AppTheme.textSecondary.withValues(alpha: 0.25),
            ),
          ),
        );
      }),
    );
  }

  LinearGradient _gradient() => switch (sessionType) {
    SessionType.focus      => AppTheme.getFocusGradient(),
    SessionType.shortBreak => AppTheme.getBreakGradient(),
    SessionType.longBreak  => AppTheme.getLongBreakGradient(),
  };

  Color _color() => switch (sessionType) {
    SessionType.focus      => AppTheme.focusRed,
    SessionType.shortBreak => AppTheme.breakGreen,
    SessionType.longBreak  => AppTheme.longBreakPurple,
  };
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final LinearGradient gradient;

  const _TimerPainter({ required this.progress, required this.gradient });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const sw = 12.0;

    // Background track
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round);

    // Progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  // FIX: also repaint when gradient changes (e.g. switching session type)
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.gradient != gradient;
}
