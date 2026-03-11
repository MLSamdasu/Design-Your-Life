// AchievementChecker 순수 함수 테스트
// 조건별 달성 여부, 이미 달성한 업적 필터링, 복합 조건 등을 검증한다.
import 'package:design_your_life/features/achievement/services/achievement_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AchievementChecker - 스트릭 업적', () {
    test('longestHabitStreak가 7 이상이면 streak_7 업적을 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 0,
        longestHabitStreak: 7,
        totalHabitsCreated: 0,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('streak_7'), true);
    });

    test('longestHabitStreak가 6이면 streak_7 업적을 반환하지 않는다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 0,
        longestHabitStreak: 6,
        totalHabitsCreated: 0,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('streak_7'), false);
    });

    test('longestHabitStreak 100이면 streak_7, streak_30, streak_100 모두 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 0,
        longestHabitStreak: 100,
        totalHabitsCreated: 0,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('streak_7'), true);
      expect(ids.contains('streak_30'), true);
      expect(ids.contains('streak_100'), true);
    });
  });

  group('AchievementChecker - 완료 업적', () {
    test('totalCompletedTodos가 1이면 todo_first 업적을 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 1,
        longestHabitStreak: 0,
        totalHabitsCreated: 0,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('todo_first'), true);
    });

    test('totalCompletedTodos가 500이면 todo_first, todo_50, todo_100, todo_500을 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 500,
        longestHabitStreak: 0,
        totalHabitsCreated: 0,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('todo_first'), true);
      expect(ids.contains('todo_50'), true);
      expect(ids.contains('todo_100'), true);
      expect(ids.contains('todo_500'), true);
    });
  });

  group('AchievementChecker - 마일스톤 업적', () {
    test('totalHabitsCreated가 1이면 habit_first 업적을 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 0,
        longestHabitStreak: 0,
        totalHabitsCreated: 1,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('habit_first'), true);
    });

    test('totalGoalsCreated가 1이면 goal_first 업적을 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 0,
        longestHabitStreak: 0,
        totalHabitsCreated: 0,
        totalGoalsCreated: 1,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('goal_first'), true);
    });
  });

  group('AchievementChecker - 특별 업적', () {
    test('completedMandalarts가 1이면 mandalart_first 업적을 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 0,
        longestHabitStreak: 0,
        totalHabitsCreated: 0,
        totalGoalsCreated: 0,
        completedMandalarts: 1,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('mandalart_first'), true);
    });

    test('allHabitsCompletedToday가 true이면 all_habits_day 업적을 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 0,
        longestHabitStreak: 0,
        totalHabitsCreated: 0,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: true,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('all_habits_day'), true);
    });

    test('isEarlyBird가 true이면 early_bird 업적을 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 0,
        longestHabitStreak: 0,
        totalHabitsCreated: 0,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: true,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      expect(ids.contains('early_bird'), true);
    });
  });

  group('AchievementChecker - 이미 달성한 업적 필터링', () {
    test('alreadyUnlockedIds에 있는 업적은 반환하지 않는다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {'todo_first', 'habit_first'},
        totalCompletedTodos: 1,
        longestHabitStreak: 0,
        totalHabitsCreated: 1,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      final ids = newAchievements.map((d) => d.id).toSet();
      // 이미 달성한 업적은 포함되지 않는다
      expect(ids.contains('todo_first'), false);
      expect(ids.contains('habit_first'), false);
    });

    test('모든 업적이 이미 달성됐으면 빈 목록을 반환한다', () {
      // 모든 업적 ID를 이미 달성한 것으로 설정한다
      final allIds = {'streak_7', 'streak_30', 'streak_100',
        'todo_first', 'todo_50', 'todo_100', 'todo_500',
        'habit_first', 'goal_first',
        'mandalart_first', 'all_habits_day', 'early_bird'};

      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: allIds,
        totalCompletedTodos: 500,
        longestHabitStreak: 100,
        totalHabitsCreated: 10,
        totalGoalsCreated: 10,
        completedMandalarts: 5,
        allHabitsCompletedToday: true,
        isEarlyBird: true,
      );

      expect(newAchievements, isEmpty);
    });
  });

  group('AchievementChecker - 빈 상태', () {
    test('모든 값이 0이고 false이면 빈 목록을 반환한다', () {
      final newAchievements = AchievementChecker.checkNewAchievements(
        alreadyUnlockedIds: {},
        totalCompletedTodos: 0,
        longestHabitStreak: 0,
        totalHabitsCreated: 0,
        totalGoalsCreated: 0,
        completedMandalarts: 0,
        allHabitsCompletedToday: false,
        isEarlyBird: false,
      );

      expect(newAchievements, isEmpty);
    });
  });
}
