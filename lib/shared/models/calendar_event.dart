// 캘린더 뷰용 공유 데이터 모델
// CalendarEvent: 이벤트/투두를 캘린더에 표시하기 위한 뷰 모델
// RoutineEntry: 루틴을 캘린더에 표시하기 위한 뷰 모델
// core와 features 양쪽에서 사용되므로 shared/models에 위치한다
import 'package:flutter/material.dart' show Color;
import '../../core/theme/color_tokens.dart';

/// 캘린더에 표시할 이벤트 데이터 모델 (뷰용)
class CalendarEvent {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final int? startHour;
  final int? startMinute;
  final int? endHour;
  final int? endMinute;
  final int colorIndex;
  final String type; // normal, range, recurring, todo
  final String? rangeTag;
  final String? memo;
  final String? location;

  /// 종일 이벤트 여부 (true이면 시간 없이 종일 표시)
  final bool isAllDay;

  /// 이벤트 출처 (F17: Google Calendar 연동)
  /// 'app': 앱에서 생성한 이벤트 (기본값, 기존 동작 유지)
  /// 'google': Google Calendar에서 가져온 이벤트
  final String source;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
    required this.colorIndex,
    required this.type,
    this.rangeTag,
    this.memo,
    this.location,
    this.isAllDay = false,
    this.source = 'app',
  });

  /// Google Calendar에서 가져온 이벤트인지 여부
  bool get isGoogleEvent => source == 'google';

  /// todosBox에서 변환된 투두 이벤트인지 여부
  bool get isTodoEvent => source == 'todo' || source == 'todo_completed';

  /// 투두가 완료 상태인지 여부
  bool get isTodoCompleted => source == 'todo_completed';

  /// 이벤트 색상 (colorIndex 기준)
  Color get color => ColorTokens.eventColor(colorIndex);
}

/// 루틴 캘린더 표시용 데이터 모델
class RoutineEntry {
  final String id;
  final String name;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final int colorIndex;

  const RoutineEntry({
    required this.id,
    required this.name,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.colorIndex,
  });
}
