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
              color: filled ? AppTheme.focusRed : AppTheme.textSecondary.withOpacity(0.25),
            ),
          ),
        );
      }),
    );
  }

  LinearGradient _gradient() {
    switch (sessionType) {
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

  Color _color() {
    switch (sessionType) {
      case SessionType.focus:
        return AppTheme.focusRed;
      case SessionType.shortBreak:
        return AppTheme.breakGreen;
      case SessionType.longBreak:
        return AppTheme.longBreakPurple;
      case SessionType.stopwatch:
        return const Color(0xFFF59E0B);
      case SessionType.countdown:
        return const Color(0xFFEF4444);
      case SessionType.candle:
        return const Color(0xFFFF9F1C);
      case SessionType.ice:
        return const Color(0xFF4FC3F7);
    }
  }
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

    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round);

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
  bool shouldRepaint(_TimerPainter old) =>
      old.progress != progress || old.gradient != gradient;
}