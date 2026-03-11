// F8: AchievementChecker - 순수 함수
// StreakCalculator 패턴을 따르는 외부 상태 비의존 순수 계산 모듈이다.
// 현재 사용자 통계와 업적 정의 목록을 비교하여 새로 달성할 업적을 반환한다.

import '../models/achievement_definition.dart';

/// 업적 달성 여부를 검사하는 순수 함수 모듈 (F8 AchievementChecker)
/// 외부 상태(서버, 날짜 등)에 의존하지 않는 순수 계산 모듈이다
abstract class AchievementChecker {
  /// 새로 달성한 업적 목록을 반환한다
  ///
  /// - [alreadyUnlockedIds]: 이미 달성한 업적 ID 집합
  /// - [totalCompletedTodos]: 전체 완료한 투두 수
  /// - [longestHabitStreak]: 습관 최장 연속 달성 일수
  /// - [totalHabitsCreated]: 생성한 습관 수
  /// - [totalGoalsCreated]: 생성한 목표 수
  /// - [completedMandalarts]: 완성한 만다라트 수
  /// - [allHabitsCompletedToday]: 오늘 모든 습관을 달성했는지 여부
  /// - [isEarlyBird]: 오전 6시 이전 접속 여부
  static List<AchievementDef> checkNewAchievements({
    required Set<String> alreadyUnlockedIds,
    required int totalCompletedTodos,
    required int longestHabitStreak,
    required int totalHabitsCreated,
    required int totalGoalsCreated,
    required int completedMandalarts,
    required bool allHabitsCompletedToday,
    required bool isEarlyBird,
  }) {
    final newAchievements = <AchievementDef>[];

    for (final def in AchievementDef.all) {
      // 이미 달성한 업적은 건너뛴다
      if (alreadyUnlockedIds.contains(def.id)) continue;

      // 조건 유형별로 달성 여부를 판별한다
      final isAchieved = _isConditionMet(
        condition: def.condition,
        totalCompletedTodos: totalCompletedTodos,
        longestHabitStreak: longestHabitStreak,
        totalHabitsCreated: totalHabitsCreated,
        totalGoalsCreated: totalGoalsCreated,
        completedMandalarts: completedMandalarts,
        allHabitsCompletedToday: allHabitsCompletedToday,
        isEarlyBird: isEarlyBird,
      );

      if (isAchieved) {
        newAchievements.add(def);
      }
    }

    return newAchievements;
  }

  /// 조건 유형에 따라 달성 여부를 판별한다
  static bool _isConditionMet({
    required AchievementCondition condition,
    required int totalCompletedTodos,
    required int longestHabitStreak,
    required int totalHabitsCreated,
    required int totalGoalsCreated,
    required int completedMandalarts,
    required bool allHabitsCompletedToday,
    required bool isEarlyBird,
  }) {
    switch (condition.type) {
      // 스트릭 연속 달성 일수 조건
      case 'streak_days':
        return longestHabitStreak >= condition.threshold;

      // 투두 완료 수 조건
      case 'total_todos':
        return totalCompletedTodos >= condition.threshold;

      // 습관 생성 수 조건
      case 'total_habits':
        return totalHabitsCreated >= condition.threshold;

      // 목표 생성 수 조건
      case 'total_goals':
        return totalGoalsCreated >= condition.threshold;

      // 만다라트 완성 수 조건
      case 'total_mandalarts':
        return completedMandalarts >= condition.threshold;

      // 오늘 모든 습관 달성 조건
      case 'all_habits_today':
        return allHabitsCompletedToday;

      // 얼리버드 조건 (오전 6시 이전 접속)
      case 'early_bird':
        return isEarlyBird;

      // 알 수 없는 조건 유형은 달성 불가로 처리한다
      default:
        return false;
    }
  }
}
