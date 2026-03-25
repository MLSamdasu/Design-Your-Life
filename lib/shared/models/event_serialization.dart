// 캘린더 이벤트 직렬화 — enum 변환 헬퍼 + toInsertMap/toUpdateMap/toCreateMap
// event_model.dart의 part 파일이다.
// fromMap 팩토리 생성자는 여기 정의된 enum 변환 함수를 사용한다.
part of 'event_model.dart';

// ─── Enum 변환 헬퍼 ─────────────────────────────────────────────────────────

/// event_type 문자열에서 enum으로 변환한다
EventType _eventTypeFromString(String? value) {
  if (value == null) return EventType.normal;
  switch (value.toLowerCase()) {
    case 'normal':
      return EventType.normal;
    case 'range':
      return EventType.range;
    case 'recurring':
      return EventType.recurring;
    case 'todo':
      return EventType.todo;
    default:
      return EventType.normal;
  }
}

/// EventType을 문자열로 변환한다 (소문자)
String _eventTypeToString(EventType type) {
  return type.name;
}

/// range_tag 문자열에서 enum으로 변환한다
RangeTag? _rangeTagFromString(String? value) {
  if (value == null) return null;
  switch (value.toLowerCase()) {
    case 'travel':
      return RangeTag.travel;
    case 'exam':
      return RangeTag.exam;
    case 'vacation':
      return RangeTag.vacation;
    case 'project':
      return RangeTag.project;
    case 'other':
      return RangeTag.other;
    default:
      return null;
  }
}

/// RangeTag를 문자열로 변환한다 (소문자)
String? _rangeTagToString(RangeTag? tag) {
  if (tag == null) return null;
  return tag.name;
}

// ─── Event 직렬화 확장 ──────────────────────────────────────────────────────

/// Map 직렬화 메서드를 제공하는 확장
/// INSERT/UPDATE 시 Map으로 변환하는 로직을 분리한다.
extension EventSerialization on Event {
  /// INSERT용 Map (id 제외, user_id 포함)
  /// end_date는 항상 포함하여 null 명시 (Hive put 대체 시 기존 값이 남지 않도록)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'event_type': _eventTypeToString(eventType),
      'start_date': DateParser.toIso8601(startDate),
      'end_date': endDate != null ? DateParser.toIso8601(endDate!) : null,
      'all_day': allDay,
      'color': color,
      'color_index': colorIndex,
      'location': location,
      'recurrence_rule': recurrenceRule,
      'range_tag': _rangeTagToString(rangeTag),
      'memo': memo,
    };
  }

  /// UPDATE용 Map (id, user_id 제외)
  /// end_date는 항상 포함하여 null 명시
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'event_type': _eventTypeToString(eventType),
      'start_date': DateParser.toIso8601(startDate),
      'end_date': endDate != null ? DateParser.toIso8601(endDate!) : null,
      'all_day': allDay,
      'color': color,
      'color_index': colorIndex,
      'location': location,
      'recurrence_rule': recurrenceRule,
      'range_tag': _rangeTagToString(rangeTag),
      'memo': memo,
    };
  }

  /// 레거시 호환: 기존 toCreateMap 호출부를 위한 별칭
  Map<String, dynamic> toCreateMap() => toUpdateMap();
}
