// C0.CalSync: Google Calendar 이벤트 → 앱 CalendarEvent 변환 순수 함수
// 외부 상태에 의존하지 않는 순수 함수(static)로 구현한다.
// 입력: GoogleCalendarEvent (Google API 응답 변환 객체)
// 출력: CalendarEvent (캘린더 뷰용 모델, source: 'google')
import '../../../shared/models/calendar_event.dart';
import 'google_calendar_service.dart';

/// Google Calendar 이벤트를 앱 CalendarEvent(뷰 모델)로 변환한다
/// abstract class + static 패턴: MandalartMapper와 동일한 구조를 따른다
abstract class GoogleEventMapper {
  /// Google Calendar 이벤트 하나를 앱 내부 CalendarEvent로 변환한다
  ///
  /// 매핑 규칙:
  /// - id: 'google_{원본ID}' 형식 (앱 이벤트와 ID 충돌 방지)
  /// - colorIndex: 8 고정 (Google 이벤트 전용 색상 인덱스, 기존 0~7과 구분)
  /// - type: 'normal' 고정 (Google 이벤트의 반복/범위 세분화 불필요)
  /// - source: 'google' 고정 (UI에서 Google 이벤트 식별에 사용)
  static CalendarEvent toCalendarEvent(GoogleCalendarEvent event) {
    return CalendarEvent(
      // 앱 이벤트 ID와 충돌하지 않도록 'google_' 접두사를 붙인다
      id: 'google_${event.id}',
      title: event.title,
      startDate: event.startDate,
      endDate: event.endDate,
      startHour: event.startHour,
      startMinute: event.startMinute,
      endHour: event.endHour,
      endMinute: event.endMinute,
      // Google 이벤트 전용 colorIndex 8 (ColorTokens.eventColor에 추가됨)
      colorIndex: 8,
      type: 'normal',
      memo: event.description,
      location: event.location,
      // startHour가 null이면 종일 이벤트로 판단한다
      isAllDay: event.startHour == null,
      // source를 'google'로 명시하여 EventCard에서 Google 뱃지를 표시한다
      source: 'google',
    );
  }

  /// Google Calendar 이벤트 목록을 일괄 변환한다
  /// 빈 목록이 전달되면 빈 목록을 반환한다
  static List<CalendarEvent> toCalendarEvents(
    List<GoogleCalendarEvent> events,
  ) {
    return events.map(toCalendarEvent).toList();
  }
}
