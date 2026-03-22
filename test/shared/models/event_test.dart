// Event 모델 단위 테스트
// fromMap, toCreateMap, EventType/RangeTag enum 직렬화,
// 선택 필드 처리를 검증한다.
// Supabase events 테이블 대응 모델 — snake_case 컬럼명, 소문자 enum 값 사용
import 'package:design_your_life/shared/models/event.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Event 모델', () {
    late Event normalEvent;
    late Event rangeEvent;
    late Event recurringEvent;

    setUp(() {
      normalEvent = Event(
        id: 'event-1',
        title: '회의',
        eventType: EventType.normal,
        startDate: DateTime(2026, 3, 9, 10, 0),
        endDate: DateTime(2026, 3, 9, 11, 0),
        location: '회의실 A',
        memo: '분기 회의',
        createdAt: testCreatedAt,
      );

      rangeEvent = Event(
        id: 'event-2',
        title: '여행',
        eventType: EventType.range,
        startDate: testDate,
        endDate: DateTime(2026, 3, 15),
        rangeTag: RangeTag.travel,
        createdAt: testCreatedAt,
      );

      recurringEvent = Event(
        id: 'event-3',
        title: '주간 회의',
        eventType: EventType.recurring,
        startDate: testDate,
        recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO,WE,FR',
        createdAt: testCreatedAt,
      );
    });

    test('EventType enum이 4가지 값을 포함한다', () {
      expect(EventType.values.length, 4);
      expect(EventType.values, contains(EventType.normal));
      expect(EventType.values, contains(EventType.range));
      expect(EventType.values, contains(EventType.recurring));
      expect(EventType.values, contains(EventType.todo));
    });

    test('RangeTag enum이 5가지 값을 포함한다', () {
      expect(RangeTag.values.length, 5);
    });

    test('일반 이벤트 toCreateMap이 올바른 Map을 반환한다', () {
      final map = normalEvent.toCreateMap();
      // Supabase는 소문자 enum 값을 사용한다
      expect(map['event_type'], 'normal');
      expect(map['title'], '회의');
      expect(map['location'], '회의실 A');
      expect(map['memo'], '분기 회의');
      // start_date는 ISO 8601 문자열이다
      expect(map['start_date'], isA<String>());
    });

    test('범위 이벤트 toCreateMap이 end_date와 range_tag를 포함한다', () {
      final map = rangeEvent.toCreateMap();
      expect(map['event_type'], 'range');
      expect(map.containsKey('end_date'), true);
      expect(map['range_tag'], 'travel');
    });

    test('반복 이벤트 toCreateMap이 recurrence_rule을 포함한다', () {
      final map = recurringEvent.toCreateMap();
      expect(map['event_type'], 'recurring');
      expect(map['recurrence_rule'], 'FREQ=WEEKLY;BYDAY=MO,WE,FR');
    });

    test('fromMap이 일반 이벤트를 올바르게 생성한다', () {
      final map = <String, dynamic>{
        'title': '회의',
        'event_type': 'normal',
        'start_date': '2026-03-09T10:00:00',
        'end_date': '2026-03-09T11:00:00',
        'all_day': false,
        'location': '회의실 A',
        'memo': '분기 회의',
        'created_at': testCreatedAt.toIso8601String(),
      };
      map['id'] = 'event-1';
      final parsed = Event.fromMap(map);
      expect(parsed.eventType, EventType.normal);
      expect(parsed.startDate.hour, 10);
      expect(parsed.location, '회의실 A');
    });

    test('fromMap이 범위 이벤트를 올바르게 생성한다', () {
      final map = <String, dynamic>{
        'title': '여행',
        'event_type': 'range',
        'start_date': testDate.toIso8601String(),
        'end_date': DateTime(2026, 3, 15).toIso8601String(),
        'range_tag': 'travel',
        'created_at': testCreatedAt.toIso8601String(),
      };
      map['id'] = 'event-2';
      final parsed = Event.fromMap(map);
      expect(parsed.eventType, EventType.range);
      expect(parsed.endDate, isNotNull);
      expect(parsed.rangeTag, RangeTag.travel);
    });

    test('fromMap에서 잘못된 eventType 값이면 normal을 기본값으로 사용한다', () {
      final map = <String, dynamic>{
        'title': '테스트',
        'event_type': 'invalid_type',
        'start_date': testDate.toIso8601String(),
        'created_at': testCreatedAt.toIso8601String(),
      };
      map['id'] = 'event-x';
      final parsed = Event.fromMap(map);
      expect(parsed.eventType, EventType.normal);
    });

    test('선택 필드가 모두 null일 때 정상 동작한다', () {
      final map = <String, dynamic>{
        'title': '최소 이벤트',
        'event_type': 'normal',
        'start_date': testDate.toIso8601String(),
        'created_at': testCreatedAt.toIso8601String(),
      };
      map['id'] = 'event-min';
      final parsed = Event.fromMap(map);
      expect(parsed.endDate, isNull);
      expect(parsed.location, isNull);
      expect(parsed.memo, isNull);
      expect(parsed.recurrenceRule, isNull);
      expect(parsed.rangeTag, isNull);
      expect(parsed.description, isNull);
      expect(parsed.allDay, false);
    });

    test('copyWith가 지정 필드만 변경한 새 인스턴스를 반환한다', () {
      final updated = normalEvent.copyWith(
        title: '변경된 회의',
      );
      expect(updated.title, '변경된 회의');
      expect(updated.id, normalEvent.id);
      expect(updated.eventType, normalEvent.eventType);
      expect(updated.location, normalEvent.location);
    });

    test('copyWith가 원본 객체를 변경하지 않는다', () {
      normalEvent.copyWith(title: '변경됨');
      expect(normalEvent.title, '회의');
    });

    test('copyWith clearEndDate가 endDate를 null로 초기화한다', () {
      final updated = rangeEvent.copyWith(clearEndDate: true);
      expect(updated.endDate, isNull);
      expect(updated.title, rangeEvent.title);
    });

    test('copyWith clearLocation이 location을 null로 초기화한다', () {
      final updated = normalEvent.copyWith(clearLocation: true);
      expect(updated.location, isNull);
      expect(updated.title, normalEvent.title);
    });

    test('copyWith clearMemo가 memo를 null로 초기화한다', () {
      final updated = normalEvent.copyWith(clearMemo: true);
      expect(updated.memo, isNull);
      expect(updated.title, normalEvent.title);
    });

    test('copyWith clearRangeTag가 rangeTag를 null로 초기화한다', () {
      final updated = rangeEvent.copyWith(clearRangeTag: true);
      expect(updated.rangeTag, isNull);
      expect(updated.title, rangeEvent.title);
    });

    test('copyWith clearRecurrenceRule이 recurrenceRule을 null로 초기화한다', () {
      final updated = recurringEvent.copyWith(clearRecurrenceRule: true);
      expect(updated.recurrenceRule, isNull);
    });

    test('colorIndex가 기본값 0으로 생성된다', () {
      expect(normalEvent.colorIndex, 0);
    });

    test('colorIndex가 지정값으로 생성된다', () {
      final event = Event(
        id: 'color-test',
        title: '색상 테스트',
        eventType: EventType.normal,
        startDate: testDate,
        colorIndex: 3,
        createdAt: testCreatedAt,
      );
      expect(event.colorIndex, 3);
    });

    test('fromMap에서 color_index를 올바르게 읽는다', () {
      final map = <String, dynamic>{
        'id': 'ci-1',
        'title': '색상 인덱스 테스트',
        'event_type': 'normal',
        'start_date': testDate.toIso8601String(),
        'color_index': 5,
        'created_at': testCreatedAt.toIso8601String(),
      };
      final parsed = Event.fromMap(map);
      expect(parsed.colorIndex, 5);
    });

    test('toCreateMap에 color_index가 포함된다', () {
      final event = Event(
        id: 'ci-2',
        title: '색상 맵 테스트',
        eventType: EventType.normal,
        startDate: testDate,
        colorIndex: 7,
        createdAt: testCreatedAt,
      );
      final map = event.toCreateMap();
      expect(map['color_index'], 7);
    });

    test('UI 호환 userId getter가 빈 문자열을 반환한다', () {
      expect(normalEvent.userId, '');
    });
  });

  group('Event 모델 - 경계값 테스트', () {
    test('title 200자가 정상 처리된다', () {
      final longTitle = 'A' * 200;
      final event = Event(
        id: 'edge-3',
        title: longTitle,
        eventType: EventType.normal,
        startDate: testDate,
        createdAt: testCreatedAt,
      );
      expect(event.title.length, 200);
    });

    test('memo 2000자가 정상 처리된다', () {
      final longMemo = 'M' * 2000;
      final event = Event(
        id: 'edge-4',
        title: '메모 경계값',
        eventType: EventType.normal,
        startDate: testDate,
        memo: longMemo,
        createdAt: testCreatedAt,
      );
      expect(event.memo?.length, 2000);
    });

    test('allDay가 true로 설정된다', () {
      final event = Event(
        id: 'edge-5',
        title: '종일 일정',
        eventType: EventType.normal,
        startDate: testDate,
        allDay: true,
        createdAt: testCreatedAt,
      );
      expect(event.allDay, true);
    });

    test('dDay가 startDate 기준으로 자동 계산된다', () {
      // 오늘 기준 3일 후 이벤트
      final futureDate = DateTime.now().add(const Duration(days: 3));
      final event = Event(
        id: 'edge-6',
        title: 'D-Day 테스트',
        eventType: EventType.normal,
        startDate: DateTime(futureDate.year, futureDate.month, futureDate.day),
        createdAt: testCreatedAt,
      );
      expect(event.dDayFrom(DateTime.now()), 3);
    });
  });
}
