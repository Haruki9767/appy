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
    final gradient = _getGradient();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _getMainColor().withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 20,
            offset: const Offset(-10, -10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CircularTimerPainter(
          progress: progress,
          gradient: gradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timeText,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: _getMainColor(),
                    ),
              ),
              const SizedBox(height: 16),
              if (sessionType == SessionType.focus)
                _buildPomodoroIndicators(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isCompleted = index < (completedPomodoros % 4);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppTheme.focusRed : AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }

  LinearGradient _getGradient() {
    switch (sessionType) {
      case SessionType.focus:
        return AppTheme.getFocusGradient();
      case SessionType.shortBreak:
        return AppTheme.getBreakGradient();
      case SessionType.longBreak:
        return AppTheme.getLongBreakGradient();
    }
  }

  Color _getMainColor() {
    switch (sessionType) {
      case SessionType.focus:
        return AppTheme.focusRed;
      case SessionType.shortBreak:
        return AppTheme.breakGreen;
      case SessionType.longBreak:
        return AppTheme.longBreakPurple;
    }
  }
}

class CircularTimerPainter extends CustomPainter {
  final double progress;
  final LinearGradient gradient;

  CircularTimerPainter({
    required this.progress,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw background circle
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final progressPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
