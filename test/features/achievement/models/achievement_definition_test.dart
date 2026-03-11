// AchievementDef 단위 테스트
// 업적 정의 목록의 완전성, 유일성, 필드 유효성을 검증한다.
import 'package:design_your_life/features/achievement/models/achievement_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AchievementDef.all - 목록 유효성', () {
    test('업적 정의 목록이 정확히 12개다', () {
      expect(AchievementDef.all.length, 12);
    });

    test('모든 업적 ID가 유일하다', () {
      final ids = AchievementDef.all.map((def) => def.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length);
    });

    test('모든 업적의 xpReward가 0보다 크다', () {
      for (final def in AchievementDef.all) {
        expect(def.xpReward, greaterThan(0),
            reason: '${def.id}의 xpReward가 0 이하입니다');
      }
    });

    test('모든 업적의 iconName이 비어있지 않다', () {
      for (final def in AchievementDef.all) {
        expect(def.iconName.isNotEmpty, true,
            reason: '${def.id}의 iconName이 비어있습니다');
      }
    });

    test('모든 업적의 title이 비어있지 않다', () {
      for (final def in AchievementDef.all) {
        expect(def.title.isNotEmpty, true,
            reason: '${def.id}의 title이 비어있습니다');
      }
    });

    test('모든 업적의 condition.threshold가 0보다 크다', () {
      for (final def in AchievementDef.all) {
        expect(def.condition.threshold, greaterThan(0),
            reason: '${def.id}의 threshold가 0 이하입니다');
      }
    });
  });

  group('AchievementDef - 스트릭 업적', () {
    test('streak_7 업적이 올바르게 정의된다', () {
      final def = AchievementDef.all.firstWhere((d) => d.id == 'streak_7');

      expect(def.type, 'streak');
      expect(def.title, '일주일 전사');
      expect(def.iconName, '🔥');
      expect(def.xpReward, 50);
      expect(def.condition.type, 'streak_days');
      expect(def.condition.threshold, 7);
    });

    test('streak_30 업적이 올바르게 정의된다', () {
      final def = AchievementDef.all.firstWhere((d) => d.id == 'streak_30');

      expect(def.type, 'streak');
      expect(def.xpReward, 200);
      expect(def.condition.threshold, 30);
    });

    test('streak_100 업적이 올바르게 정의된다', () {
      final def = AchievementDef.all.firstWhere((d) => d.id == 'streak_100');

      expect(def.xpReward, 500);
      expect(def.condition.threshold, 100);
    });
  });

  group('AchievementDef - 완료 업적', () {
    test('todo_first 업적이 올바르게 정의된다', () {
      final def = AchievementDef.all.firstWhere((d) => d.id == 'todo_first');

      expect(def.type, 'completion');
      expect(def.xpReward, 10);
      expect(def.condition.type, 'total_todos');
      expect(def.condition.threshold, 1);
    });

    test('todo_500 업적이 올바르게 정의된다', () {
      final def = AchievementDef.all.firstWhere((d) => d.id == 'todo_500');

      expect(def.xpReward, 500);
      expect(def.condition.threshold, 500);
    });
  });

  group('AchievementDef - 마일스톤 업적', () {
    test('habit_first 업적이 올바르게 정의된다', () {
      final def = AchievementDef.all.firstWhere((d) => d.id == 'habit_first');

      expect(def.type, 'milestone');
      expect(def.iconName, '🌱');
      expect(def.xpReward, 10);
    });

    test('goal_first 업적이 올바르게 정의된다', () {
      final def = AchievementDef.all.firstWhere((d) => d.id == 'goal_first');

      expect(def.type, 'milestone');
      expect(def.condition.type, 'total_goals');
    });
  });

  group('AchievementDef - 특별 업적', () {
    test('mandalart_first 업적이 올바르게 정의된다', () {
      final def =
          AchievementDef.all.firstWhere((d) => d.id == 'mandalart_first');

      expect(def.type, 'special');
      expect(def.xpReward, 200);
      expect(def.condition.type, 'total_mandalarts');
    });

    test('early_bird 업적이 올바르게 정의된다', () {
      final def = AchievementDef.all.firstWhere((d) => d.id == 'early_bird');

      expect(def.type, 'special');
      expect(def.xpReward, 30);
      expect(def.condition.type, 'early_bird');
    });
  });

  group('AchievementDef - 타입별 분류', () {
    test('streak 타입 업적이 3개다', () {
      final streakDefs = AchievementDef.all.where((d) => d.type == 'streak');
      expect(streakDefs.length, 3);
    });

    test('completion 타입 업적이 4개다', () {
      final completionDefs =
          AchievementDef.all.where((d) => d.type == 'completion');
      expect(completionDefs.length, 4);
    });

    test('milestone 타입 업적이 2개다', () {
      final milestoneDefs =
          AchievementDef.all.where((d) => d.type == 'milestone');
      expect(milestoneDefs.length, 2);
    });

    test('special 타입 업적이 3개다', () {
      final specialDefs = AchievementDef.all.where((d) => d.type == 'special');
      expect(specialDefs.length, 3);
    });
  });
}
