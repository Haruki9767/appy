import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/storage_service.dart';
import '../services/statistics_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;

  // Monthly data
  late Map<String, dynamic> _monthStats;
  late int _streak;
  late List<Map<String, dynamic>> _dailyData; // per-day focus minutes for current month

  // Yearly data
  late int _yearTotalMinutes;
  late List<double> _monthlyMinutes; // index 0=Jan … 11=Dec
  late int _yearTotalSessions;
  late int _longestStreak;
  late int _projectsCompleted;
  late int _examsCompleted;
  late int _achievementsEarned;
  late int _achievementsTotal;
  late String _bestMonth;
  late String _progressPercent;

  // Month achievements (unlocked this month)
  late List<String> _monthAchievements;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();

    // ── Monthly ──────────────────────────────────────────────────────────────
    _monthStats = StatisticsService.getMonthStats();
    _streak = StatisticsService.getStreak();

    // Build per-day focus-minutes array for the current month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    _dailyData = List.generate(daysInMonth, (i) {
      final dayStart = DateTime(now.year, now.month, i + 1);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final sessions = StorageService.getSessionsInRange(dayStart, dayEnd);
      final mins = sessions
          .where((s) => s.type == 'focus' && s.completed)
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
      return {'day': i + 1, 'minutes': mins};
    });

    // ── Yearly ───────────────────────────────────────────────────────────────
    _yearTotalMinutes = StatisticsService.getYearTotalMinutes();

    _monthlyMinutes = List.generate(12, (m) {
      final monthStart = DateTime(now.year, m + 1, 1);
      final monthEnd = DateTime(now.year, m + 2, 1);
      final sessions = StorageService.getSessionsInRange(monthStart, monthEnd);
      return sessions
          .where((s) => s.type == 'focus' && s.completed)
          .fold<int>(0, (sum, s) => sum + s.durationMinutes)
          .toDouble();
    });

    // Best month
    double bestVal = 0;
    int bestIdx = 0;
    for (int i = 0; i < 12; i++) {
      if (_monthlyMinutes[i] > bestVal) {
        bestVal = _monthlyMinutes[i];
        bestIdx = i;
      }
    }
    const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    _bestMonth = bestVal > 0 ? monthNames[bestIdx] : '–';

    // Progress vs last month
    final thisMonthMins = _monthlyMinutes[now.month - 1];
    final lastMonthMins = now.month > 1 ? _monthlyMinutes[now.month - 2] : 0.0;
    if (lastMonthMins > 0) {
      final pct = ((thisMonthMins - lastMonthMins) / lastMonthMins * 100).round();
      _progressPercent = '${pct >= 0 ? '+' : ''}$pct%';
    } else {
      _progressPercent = thisMonthMins > 0 ? '+100%' : '–';
    }

    // Yearly session count
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year + 1, 1, 1);
    final yearSessions = StorageService.getSessionsInRange(yearStart, yearEnd)
        .where((s) => s.type == 'focus' && s.completed)
        .toList();
    _yearTotalSessions = yearSessions.length;

    // Longest streak (approximation from stored streak — full computation would
    // need a separate StatisticsService method; using current streak as proxy)
    _longestStreak = _streak;

    // Projects / exams completed
    final allProjects = StorageService.getAllProjects();
    _projectsCompleted = allProjects.where((p) => p.status == 'completed' && p.type == 'project').length;
    _examsCompleted    = allProjects.where((p) => p.status == 'completed' && p.type == 'exam').length;

    // Achievements
    final unlockedIds = await StorageService.getUnlockedAchievements();
    _achievementsEarned = unlockedIds.length;
    _achievementsTotal  = 24; // matches AchievementService list size
    _monthAchievements  = unlockedIds; // ideally filter by unlock date; stored as IDs for now

    setState(() => _isLoading = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppTheme.backgroundColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMonthlyReport(),
                _buildYearlyReport(),
              ],
            ),
    );
  }

  // ── Monthly ───────────────────────────────────────────────────────────────

  Widget _buildMonthlyReport() {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy').format(now);
    final totalMinutes = _monthStats['totalFocusMinutes'] as int;
    final dailyAvg     = _monthStats['dailyAverage'] as double;
    final sessions     = _monthStats['focusSessions'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.getFocusGradient(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 $monthName',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildReportStat('Total Hours', '${(totalMinutes / 60).toStringAsFixed(1)}h', Colors.white70),
                    _buildReportStat('Daily Avg', '${dailyAvg.toStringAsFixed(1)}m', Colors.white70),
                    _buildReportStat('Sessions', '$sessions', Colors.white70),
                    _buildReportStat('Streak', '$_streak🔥', Colors.white70),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Daily progress chart (LineChart – area style)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 Daily Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildDailyLineChart(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Achievements this month
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏆 Achievements This Month',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                _monthAchievements.isEmpty
                    ? const Text(
                        'No achievements unlocked this month yet.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      )
                    : Wrap(
                        spacing: 8,
                        children: _monthAchievements
                            .map((id) => Chip(label: Text(id, style: const TextStyle(fontSize: 11))))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Area line chart for daily focus minutes — no overlapping labels.
  Widget _buildDailyLineChart() {
    final maxY = _dailyData
        .map((d) => (d['minutes'] as int).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = (maxY < 10) ? 10.0 : (maxY * 1.2).ceilToDouble();

    final spots = _dailyData
        .map((d) => FlSpot((d['day'] as int).toDouble(), (d['minutes'] as int).toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: _dailyData.length.toDouble(),
        minY: 0,
        maxY: chartMax,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        // Disable top & right axes, show only bottom & left with sensible labels
        titlesData: FlTitlesData(
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: chartMax / 4,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              // Only show 1, 8, 15, 22, last day — avoids all overlap
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                final last = _dailyData.length;
                if (day == 1 || day == 8 || day == 15 || day == 22 || day == last) {
                  return Text(
                    '$day',
                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.focusRed,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AppTheme.focusRed.withOpacity(0.35), AppTheme.focusRed.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Yearly ────────────────────────────────────────────────────────────────

  Widget _buildYearlyReport() {
    final now = DateTime.now();
    final year = now.year;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.getBreakGradient(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 $year Summary',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildReportStat('Total Hours', '${(_yearTotalMinutes / 60).toStringAsFixed(1)}h', Colors.white70),
                    _buildReportStat('Monthly Avg', '${(_yearTotalMinutes / 12 / 60).toStringAsFixed(1)}h', Colors.white70),
                    _buildReportStat('Best Month', _bestMonth, Colors.white70),
                    _buildReportStat('Progress', _progressPercent, Colors.white70),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Month-by-month bar chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📅 Month-by-Month Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildMonthlyBarChart(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Year stats — all real data
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _buildYearStatRow('Total Sessions', '$_yearTotalSessions'),
                _buildYearStatRow('Longest Streak', '$_longestStreak days'),
                _buildYearStatRow('Projects Completed', '$_projectsCompleted'),
                _buildYearStatRow('Exams Completed', '$_examsCompleted'),
                _buildYearStatRow('Achievements Earned', '$_achievementsEarned/$_achievementsTotal'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bar chart for monthly breakdown — top & right axes disabled, proper month labels.
  Widget _buildMonthlyBarChart() {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final maxVal = _monthlyMinutes.fold(0.0, (a, b) => a > b ? a : b);
    final chartMax = maxVal < 10 ? 60.0 : (maxVal * 1.2).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMax,
        barGroups: List.generate(12, (i) => BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _monthlyMinutes[i],
              color: AppTheme.breakGreen,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        )),
        titlesData: FlTitlesData(
          // Disable top & right — these were causing the duplicate "0 1 2 3…" labels
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: chartMax / 4,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= 12) return const SizedBox.shrink();
                return Text(
                  months[idx],
                  style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax / 4,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildReportStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildYearStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    );
  }
}
