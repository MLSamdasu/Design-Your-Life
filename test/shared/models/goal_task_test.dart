// GoalTask 모델 단위 테스트
// fromMap/toMap 왕복 변환, orderIndex, copyWith를 검증한다.
// Supabase goal_tasks 테이블 대응 — toMap은 snake_case (is_completed, order_index)
import 'package:design_your_life/shared/models/goal_task.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('GoalTask 모델', () {
    late GoalTask task;

    setUp(() {
      task = GoalTask(
        id: 'task-1',
        subGoalId: 'sub-1',
        title: 'Dart 기초 튜토리얼 완료',
        isCompleted: false,
        orderIndex: 0,
        createdAt: testCreatedAt,
      );
    });

    test('기본값이 올바르게 설정된다', () {
      expect(task.isCompleted, false);
      expect(task.orderIndex, 0);
    });

    test('toMap이 올바른 snake_case Map을 반환한다', () {
      final map = task.toMap();
      // toMap은 toUpdateMap 별칭 — sub_goal_id 미포함 (UPDATE용)
      expect(map['title'], 'Dart 기초 튜토리얼 완료');
      expect(map['is_completed'], false);
      expect(map['order_index'], 0);
      // toUpdateMap에는 sub_goal_id가 포함되지 않는다
      expect(map.containsKey('sub_goal_id'), false);
      expect(map.containsKey('subGoalId'), false);
    });

    test('fromMap이 올바른 GoalTask 객체를 생성한다', () {
      final map = <String, dynamic>{
        'sub_goal_id': 'sub-1',
        'title': 'Dart 기초 튜토리얼 완료',
        'is_completed': true,
        'order_index': 4,
        'created_at': testCreatedAt.toIso8601String(),
      };
      final parsed = GoalTask.fromMap({...map, 'id': 'task-1'});
      expect(parsed.id, 'task-1');
      expect(parsed.subGoalId, 'sub-1');
      expect(parsed.title, 'Dart 기초 튜토리얼 완료');
      expect(parsed.isCompleted, true);
      expect(parsed.orderIndex, 4);
    });

    test('fromMap/toMap 왕복 변환이 데이터를 보존한다', () {
      final map = task.toMap();
      // toMap(=toUpdateMap)에는 sub_goal_id가 없으므로 별도 추가한다
      final restored = GoalTask.fromMap({
        ...map,
        'id': task.id,
        'sub_goal_id': task.subGoalId,
        'created_at': testCreatedAt.toIso8601String(),
      });
      expect(restored.subGoalId, task.subGoalId);
      expect(restored.title, task.title);
      expect(restored.isCompleted, task.isCompleted);
      expect(restored.orderIndex, task.orderIndex);
    });

    test('fromMap에서 선택 필드가 null일 때 기본값을 사용한다', () {
      final map = <String, dynamic>{
        'sub_goal_id': 'sub-1',
        'title': '테스트 과제',
        'created_at': testCreatedAt.toIso8601String(),
      };
      final parsed = GoalTask.fromMap({...map, 'id': 'task-x'});
      expect(parsed.isCompleted, false);
      expect(parsed.orderIndex, 0);
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = task.copyWith(
        title: '변경된 과제',
        isCompleted: true,
        orderIndex: 7,
      );
      expect(updated.title, '변경된 과제');
      expect(updated.isCompleted, true);
      expect(updated.orderIndex, 7);
      expect(updated.id, task.id);
      expect(updated.subGoalId, task.subGoalId);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      task.copyWith(title: '변경됨');
      expect(task.title, 'Dart 기초 튜토리얼 완료');
    });

    test('완료 상태를 토글할 수 있다', () {
      final completed = task.copyWith(isCompleted: true);
      expect(completed.isCompleted, true);
      final uncompleted = completed.copyWith(isCompleted: false);
      expect(uncompleted.isCompleted, false);
    });
  });
}
