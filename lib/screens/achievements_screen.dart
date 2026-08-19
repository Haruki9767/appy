import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/storage_service.dart';
import '../services/statistics_service.dart';
import '../services/achievement_service.dart';
import '../theme/app_theme.dart';
import '../models/achievement.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  List<Achievement> _achievements = [];
  // Map of achievementId -> ISO unlock timestamp (real stored date, not DateTime.now())
  Map<String, String> _unlockedAtMap = {};
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadAchievements();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);

    final allAchievements = AchievementService.getAllAchievements();

    // Load the stored list of unlocked IDs
    final unlockedIds = await StorageService.getUnlockedAchievements();

    // Load stored unlock timestamps (key: "unlockedAt_<id>")
    // FIX: read the real persisted timestamp instead of overwriting with DateTime.now()
    final Map<String, String> unlockedAtMap = {};
    for (final id in unlockedIds) {
      final stored = StorageService.getSetting<String>('unlockedAt_$id', '');
      if (stored.isNotEmpty) {
        unlockedAtMap[id] = stored;
      } else {
        // First time we see this id without a timestamp: stamp it now and save
        final now = DateTime.now().toIso8601String();
        await StorageService.setSetting('unlockedAt_$id', now);
        unlockedAtMap[id] = now;
      }
    }

    setState(() {
      _unlockedAtMap = unlockedAtMap;
      _achievements = allAchievements.map((a) {
        final isUnlocked = unlockedIds.contains(a.id);
        return a.copyWith(
          unlocked: isUnlocked,
          // FIX: use the persisted timestamp, never DateTime.now() on every rebuild
          unlockedAt: isUnlocked ? unlockedAtMap[a.id] : null,
        );
      }).toList();
      _isLoading = false;
    });

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _achievements.where((a) => a.unlocked).length;
    final total = _achievements.length;

    // FIX: guard against empty list to avoid division by zero / NaN
    final progressValue = total == 0 ? 0.0 : (unlockedCount / total).clamp(0.0, 1.0);
    final progressPercent = total == 0 ? 0 : (unlockedCount / total * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: Column(
        children: [
          // Progress header card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.getFocusGradient(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🏆 Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$unlockedCount / $total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$progressPercent% Complete',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimationLimiter(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _achievements.length,
                      itemBuilder: (context, index) {
                        final achievement = _achievements[index];
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          columnCount: 2,
                          duration: const Duration(milliseconds: 500),
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: _buildAchievementCard(achievement),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.unlocked;

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.focusRed.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppTheme.focusRed.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppTheme.focusRed.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: TextStyle(
                        fontSize: isUnlocked ? 28 : 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: isUnlocked
                        ? AppTheme.textSecondary
                        : AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                // Show real unlock date
                if (isUnlocked && achievement.unlockedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatUnlockDate(achievement.unlockedAt!),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.successGreen.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          // Lock / check badge
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isUnlocked ? AppTheme.successGreen : AppTheme.textSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? Icons.check : Icons.lock,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatUnlockDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
