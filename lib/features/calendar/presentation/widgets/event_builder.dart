// F2 헬퍼: 이벤트 폼 관련 순수 함수 모음
// SRP 분리: Event 객체 생성 + 반복 규칙 파싱 + 폼 유효성 검사 로직만 담당한다
// 순수 함수로 부작용(side-effect) 없이 입력값을 변환/검증한다
import 'package:flutter/material.dart';

import '../../../../shared/models/event.dart';

/// 폼 입력값으로 Event 모델 객체를 생성하는 순수 함수
/// userId는 EventRepository가 Provider를 통해 처리하므로 여기서는 포함하지 않는다
Event buildEventFromForm({
  required String eventId,
  required DateTime now,
  required String title,
  required EventType eventType,
  required DateTime startDate,
  required DateTime? endDate,
  required TimeOfDay? startTime,
  required TimeOfDay? endTime,
  required int colorIndex,
  required String location,
  required String memo,
  required Set<int> repeatDays,
  required String rangeTagText,
}) {
  // startDate에 시간을 합친 DateTime을 생성한다
  // 백엔드는 LocalDateTime 형식으로 시작/종료를 받는다
  DateTime startDateTime = startDate;
  if (startTime != null) {
    startDateTime = DateTime(
      startDate.year, startDate.month, startDate.day,
      startTime.hour, startTime.minute,
    );
  }

  DateTime? endDateTime;
  if (eventType == EventType.range && endDate != null) {
    if (endTime != null) {
      endDateTime = DateTime(
        endDate.year, endDate.month, endDate.day,
        endTime.hour, endTime.minute,
      );
    } else {
      endDateTime = endDate;
    }
  } else if (endTime != null) {
    // 범위 타입이 아닌 경우, 같은 날의 종료 시간으로 설정한다
    endDateTime = DateTime(
      startDate.year, startDate.month, startDate.day,
      endTime.hour, endTime.minute,
    );
  }

  // 반복 규칙 문자열 생성 (iCalendar RRULE 형식 간소화)
  String? recurrenceRule;
  if (eventType == EventType.recurring && repeatDays.isNotEmpty) {
    final sortedDays = repeatDays.toList()..sort();
    final dayNames = ['', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    final byDay = sortedDays.map((d) => dayNames[d]).join(',');
    recurrenceRule = 'FREQ=WEEKLY;BYDAY=$byDay';
  }

  return Event(
    id: eventId,
    title: title.trim(),
    eventType: eventType,
    startDate: startDateTime,
    endDate: endDateTime,
    allDay: startTime == null && endTime == null,
    colorIndex: colorIndex,
    location: location.trim().isNotEmpty ? location.trim() : null,
    memo: memo.trim().isNotEmpty ? memo.trim() : null,
    recurrenceRule: recurrenceRule,
    rangeTag: eventType == EventType.range && rangeTagText.trim().isNotEmpty
        ? RangeTag.values.firstWhere(
            (t) => t.name == rangeTagText.trim().toLowerCase(),
            orElse: () => RangeTag.other,
          )
        : null,
    createdAt: now,
  );
}

/// 기존 Event에서 폼 초기값을 추출하는 데이터 클래스
/// 편집 모드에서 State 초기화를 단순화하기 위해 사용한다
class EventFormInitData {
  final EventType eventType;
  final int colorIndex;
  final DateTime startDate;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? rangeTagName;
  final Set<int> repeatDays;

  EventFormInitData._({
    required this.eventType,
    required this.colorIndex,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.rangeTagName,
    required this.repeatDays,
  });

  /// Event 모델로부터 폼 초기값을 추출한다
  factory EventFormInitData.fromEvent(Event e) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    if (!e.allDay) {
      startTime = TimeOfDay(
        hour: e.startDate.hour, minute: e.startDate.minute,
      );
      if (e.endDate != null) {
        endTime = TimeOfDay(
          hour: e.endDate!.hour, minute: e.endDate!.minute,
        );
      }
    }
    return EventFormInitData._(
      eventType: e.eventType,
      colorIndex: e.colorIndex,
      startDate: e.startDate,
      endDate: e.endDate,
      startTime: startTime,
      endTime: endTime,
      rangeTagName: e.rangeTag?.name,
      repeatDays: parseRecurrenceRule(e.recurrenceRule),
    );
  }
}

/// 반복 규칙 문자열(RRULE)에서 반복 요일 Set을 파싱하여 반환한다
/// 형식: FREQ=WEEKLY;BYDAY=MO,TU,WE (1=월 ~ 7=일)
Set<int> parseRecurrenceRule(String? rule) {
  final result = <int>{};
  if (rule == null) return result;

  final byDayMatch = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(rule);
  if (byDayMatch == null) return result;

  const dayNames = {
    'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6, 'SU': 7,
  };
  for (final day in byDayMatch.group(1)!.split(',')) {
    final dayNum = dayNames[day];
    if (dayNum != null) result.add(dayNum);
  }
  return result;
}

/// 이벤트 폼 유효성 검사 결과를 담는 불변 레코드
/// 각 필드가 null이면 해당 검사를 통과한 것이다
typedef EventValidationResult = ({
  String? titleError,
  String? dateError,
  String? repeatError,
});

/// 이벤트 폼 입력값의 유효성을 검사하는 순수 함수
/// 제목 비어있음, 범위 일정 종료일 누락/역순, 반복 요일 미선택을 검증한다
EventValidationResult validateEventForm({
  required String title,
  required EventType eventType,
  required DateTime startDate,
  required DateTime? endDate,
  required Set<int> repeatDays,
}) {
  final titleError = title.trim().isEmpty ? '제목을 입력해주세요' : null;

  String? dateError;
  if (eventType == EventType.range) {
    if (endDate == null) {
      dateError = '종료일을 선택해주세요';
    } else if (endDate.isBefore(startDate)) {
      dateError = '종료일은 시작일 이후여야 합니다';
    }
  }

  final repeatError =
      (eventType == EventType.recurring && repeatDays.isEmpty)
          ? '반복 요일을 최소 1개 선택해주세요'
          : null;

  return (
    titleError: titleError,
    dateError: dateError,
    repeatError: repeatError,
  );
}
