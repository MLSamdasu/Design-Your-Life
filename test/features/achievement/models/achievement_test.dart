// Achievement 모델 단위 테스트
// fromMap, toMap, copyWith 메서드와 파싱 에러 처리를 검증한다.
// Supabase user_achievements 테이블 대응 — snake_case 컬럼명 사용
import 'package:design_your_life/features/achievement/models/achievement.dart';
import 'package:flutter_test/flutter_test.dart';

/// 테스트용 Achievement Map 데이터를 생성한다
Map<String, dynamic> _createAchievementMap({
  String userId = 'user-1',
  String type = 'streak',
  String title = '일주일 전사',
  String description = '7일 연속으로 습관을 달성하세요',
  String iconName = '🔥',
  int xpReward = 50,
  DateTime? unlockedAt,
  DateTime? createdAt,
}) {
  final base = DateTime(2026, 3, 9);
  return {
    'user_id': userId,
    'type': type,
    'title': title,
    'description': description,
    'icon_name': iconName,
    'xp_reward': xpReward,
    'unlocked_at': (unlockedAt ?? base).toIso8601String(),
    'created_at': (createdAt ?? base).toIso8601String(),
  };
}

void main() {
  group('Achievement.fromMap', () {
    test('올바른 Map에서 Achievement 객체를 생성한다', () {
      final map = _createAchievementMap();

      final achievement = Achievement.fromMap({...map, 'id': 'streak_7'});

      expect(achievement.id, 'streak_7');
      expect(achievement.userId, 'user-1');
      expect(achievement.type, 'streak');
      expect(achievement.title, '일주일 전사');
      expect(achievement.description, '7일 연속으로 습관을 달성하세요');
      expect(achievement.iconName, '🔥');
      expect(achievement.xpReward, 50);
    });

    test('unlockedAt이 DateTime으로 변환된다', () {
      final targetDate = DateTime(2026, 3, 1);
      final map = _createAchievementMap(unlockedAt: targetDate);

      final achievement = Achievement.fromMap({...map, 'id': 'streak_7'});

      expect(achievement.unlockedAt, targetDate);
    });

    test('createdAt이 DateTime으로 변환된다', () {
      final targetDate = DateTime(2026, 1, 15);
      final map = _createAchievementMap(createdAt: targetDate);

      final achievement = Achievement.fromMap({...map, 'id': 'streak_7'});

      expect(achievement.createdAt, targetDate);
    });

    test('userId가 int 타입이어도 toString()으로 변환된다', () {
      // Supabase 마이그레이션 후 userId는 toString()으로 처리한다
      final badMap = {
        'user_id': 123,
        'type': 'streak',
        'title': '일주일 전사',
        'description': '설명',
        'icon_name': '🔥',
        'xp_reward': 50,
        'unlocked_at': DateTime(2026, 3, 9).toIso8601String(),
        'created_at': DateTime(2026, 3, 9).toIso8601String(),
      };

      // int userId도 toString()으로 정상 처리된다
      final achievement = Achievement.fromMap({...badMap, 'id': 'streak_7'});
      expect(achievement.userId, '123');
    });

    test('completion 타입 업적을 올바르게 파싱한다', () {
      final map = _createAchievementMap(
        type: 'completion',
        title: '첫 걸음',
        iconName: '✅',
        xpReward: 10,
      );

      final achievement = Achievement.fromMap({...map, 'id': 'todo_first'});

      expect(achievement.type, 'completion');
      expect(achievement.xpReward, 10);
    });
  });

  group('Achievement.toMap', () {
    test('Achievement 객체를 snake_case Map으로 변환한다', () {
      final now = DateTime(2026, 3, 9);
      final achievement = Achievement(
        id: 'streak_7',
        userId: 'user-1',
        type: 'streak',
        title: '일주일 전사',
        description: '7일 연속으로 습관을 달성하세요',
        iconName: '🔥',
        xpReward: 50,
        unlockedAt: now,
        createdAt: now,
      );

      final map = achievement.toMap();

      // toMap은 toInsertMap(userId) 별칭 — snake_case 키를 반환한다
      expect(map['user_id'], 'user-1');
      expect(map['type'], 'streak');
      expect(map['title'], '일주일 전사');
      expect(map['icon_name'], '🔥');
      expect(map['xp_reward'], 50);
      // unlocked_at은 ISO 8601 문자열로 반환된다
      expect(map['unlocked_at'], isA<String>());
    });
  });

  group('Achievement.copyWith', () {
    test('지정한 필드만 변경된다', () {
      final now = DateTime(2026, 3, 9);
      final original = Achievement(
        id: 'streak_7',
        userId: 'user-1',
        type: 'streak',
        title: '일주일 전사',
        description: '원본 설명',
        iconName: '🔥',
        xpReward: 50,
        unlockedAt: now,
        createdAt: now,
      );

      final updated = original.copyWith(title: '수정된 제목', xpReward: 100);

      // 변경된 필드
      expect(updated.title, '수정된 제목');
      expect(updated.xpReward, 100);
      // 변경되지 않은 필드
      expect(updated.id, 'streak_7');
      expect(updated.userId, 'user-1');
      expect(updated.type, 'streak');
      expect(updated.description, '원본 설명');
      expect(updated.iconName, '🔥');
    });

    test('copyWith에 null을 전달하면 원본 값을 유지한다', () {
      final now = DateTime(2026, 3, 9);
      final original = Achievement(
        id: 'streak_7',
        userId: 'user-1',
        type: 'streak',
        title: '일주일 전사',
        description: '7일 연속',
        iconName: '🔥',
        xpReward: 50,
        unlockedAt: now,
        createdAt: now,
      );

      final copy = original.copyWith();

      expect(copy.title, original.title);
      expect(copy.xpReward, original.xpReward);
    });
  });
}
