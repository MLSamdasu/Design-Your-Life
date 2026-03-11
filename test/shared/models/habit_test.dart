// Habit 모델 단위 테스트
// fromMap, toCreateMap, 기본값, copyWith, 프리셋 목록을 검증한다.
// 백엔드 HabitDto 대응 모델로 전환 후 테스트를 업데이트했다.
import 'package:design_your_life/shared/models/habit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Habit 모델', () {
    late Habit habit;

    setUp(() {
      habit = Habit(
        id: 'habit-1',
        name: '운동 30분',
        icon: '\u{1F4AA}',
        color: '#4CAF50',
        isActive: true,
      );
    });

    test('기본값이 올바르게 설정된다', () {
      final defaultHabit = Habit(
        id: 'habit-2',
        name: '독서',
      );
      expect(defaultHabit.isActive, true);
      expect(defaultHabit.icon, isNull);
      expect(defaultHabit.color, isNull);
      expect(defaultHabit.currentStreak, 0);
      expect(defaultHabit.longestStreak, 0);
    });

    test('toCreateMap이 올바른 Map을 반환한다', () {
      final map = habit.toCreateMap();
      expect(map['name'], '운동 30분');
      expect(map['icon'], '\u{1F4AA}');
      expect(map['color'], '#4CAF50');
    });

    test('fromMap이 올바른 Habit 객체를 생성한다 (백엔드 필드명)', () {
      final map = <String, dynamic>{
        'name': '운동 30분',
        'icon': '\u{1F4AA}',
        'color': '#4CAF50',
        'active': true,
        'currentStreak': 5,
        'longestStreak': 10,
      };
      map['id'] = 'habit-1';
      final parsed = Habit.fromMap(map);
      expect(parsed.id, 'habit-1');
      expect(parsed.name, '운동 30분');
      expect(parsed.icon, '\u{1F4AA}');
      expect(parsed.color, '#4CAF50');
      expect(parsed.isActive, true);
      expect(parsed.currentStreak, 5);
      expect(parsed.longestStreak, 10);
    });

    test('fromMap에서 선택 필드가 null일 때 기본값을 사용한다', () {
      final map = <String, dynamic>{
        'name': '테스트 습관',
      };
      map['id'] = 'habit-3';
      final parsed = Habit.fromMap(map);
      expect(parsed.isActive, true);
      expect(parsed.icon, isNull);
      expect(parsed.color, isNull);
      expect(parsed.currentStreak, 0);
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = habit.copyWith(
        name: '명상',
        isActive: false,
      );
      expect(updated.name, '명상');
      expect(updated.isActive, false);
      expect(updated.id, habit.id);
      expect(updated.icon, habit.icon);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      habit.copyWith(name: '변경됨');
      expect(habit.name, '운동 30분');
    });

    test('UI 호환 colorIndex getter가 0을 반환한다', () {
      expect(habit.colorIndex, 0);
    });

    test('UI 호환 userId getter가 빈 문자열을 반환한다', () {
      expect(habit.userId, '');
    });
  });

  group('HabitPreset', () {
    test('프리셋 목록이 5개이다', () {
      expect(HabitPreset.presets.length, 5);
    });

    test('프리셋이 필수 필드를 모두 포함한다', () {
      for (final preset in HabitPreset.presets) {
        expect(preset.name.isNotEmpty, true);
        expect(preset.icon.isNotEmpty, true);
      }
    });

    test('프리셋에 color 필드가 있다', () {
      for (final preset in HabitPreset.presets) {
        expect(preset.color, isNotNull);
        expect(preset.color!.startsWith('#'), true);
      }
    });
  });

  group('Habit 모델 - 경계값 테스트', () {
    test('name 100자가 정상 처리된다', () {
      final longName = 'A' * 100;
      final habit = Habit(
        id: 'edge-3',
        name: longName,
      );
      expect(habit.name.length, 100);
    });

    test('빈 문자열 name이 저장된다', () {
      final habit = Habit(
        id: 'edge-4',
        name: '',
      );
      expect(habit.name, '');
    });

    test('icon이 null일 때 toCreateMap에 null이 포함된다', () {
      final habit = Habit(
        id: 'edge-5',
        name: '아이콘 없음',
      );
      expect(habit.toCreateMap()['icon'], isNull);
    });
  });
}
