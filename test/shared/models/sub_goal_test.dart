// SubGoal 모델 단위 테스트
// fromMap/toMap 왕복 변환, orderIndex 범위, copyWith를 검증한다.
// Supabase sub_goals 테이블 대응 — toMap은 snake_case (is_completed, order_index)
import 'package:design_your_life/shared/models/sub_goal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SubGoal 모델', () {
    late SubGoal subGoal;

    setUp(() {
      subGoal = SubGoal(
        id: 'sub-1',
        goalId: 'goal-1',
        title: '기초 문법 학습',
        isCompleted: false,
        orderIndex: 0,
        createdAt: testCreatedAt,
      );
    });

    test('기본값이 올바르게 설정된다', () {
      expect(subGoal.isCompleted, false);
      expect(subGoal.orderIndex, 0);
    });

    test('toMap이 올바른 snake_case Map을 반환한다', () {
      final map = subGoal.toMap();
      // toMap은 toUpdateMap 별칭 — goal_id 미포함 (UPDATE용)
      expect(map['title'], '기초 문법 학습');
      expect(map['is_completed'], false);
      expect(map['order_index'], 0);
      // toUpdateMap에는 goal_id가 포함되지 않는다
      expect(map.containsKey('goal_id'), false);
      expect(map.containsKey('goalId'), false);
    });

    test('fromMap이 올바른 SubGoal 객체를 생성한다', () {
      final map = <String, dynamic>{
        'goal_id': 'goal-1',
        'title': '기초 문법 학습',
        'is_completed': false,
        'order_index': 3,
        'created_at': testCreatedAt.toIso8601String(),
      };
      final parsed = SubGoal.fromMap({...map, 'id': 'sub-1'});
      expect(parsed.id, 'sub-1');
      expect(parsed.goalId, 'goal-1');
      expect(parsed.title, '기초 문법 학습');
      expect(parsed.orderIndex, 3);
    });

    test('fromMap/toMap 왕복 변환이 데이터를 보존한다', () {
      final map = subGoal.toMap();
      // toMap(=toUpdateMap)에는 goal_id가 없으므로 별도 추가한다
      final restored = SubGoal.fromMap({
        ...map,
        'id': subGoal.id,
        'goal_id': subGoal.goalId,
        'created_at': testCreatedAt.toIso8601String(),
      });
      expect(restored.goalId, subGoal.goalId);
      expect(restored.title, subGoal.title);
      expect(restored.isCompleted, subGoal.isCompleted);
      expect(restored.orderIndex, subGoal.orderIndex);
    });

    test('fromMap에서 선택 필드가 null일 때 기본값을 사용한다', () {
      final map = <String, dynamic>{
        'goal_id': 'goal-1',
        'title': '테스트',
        'created_at': testCreatedAt.toIso8601String(),
      };
      final parsed = SubGoal.fromMap({...map, 'id': 'sub-x'});
      expect(parsed.isCompleted, false);
      expect(parsed.orderIndex, 0);
    });

    test('orderIndex가 0~7 범위의 값을 가질 수 있다', () {
      for (int i = 0; i <= 7; i++) {
        final sg = subGoal.copyWith(orderIndex: i);
        expect(sg.orderIndex, i);
      }
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = subGoal.copyWith(
        title: '변경된 하위 목표',
        isCompleted: true,
        orderIndex: 5,
      );
      expect(updated.title, '변경된 하위 목표');
      expect(updated.isCompleted, true);
      expect(updated.orderIndex, 5);
      expect(updated.id, subGoal.id);
      expect(updated.goalId, subGoal.goalId);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      subGoal.copyWith(title: '변경됨');
      expect(subGoal.title, '기초 문법 학습');
    });
  });
}
