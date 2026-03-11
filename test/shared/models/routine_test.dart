// Routine 모델 단위 테스트
// fromMap/toMap 왕복 변환, 요일 리스트, TimeOfDay 직렬화를 검증한다.
// Supabase routines 테이블 대응 — days_of_week는 text[] 배열,
// start_time/end_time은 "HH:mm" 문자열, color는 hex 문자열이다.
import 'package:design_your_life/shared/models/routine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Routine 모델', () {
    late Routine routine;

    setUp(() {
      routine = Routine(
        id: 'routine-1',
        userId: 'user-1',
        name: '아침 루틴',
        repeatDays: [1, 2, 3, 4, 5],
        startTime: const TimeOfDay(hour: 7, minute: 0),
        endTime: const TimeOfDay(hour: 8, minute: 30),
        colorIndex: 1,
        isActive: true,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
    });

    test('기본값이 올바르게 설정된다', () {
      final defaultRoutine = Routine(
        id: 'routine-2',
        userId: 'user-1',
        name: '저녁 루틴',
        repeatDays: [1, 3, 5],
        startTime: const TimeOfDay(hour: 18, minute: 0),
        endTime: const TimeOfDay(hour: 19, minute: 0),
        colorIndex: 0,
        createdAt: testCreatedAt,
        updatedAt: testDate,
      );
      expect(defaultRoutine.isActive, true);
    });

    test('toMap이 TimeOfDay를 "HH:mm" 문자열로 변환한다', () {
      final map = routine.toMap();
      // Supabase time 타입 대응: "HH:mm" 문자열
      expect(map['start_time'], '07:00');
      expect(map['end_time'], '08:30');
    });

    test('toMap이 repeatDays를 DayOfWeek 문자열 배열로 변환한다', () {
      final map = routine.toMap();
      // Supabase text[] 배열: ["MON","TUE","WED","THU","FRI"]
      expect(map['days_of_week'], ['MON', 'TUE', 'WED', 'THU', 'FRI']);
    });

    test('toMap이 colorIndex를 hex 문자열로 변환한다', () {
      final map = routine.toMap();
      // colorIndex 1 → hex 색상 문자열
      expect(map['color'], isA<String>());
      expect((map['color'] as String).startsWith('#'), true);
    });

    test('toMap이 is_active를 포함한다', () {
      final map = routine.toMap();
      expect(map['is_active'], true);
    });

    test('fromMap이 올바른 Routine 객체를 생성한다', () {
      final map = <String, dynamic>{
        'user_id': 'user-1',
        'name': '아침 루틴',
        'days_of_week': ['MON', 'TUE', 'WED', 'THU', 'FRI'],
        'start_time': '07:00',
        'end_time': '08:30',
        'color': '#EC4899',
        'is_active': true,
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testDate.toIso8601String(),
      };
      final parsed = Routine.fromMap({...map, 'id': 'routine-1'});
      expect(parsed.id, 'routine-1');
      expect(parsed.name, '아침 루틴');
      expect(parsed.startTime.hour, 7);
      expect(parsed.startTime.minute, 0);
      expect(parsed.endTime.hour, 8);
      expect(parsed.endTime.minute, 30);
      expect(parsed.repeatDays, [1, 2, 3, 4, 5]);
    });

    test('fromMap/toMap 왕복 변환이 데이터를 보존한다', () {
      final map = routine.toMap();
      // toMap은 Supabase snake_case 형식이므로 fromMap에 직접 전달 가능하다
      // 단, createdAt/updatedAt은 toMap에 포함되지 않으므로 별도 추가한다
      final restored = Routine.fromMap({
        ...map,
        'id': routine.id,
        'user_id': routine.userId,
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testDate.toIso8601String(),
      });
      expect(restored.name, routine.name);
      expect(restored.startTime.hour, routine.startTime.hour);
      expect(restored.startTime.minute, routine.startTime.minute);
      expect(restored.endTime.hour, routine.endTime.hour);
      expect(restored.endTime.minute, routine.endTime.minute);
      expect(restored.repeatDays, routine.repeatDays);
      expect(restored.isActive, routine.isActive);
    });

    test('fromMap에서 선택 필드가 null일 때 기본값을 사용한다', () {
      final map = <String, dynamic>{
        'user_id': 'user-1',
        'name': '테스트',
        'days_of_week': ['SAT', 'SUN'],
        'start_time': '10:00',
        'end_time': '11:00',
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testDate.toIso8601String(),
      };
      final parsed = Routine.fromMap({...map, 'id': 'routine-x'});
      expect(parsed.colorIndex, 0);
      expect(parsed.isActive, true);
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = routine.copyWith(
        name: '저녁 루틴',
        repeatDays: [6, 7],
        isActive: false,
      );
      expect(updated.name, '저녁 루틴');
      expect(updated.repeatDays, [6, 7]);
      expect(updated.isActive, false);
      expect(updated.id, routine.id);
      expect(updated.startTime.hour, routine.startTime.hour);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      routine.copyWith(name: '변경됨');
      expect(routine.name, '아침 루틴');
    });

    test('주말만 반복하는 루틴을 올바르게 처리한다', () {
      final weekendRoutine = routine.copyWith(repeatDays: [6, 7]);
      expect(weekendRoutine.repeatDays, [6, 7]);
      expect(weekendRoutine.repeatDays.length, 2);
    });
  });
}
