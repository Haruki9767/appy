import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  List<Achievement> _achievements = [];
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
    
    // Get all achievements with their unlock status
    final allAchievements = AchievementService.getAllAchievements();
    final unlockedIds = await StorageService.getUnlockedAchievements();
    
    setState(() {
      _achievements = allAchievements.map((a) {
        final isUnlocked = unlockedIds.contains(a.id);
        return a.copyWith(
          unlocked: isUnlocked,
          unlockedAt: isUnlocked ? DateTime.now().toIso8601String() : null,
        );
      }).toList();
      _isLoading = false;
    });
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final totalStats = StatisticsService.getTotalStats();
    final totalHours = totalStats['totalFocusHours'] as int;
    final unlockedCount = _achievements.where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: Column(
        children: [
          // Progress header
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
                      '$unlockedCount / ${_achievements.length}',
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
                    value: unlockedCount / _achievements.length,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(unlockedCount / _achievements.length * 100).round()}% Complete',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Achievements grid
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
          color: isUnlocked ? AppTheme.focusRed.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: isUnlocked ? [
          BoxShadow(
            color: AppTheme.focusRed.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
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
                        opacity: isUnlocked ? 1 : 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Title
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
                // Description
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: isUnlocked ? AppTheme.textSecondary : AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Locked overlay
          if (!isUnlocked)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.textSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          // Unlocked badge
          if (isUnlocked)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.successGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}