// 공유 모델: Event (캘린더 일정)
// Hive eventsBox에 저장되는 이벤트 모델이다.
// 필드: id, user_id, title, description, event_type, start_date, end_date,
//   all_day, color, color_index, location, recurrence_rule, range_tag, memo, created_at
// dDay는 startDate 기준으로 매번 계산하는 컴퓨티드 속성이다.
import '../../core/utils/date_parser.dart';
import '../../core/utils/date_utils.dart';
import '../../core/error/app_exception.dart';

/// 캘린더 이벤트 유형
enum EventType {
  normal,    // 일반 일정
  range,     // 범위 일정 (시작~종료일)
  recurring, // 반복 일정
  todo,      // 투두 연동 일정
}

/// 범위 일정 태그
enum RangeTag {
  travel,    // 여행
  exam,      // 시험
  vacation,  // 휴가
  project,   // 프로젝트
  other,     // 기타
}

/// 캘린더 일정 모델
/// Hive eventsBox에 저장된다
class Event {
  /// 문서 ID (BIGINT → String 변환)
  final String id;

  /// 일정 제목 (최대 200자)
  final String title;

  /// 일정 설명
  final String? description;

  /// 일정 유형
  final EventType eventType;

  /// 시작 날짜시간
  final DateTime startDate;

  /// 종료 날짜시간 (nullable)
  final DateTime? endDate;

  /// 종일 일정 여부
  final bool allDay;

  /// 색상 (hex 문자열)
  final String? color;

  /// 위치 정보
  final String? location;

  /// 반복 규칙 (iCalendar RRULE 형식)
  final String? recurrenceRule;

  /// 범위 태그 (RANGE 타입에서만 사용)
  final RangeTag? rangeTag;

  /// 메모
  final String? memo;

  /// 색상 인덱스 (0~7, UI 색상 팔레트 인덱스)
  final int colorIndex;

  final DateTime createdAt;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.eventType,
    required this.startDate,
    this.endDate,
    this.allDay = false,
    this.color,
    this.location,
    this.recurrenceRule,
    this.rangeTag,
    this.memo,
    this.colorIndex = 0,
    required this.createdAt,
  });

  // ─── UI 호환 컴퓨티드 속성 ────────────────────────────────────────────────

  /// D-Day 계산 (startDate 기준, 저장하지 않고 매번 계산한다)
  /// [referenceDate]를 외부에서 전달받아 리스트 순회 시 동일한 기준 날짜를 사용한다.
  /// 기존 getter 방식은 매 접근마다 DateTime.now()를 호출하여 20건 이벤트에서
  /// 20개의 독립 호출이 발생하는 문제가 있었다.
  int dDayFrom(DateTime referenceDate) =>
      startDate.difference(AppDateUtils.startOfDay(referenceDate)).inDays;

  /// UI에서 사용하는 userId (빈 문자열)
  String get userId => '';

  // ─── Enum 변환 ─────────────────────────────────────────────────────────────

  /// event_type 문자열에서 enum으로 변환한다
  static EventType _eventTypeFromString(String? value) {
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
  static String _eventTypeToString(EventType type) {
    return type.name;
  }

  /// range_tag 문자열에서 enum으로 변환한다
  static RangeTag? _rangeTagFromString(String? value) {
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
  static String? _rangeTagToString(RangeTag? tag) {
    if (tag == null) return null;
    return tag.name;
  }

  /// Map 데이터에서 Event 객체를 생성한다
  factory Event.fromMap(Map<String, dynamic> map) {
    try {
      return Event(
        id: map['id']?.toString() ?? '',
        title: (map['title'] as String?) ?? '',
        description: map['description'] as String?,
        // event_type 필드 (text)
        eventType: _eventTypeFromString(
            (map['event_type'] ?? map['eventType'] ?? map['type'])
                ?.toString()),
        startDate: DateParser.parse(
            map['start_date'] ?? map['startDate']),
        endDate: DateParser.parseNullable(
            map['end_date'] ?? map['endDate']),
        allDay: map['all_day'] as bool? ?? map['allDay'] as bool? ?? false,
        color: map['color'] as String?,
        location: map['location'] as String?,
        recurrenceRule: (map['recurrence_rule'] ?? map['recurrenceRule'])
            as String?,
        rangeTag: _rangeTagFromString(
            (map['range_tag'] ?? map['rangeTag'])?.toString()),
        memo: map['memo'] as String?,
        colorIndex: (map['color_index'] as num?)?.toInt() ??
            (map['colorIndex'] as num?)?.toInt() ??
            0,
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'Event 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  /// P1-4: end_date는 항상 포함하여 null 명시 (Hive put 대체 시 기존 값이 남지 않도록)
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
  /// P1-4: end_date는 항상 포함하여 null 명시
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

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Event copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    EventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? allDay,
    String? color,
    bool clearColor = false,
    String? location,
    bool clearLocation = false,
    String? recurrenceRule,
    bool clearRecurrenceRule = false,
    RangeTag? rangeTag,
    bool clearRangeTag = false,
    String? memo,
    bool clearMemo = false,
    int? colorIndex,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      eventType: eventType ?? this.eventType,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      allDay: allDay ?? this.allDay,
      color: clearColor ? null : (color ?? this.color),
      location: clearLocation ? null : (location ?? this.location),
      recurrenceRule: clearRecurrenceRule
          ? null
          : (recurrenceRule ?? this.recurrenceRule),
      rangeTag: clearRangeTag ? null : (rangeTag ?? this.rangeTag),
      memo: clearMemo ? null : (memo ?? this.memo),
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
    );
  }
}
