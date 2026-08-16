import '../models/achievement.dart';
import 'storage_service.dart';

class AchievementService {
  static List<Achievement> _allAchievements = [];

  static List<Achievement> getAllAchievements() {
    if (_allAchievements.isEmpty) {
      _allAchievements = _createAchievements();
    }
    return _allAchievements;
  }

  static List<Achievement> _createAchievements() {
    return [
      // Hour-based achievements (15 achievements)
      Achievement(id: 'hour_1', icon: '⏱️', title: 'Hour One', description: 'Reach 1 total hour of focus', category: 'hour', requiredValue: 1),
      Achievement(id: 'hour_10', icon: '📚', title: 'Bookworm', description: 'Reach 10 total hours', category: 'hour', requiredValue: 10),
      Achievement(id: 'hour_25', icon: '🔥', title: 'On Fire', description: 'Reach 25 total hours', category: 'hour', requiredValue: 25),
      Achievement(id: 'hour_50', icon: '💎', title: 'Diamond Mind', description: 'Reach 50 total hours', category: 'hour', requiredValue: 50),
      Achievement(id: 'hour_100', icon: '🏆', title: 'Centurion', description: 'Reach 100 total hours', category: 'hour', requiredValue: 100),
      Achievement(id: 'hour_150', icon: '⭐', title: 'Rising Star', description: 'Reach 150 total hours', category: 'hour', requiredValue: 150),
      Achievement(id: 'hour_200', icon: '🎯', title: 'Focused', description: 'Reach 200 total hours', category: 'hour', requiredValue: 200),
      Achievement(id: 'hour_300', icon: '🚀', title: 'Accelerator', description: 'Reach 300 total hours', category: 'hour', requiredValue: 300),
      Achievement(id: 'hour_400', icon: '📖', title: 'Scholar', description: 'Reach 400 total hours', category: 'hour', requiredValue: 400),
      Achievement(id: 'hour_500', icon: '🧠', title: 'Master Mind', description: 'Reach 500 total hours', category: 'hour', requiredValue: 500),
      Achievement(id: 'hour_600', icon: '🏅', title: 'Olympian', description: 'Reach 600 total hours', category: 'hour', requiredValue: 600),
      Achievement(id: 'hour_700', icon: '👑', title: 'The Crown', description: 'Reach 700 total hours', category: 'hour', requiredValue: 700),
      Achievement(id: 'hour_800', icon: '💫', title: 'Legendary', description: 'Reach 800 total hours', category: 'hour', requiredValue: 800),
      Achievement(id: 'hour_900', icon: '🌟', title: 'Supernova', description: 'Reach 900 total hours', category: 'hour', requiredValue: 900),
      Achievement(id: 'hour_1000', icon: '🎖️', title: 'The One', description: 'Reach 1000 total hours', category: 'hour', requiredValue: 1000),
      
      // Streak achievements
      Achievement(id: 'first_session', icon: '🌱', title: 'First Step', description: 'Complete your first focus session', category: 'special', requiredValue: 1),
      Achievement(id: 'streak_7', icon: '⚡', title: 'Week Warrior', description: 'Study 7 days in a row', category: 'streak', requiredValue: 7),
      Achievement(id: 'streak_30', icon: '🌟', title: 'Consistency King', description: 'Study 30 days in a row', category: 'streak', requiredValue: 30),
      
      // Special achievements
      Achievement(id: 'early_bird', icon: '🌅', title: 'Early Bird', description: 'Start a session before 6 AM', category: 'special', requiredValue: 1),
      Achievement(id: 'night_owl', icon: '🦉', title: 'Night Owl', description: 'Study past midnight', category: 'special', requiredValue: 1),
      Achievement(id: 'marathon', icon: '🏃', title: 'Marathon', description: 'Study 3+ hours in one session', category: 'special', requiredValue: 180),
      Achievement(id: 'goal_crusher', icon: '💪', title: 'Goal Crusher', description: 'Meet your daily goal 7 days in a row', category: 'special', requiredValue: 7),
      Achievement(id: 'monthly_master', icon: '📅', title: 'Monthly Master', description: 'Study 30 days in a single month', category: 'special', requiredValue: 30),
      Achievement(id: 'yearly_legend', icon: '🗓️', title: 'Yearly Legend', description: 'Study for 365 days in a year', category: 'special', requiredValue: 365),
      Achievement(id: 'consistency_champion', icon: '🏅', title: 'Consistency Champion', description: 'Study 5 days a week for 4 weeks', category: 'special', requiredValue: 20),
      Achievement(id: 'weekend_warrior', icon: '🎮', title: 'Weekend Warrior', description: 'Study 5+ hours on a weekend', category: 'special', requiredValue: 300),
    ];
  }

  static Future<List<String>> checkAndUnlockAchievements({
    required int totalHours,
    required int streakDays,
    required int completedSessions,
    required int maxSessionMinutes,
    required bool hasEarlyBird,
    required bool hasNightOwl,
    required int monthlyStudyDays,
    required int yearlyStudyDays,
    required int weekendMinutes,
  }) async {
    final allAchievements = getAllAchievements();
    final unlocked = await StorageService.getUnlockedAchievements();
    final newlyUnlocked = <String>[];

    for (final achievement in allAchievements) {
      if (unlocked.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.category) {
        case 'hour':
          shouldUnlock = totalHours >= achievement.requiredValue;
          break;
        case 'streak':
          shouldUnlock = streakDays >= achievement.requiredValue;
          break;
        case 'special':
          switch (achievement.id) {
            case 'first_session':
              shouldUnlock = completedSessions >= 1;
              break;
            case 'early_bird':
              shouldUnlock = hasEarlyBird;
              break;
            case 'night_owl':
              shouldUnlock = hasNightOwl;
              break;
            case 'marathon':
              shouldUnlock = maxSessionMinutes >= 180;
              break;
            case 'goal_crusher':
              shouldUnlock = streakDays >= 7;
              break;
            case 'monthly_master':
              shouldUnlock = monthlyStudyDays >= 30;
              break;
            case 'yearly_legend':
              shouldUnlock = yearlyStudyDays >= 365;
              break;
            case 'consistency_champion':
              shouldUnlock = streakDays >= 20;
              break;
            case 'weekend_warrior':
              shouldUnlock = weekendMinutes >= 300;
              break;
          }
          break;
      }

      if (shouldUnlock) {
        newlyUnlocked.add(achievement.id);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await StorageService.saveUnlockedAchievements([...unlocked, ...newlyUnlocked]);
    }

    return newlyUnlocked;
  }

  static String getAchievementTitle(String id) {
    final achievement = _allAchievements.firstWhere(
      (a) => a.id == id,
      orElse: () => _allAchievements.first,
    );
    return achievement.title;
  }

  static String getAchievementIcon(String id) {
    final achievement = _allAchievements.firstWhere(
      (a) => a.id == id,
      orElse: () => _allAchievements.first,
    );
    return achievement.icon;
  }
}