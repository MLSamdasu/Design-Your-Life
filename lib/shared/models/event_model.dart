// 캘린더 이벤트 모델 — 클래스 정의, 필드, 생성자, fromMap, copyWith
// Hive eventsBox에 저장되는 이벤트 모델이다.
// 직렬화(toInsertMap/toUpdateMap)와 enum 변환 헬퍼는 event_serialization.dart에 분리한다.
import '../../core/utils/date_parser.dart';
import '../../core/utils/date_utils.dart';
import '../../core/error/app_exception.dart';

part 'event_serialization.dart';

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

  // ─── UI 호환 컴퓨티드 속성 ──────────────────────────────────────────────

  /// D-Day 계산 (startDate 기준, 저장하지 않고 매번 계산한다)
  /// [referenceDate]를 외부에서 전달받아 리스트 순회 시 동일한 기준 날짜를 사용한다.
  int dDayFrom(DateTime referenceDate) =>
      startDate.difference(AppDateUtils.startOfDay(referenceDate)).inDays;

  /// UI에서 사용하는 userId (빈 문자열)
  String get userId => '';

  /// Map 데이터에서 Event 객체를 생성한다
  factory Event.fromMap(Map<String, dynamic> map) {
    try {
      return Event(
        id: map['id']?.toString() ?? '',
        title: (map['title'] as String?) ?? '',
        description: map['description'] as String?,
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
