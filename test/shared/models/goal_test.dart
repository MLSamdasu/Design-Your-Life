// Goal 모델 단위 테스트
// fromMap/toMap 왕복 변환, GoalPeriod enum 직렬화, copyWith를 검증한다.
import 'package:design_your_life/shared/enums/goal_period.dart';
import 'package:design_your_life/shared/models/goal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Goal 모델', () {
    late Goal yearlyGoal;
    late Goal monthlyGoal;

    setUp(() {
      yearlyGoal = Goal(
        id: 'goal-1',
        userId: 'user-1',
        title: '플러터 마스터',
        description: '2026년 안에 플러터 마스터하기',
        period: GoalPeriod.yearly,
        year: 2026,
        isCompleted: false,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
      monthlyGoal = Goal(
        id: 'goal-2',
        userId: 'user-1',
        title: '3월 목표',
        period: GoalPeriod.monthly,
        year: 2026,
        month: 3,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
    });

    test('기본값이 올바르게 설정된다', () {
      expect(yearlyGoal.isCompleted, false);
      expect(yearlyGoal.month, isNull);
      expect(monthlyGoal.isCompleted, false);
      expect(monthlyGoal.month, 3);
    });

    test('toMap이 period를 문자열로 직렬화한다', () {
      expect(yearlyGoal.toMap()['period'], 'yearly');
      expect(monthlyGoal.toMap()['period'], 'monthly');
    });

    test('toMap이 선택 필드를 포함한다', () {
      final map = yearlyGoal.toMap();
      expect(map['description'], '2026년 안에 플러터 마스터하기');
      expect(map['month'], isNull);

      final monthlyMap = monthlyGoal.toMap();
      expect(monthlyMap['month'], 3);
    });

    test('fromMap이 올바른 Goal 객체를 생성한다', () {
      final map = <String, dynamic>{
        'userId': 'user-1',
        'title': '플러터 마스터',
        'description': '2026년 안에 플러터 마스터하기',
        'period': 'yearly',
        'year': 2026,
        'isCompleted': false,
        'createdAt': testCreatedAt.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };
      final parsed = Goal.fromMap({...map, 'id': 'goal-1'});
      expect(parsed.id, 'goal-1');
      expect(parsed.title, '플러터 마스터');
      expect(parsed.period, GoalPeriod.yearly);
      expect(parsed.year, 2026);
      expect(parsed.month, isNull);
    });

    test('fromMap/toMap 왕복 변환이 데이터를 보존한다', () {
      final map = yearlyGoal.toMap();
      // toMap은 ISO 8601 문자열을 반환하므로 그대로 fromMap에 전달한다
      final restored = Goal.fromMap({...map, 'id': yearlyGoal.id});
      expect(restored.title, yearlyGoal.title);
      expect(restored.description, yearlyGoal.description);
      expect(restored.period, yearlyGoal.period);
      expect(restored.year, yearlyGoal.year);
      expect(restored.isCompleted, yearlyGoal.isCompleted);
    });

    test('fromMap에서 잘못된 period 값이면 yearly를 기본값으로 사용한다', () {
      final map = <String, dynamic>{
        'userId': 'user-1',
        'title': '테스트',
        'period': 'invalid',
        'year': 2026,
        'createdAt': testCreatedAt.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };
      final parsed = Goal.fromMap({...map, 'id': 'goal-x'});
      expect(parsed.period, GoalPeriod.yearly);
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = yearlyGoal.copyWith(
        title: '변경된 목표',
        isCompleted: true,
      );
      expect(updated.title, '변경된 목표');
      expect(updated.isCompleted, true);
      expect(updated.id, yearlyGoal.id);
      expect(updated.period, GoalPeriod.yearly);
    });

    test('월간 목표의 month가 올바르게 설정된다', () {
      expect(monthlyGoal.month, 3);
      final updated = monthlyGoal.copyWith(month: 12);
      expect(updated.month, 12);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      yearlyGoal.copyWith(title: '변경됨');
      expect(yearlyGoal.title, '플러터 마스터');
    });

    test('copyWith clearDescription이 description을 null로 초기화한다', () {
      final updated = yearlyGoal.copyWith(clearDescription: true);
      expect(updated.description, isNull);
      expect(updated.title, yearlyGoal.title);
    });

    test('copyWith clearMonth가 month를 null로 초기화한다', () {
      final updated = monthlyGoal.copyWith(clearMonth: true);
      expect(updated.month, isNull);
      expect(updated.title, monthlyGoal.title);
    });
  });

  group('Goal 모델 - 경계값 테스트', () {
    test('title 200자가 정상 처리된다', () {
      final longTitle = 'A' * 200;
      final goal = Goal(
        id: 'edge-1',
        userId: 'user-1',
        title: longTitle,
        period: GoalPeriod.yearly,
        year: 2026,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
      expect(goal.title.length, 200);
    });

    test('빈 문자열 title이 저장된다', () {
      final goal = Goal(
        id: 'edge-2',
        userId: 'user-1',
        title: '',
        period: GoalPeriod.yearly,
        year: 2026,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
      expect(goal.title, '');
    });

    test('description 1000자가 정상 처리된다', () {
      final longDesc = 'B' * 1000;
      final goal = Goal(
        id: 'edge-3',
        userId: 'user-1',
        title: '테스트',
        description: longDesc,
        period: GoalPeriod.yearly,
        year: 2026,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
      expect(goal.description?.length, 1000);
    });

    test('month 경계값 1(1월)이 정상 처리된다', () {
      final goal = Goal(
        id: 'edge-4',
        userId: 'user-1',
        title: '1월 목표',
        period: GoalPeriod.monthly,
        year: 2026,
        month: 1,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
      expect(goal.month, 1);
    });

    test('month 경계값 12(12월)가 정상 처리된다', () {
      final goal = Goal(
        id: 'edge-5',
        userId: 'user-1',
        title: '12월 목표',
        period: GoalPeriod.monthly,
        year: 2026,
        month: 12,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
      expect(goal.month, 12);
    });

    test('description이 null일 때 toMap에 null이 포함된다', () {
      final goal = Goal(
        id: 'edge-6',
        userId: 'user-1',
        title: '설명 없음',
        period: GoalPeriod.yearly,
        year: 2026,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
      expect(goal.toMap()['description'], isNull);
    });
  });
}
