// 테스트: GoogleEventMapper (순수 함수 단위 테스트)
// Google Calendar 이벤트를 앱 CalendarEvent로 변환하는 매핑 로직을 검증한다.
// Google Calendar API 연결 없이 순수 함수만 테스트하므로 Mock 불필요.
import 'package:flutter_test/flutter_test.dart';

import 'package:design_your_life/core/calendar_sync/google_calendar_service.dart';
import 'package:design_your_life/core/calendar_sync/google_event_mapper.dart';
import 'package:design_your_life/features/calendar/providers/event_provider.dart';

void main() {
  group('GoogleEventMapper', () {
    // ─── toCalendarEvent 단일 변환 테스트 ──────────────────────────────────

    group('toCalendarEvent', () {
      test('시간 포함 이벤트를 올바르게 변환한다', () {
        // 준비: 시간 정보가 있는 Google Calendar 이벤트
        final googleEvent = GoogleCalendarEvent(
          id: 'test_id_001',
          title: '팀 미팅',
          startDate: DateTime(2024, 3, 15),
          endDate: DateTime(2024, 3, 15),
          startHour: 14,
          startMinute: 30,
          endHour: 15,
          endMinute: 30,
          location: '회의실 A',
          description: '월간 스프린트 리뷰',
        );

        // 실행
        final result = GoogleEventMapper.toCalendarEvent(googleEvent);

        // 검증: 모든 필드가 올바르게 매핑되었는지 확인
        expect(result.id, 'google_test_id_001'); // 'google_' 접두사 확인
        expect(result.title, '팀 미팅');
        expect(result.startDate, DateTime(2024, 3, 15));
        expect(result.endDate, DateTime(2024, 3, 15));
        expect(result.startHour, 14);
        expect(result.startMinute, 30);
        expect(result.endHour, 15);
        expect(result.endMinute, 30);
        expect(result.location, '회의실 A');
        expect(result.memo, '월간 스프린트 리뷰');
        expect(result.colorIndex, 8); // Google 이벤트 전용 colorIndex
        expect(result.type, 'normal');
        expect(result.source, 'google'); // source 필드 확인
        expect(result.isGoogleEvent, isTrue); // 편의 getter 확인
      });

      test('종일 이벤트를 올바르게 변환한다', () {
        // 준비: 시간 정보가 없는 종일 이벤트
        final googleEvent = GoogleCalendarEvent(
          id: 'allday_001',
          title: '연차 휴가',
          startDate: DateTime(2024, 3, 20),
          // 종일 이벤트: startHour, startMinute, endHour, endMinute 모두 null
        );

        // 실행
        final result = GoogleEventMapper.toCalendarEvent(googleEvent);

        // 검증
        expect(result.id, 'google_allday_001');
        expect(result.title, '연차 휴가');
        expect(result.startDate, DateTime(2024, 3, 20));
        expect(result.endDate, isNull); // 종일 이벤트는 endDate null
        expect(result.startHour, isNull); // 시간 정보 없음
        expect(result.startMinute, isNull);
        expect(result.endHour, isNull);
        expect(result.endMinute, isNull);
        expect(result.source, 'google');
        expect(result.colorIndex, 8);
      });

      test('null 제목이 없는 이벤트도 올바르게 변환한다', () {
        // Google 이벤트는 summary가 항상 있지만 방어적으로 빈 문자열 처리 확인
        final googleEvent = GoogleCalendarEvent(
          id: 'empty_title',
          title: '', // 빈 제목
          startDate: DateTime(2024, 3, 10),
        );

        final result = GoogleEventMapper.toCalendarEvent(googleEvent);

        expect(result.title, '');
        expect(result.id, 'google_empty_title');
        expect(result.source, 'google');
      });

      test('location과 description이 null인 이벤트를 올바르게 변환한다', () {
        // 준비: 장소와 설명이 없는 이벤트
        final googleEvent = GoogleCalendarEvent(
          id: 'no_location',
          title: '개인 일정',
          startDate: DateTime(2024, 3, 5),
          // location, description 생략 (null)
        );

        final result = GoogleEventMapper.toCalendarEvent(googleEvent);

        expect(result.location, isNull);
        expect(result.memo, isNull);
        expect(result.source, 'google');
        expect(result.colorIndex, 8);
      });

      test('source가 항상 google로 설정된다', () {
        // 어떤 이벤트든 source는 반드시 'google'이어야 한다
        final googleEvent = GoogleCalendarEvent(
          id: 'source_test',
          title: '소스 확인 테스트',
          startDate: DateTime(2024, 1, 1),
        );

        final result = GoogleEventMapper.toCalendarEvent(googleEvent);

        expect(result.source, 'google');
        expect(result.isGoogleEvent, isTrue);
      });

      test('colorIndex가 항상 8로 설정된다', () {
        // Google 이벤트 전용 colorIndex는 반드시 8이어야 한다
        final googleEvent = GoogleCalendarEvent(
          id: 'color_test',
          title: '색상 확인 테스트',
          startDate: DateTime(2024, 1, 1),
        );

        final result = GoogleEventMapper.toCalendarEvent(googleEvent);

        // colorIndex 8은 Google Blue (#4285F4)를 나타낸다
        expect(result.colorIndex, 8);
      });

      test('이벤트 ID에 google_ 접두사가 붙는다', () {
        // ID 충돌 방지를 위해 반드시 'google_' 접두사가 있어야 한다
        final googleEvent = GoogleCalendarEvent(
          id: 'original_id',
          title: 'ID 테스트',
          startDate: DateTime(2024, 1, 1),
        );

        final result = GoogleEventMapper.toCalendarEvent(googleEvent);

        // 앱 이벤트 ID와 충돌하지 않도록 'google_' 접두사 확인
        expect(result.id, startsWith('google_'));
        expect(result.id, 'google_original_id');
      });

      test('type이 항상 normal로 설정된다', () {
        // Google 이벤트는 앱 내에서 반복/범위 구분 없이 normal로 처리한다
        final googleEvent = GoogleCalendarEvent(
          id: 'type_test',
          title: '타입 확인',
          startDate: DateTime(2024, 1, 1),
        );

        final result = GoogleEventMapper.toCalendarEvent(googleEvent);

        expect(result.type, 'normal');
      });

      test('범위 이벤트(startDate != endDate)를 올바르게 변환한다', () {
        // 준비: 여러 날에 걸친 범위 이벤트
        final googleEvent = GoogleCalendarEvent(
          id: 'range_event',
          title: '출장',
          startDate: DateTime(2024, 4, 1),
          endDate: DateTime(2024, 4, 5),
          location: '부산',
          description: '지방 출장',
        );

        final result = GoogleEventMapper.toCalendarEvent(googleEvent);

        expect(result.startDate, DateTime(2024, 4, 1));
        expect(result.endDate, DateTime(2024, 4, 5));
        expect(result.source, 'google');
        expect(result.colorIndex, 8);
      });
    });

    // ─── toCalendarEvents 일괄 변환 테스트 ─────────────────────────────────

    group('toCalendarEvents', () {
      test('빈 목록을 전달하면 빈 목록을 반환한다', () {
        final result = GoogleEventMapper.toCalendarEvents([]);
        expect(result, isEmpty);
      });

      test('여러 이벤트를 일괄 변환한다', () {
        // 준비: 3개의 Google Calendar 이벤트
        final googleEvents = [
          GoogleCalendarEvent(
            id: 'event_1',
            title: '이벤트 1',
            startDate: DateTime(2024, 3, 1),
          ),
          GoogleCalendarEvent(
            id: 'event_2',
            title: '이벤트 2',
            startDate: DateTime(2024, 3, 2),
            startHour: 9,
            startMinute: 0,
          ),
          GoogleCalendarEvent(
            id: 'event_3',
            title: '이벤트 3',
            startDate: DateTime(2024, 3, 3),
            location: '서울',
          ),
        ];

        final result = GoogleEventMapper.toCalendarEvents(googleEvents);

        // 변환된 결과가 원본과 동일한 수인지 확인
        expect(result.length, 3);

        // 각 이벤트의 ID와 source 확인
        expect(result[0].id, 'google_event_1');
        expect(result[1].id, 'google_event_2');
        expect(result[2].id, 'google_event_3');

        // 모든 이벤트의 source가 'google'인지 확인
        for (final event in result) {
          expect(event.source, 'google');
          expect(event.colorIndex, 8);
          expect(event.type, 'normal');
        }
      });

      test('CalendarEvent 타입으로 반환된다', () {
        // 반환 타입이 List<CalendarEvent>인지 확인
        final googleEvents = [
          GoogleCalendarEvent(
            id: 'type_check',
            title: '타입 확인',
            startDate: DateTime(2024, 1, 1),
          ),
        ];

        final result = GoogleEventMapper.toCalendarEvents(googleEvents);

        expect(result, isA<List<CalendarEvent>>());
        expect(result.first, isA<CalendarEvent>());
      });
    });
  });
}
