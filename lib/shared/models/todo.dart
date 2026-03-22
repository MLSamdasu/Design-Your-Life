// 공유 모델: Todo (투두 아이템)
// Hive todosBox에 저장되는 투두 모델이다.
// 필드: id, user_id, title, scheduled_date, start_time, end_time,
//   is_completed, color, memo, display_order, created_at
import 'package:flutter/material.dart';

import '../../core/utils/date_parser.dart';
import '../../core/utils/date_utils.dart';
import '../../core/error/app_exception.dart';

/// 투두 아이템 모델
/// Hive todosBox에 저장된다
class Todo {
  final String id;
  final String title;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isCompleted;
  final String? color;
  final String? memo;
  final int displayOrder;

  /// 연결된 태그 목록 (태그 객체)
  final List<Map<String, dynamic>> tags;

  final DateTime createdAt;

  const Todo({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.color,
    this.memo,
    this.displayOrder = 0,
    this.tags = const [],
    required this.createdAt,
  });

  // ─── UI 호환 컴퓨티드 속성 ────────────────────────────────────────────────
  // 기존 UI 코드에서 참조하는 필드에 대한 하위 호환성을 제공한다.

  /// UI에서 사용하는 시간 (startTime의 별칭)
  /// 기존 `todo.time` 참조와 호환된다
  TimeOfDay? get time => startTime;

  /// UI에서 사용하는 colorIndex (0~7)
  /// color 필드에 저장된 인덱스 문자열을 정수로 변환한다
  /// color가 null이거나 파싱 불가능하면 기본값 0을 반환한다
  int get colorIndex {
    if (color == null) return 0;
    final parsed = int.tryParse(color!);
    if (parsed == null) return 0;
    // 유효 범위(0~7)를 벗어나면 기본값 0을 반환한다
    return (parsed >= 0 && parsed <= 7) ? parsed : 0;
  }

  /// 태그 ID 목록 (UI 호환용)
  /// 태그 목록에서 id 필드를 추출하여 String 리스트로 반환한다
  List<String> get tagIds => tags
      .map((t) => t['id']?.toString())
      .where((id) => id != null)
      .cast<String>()
      .toList();

  // ─── 직렬화 ───────────────────────────────────────────────────────────────

  /// LocalTime 문자열("HH:mm:ss")에서 TimeOfDay로 변환한다
  static TimeOfDay? _timeFromString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      // "HH:mm:ss" 또는 "HH:mm" 형식을 파싱한다
      final parts = value.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    // Map 형식 호환 (레거시 데이터 지원)
    if (value is Map<String, dynamic>) {
      return TimeOfDay(
        hour: value['hour'] as int? ?? 0,
        minute: value['minute'] as int? ?? 0,
      );
    }
    return null;
  }

  /// TimeOfDay를 "HH:mm:ss" 문자열로 변환한다 (PostgreSQL time 대응)
  static String? _timeToString(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  }

  /// Map 데이터에서 Todo 객체를 생성한다
  factory Todo.fromMap(Map<String, dynamic> map) {
    try {
      return Todo(
        id: map['id']?.toString() ?? '',
        title: (map['title'] as String?) ?? '',
        // scheduled_date 필드 (date 타입 → "yyyy-MM-dd")
        date: DateParser.parse(
            map['scheduled_date'] ?? map['scheduledDate'] ?? map['date']),
        // start_time, end_time 필드 (time 타입 → "HH:mm:ss")
        startTime:
            _timeFromString(map['start_time'] ?? map['startTime']),
        endTime: _timeFromString(map['end_time'] ?? map['endTime']),
        // is_completed 필드 (boolean)
        isCompleted: map['is_completed'] as bool? ??
            map['completed'] as bool? ??
            map['isCompleted'] as bool? ??
            false,
        // color 필드 (text, nullable)
        color: map['color'] as String?,
        memo: map['memo'] as String?,
        displayOrder:
            (map['display_order'] as num?)?.toInt() ?? (map['displayOrder'] as num?)?.toInt() ?? 0,
        // 태그는 별도 조인 또는 후처리로 채운다
        tags: map['tags'] != null
            ? List<Map<String, dynamic>>.from(
                (map['tags'] as List).map((e) =>
                    e is Map<String, dynamic> ? e : <String, dynamic>{}))
            : const [],
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      // 필수 필드 타입 불일치 시 의미 있는 에러 메시지를 제공한다
      throw AppException.validation(
        'Todo 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'scheduled_date': _dateToLocalDateString(date),
      'start_time': _timeToString(startTime),
      'end_time': _timeToString(endTime),
      'color': color,
      'memo': memo,
      'is_completed': isCompleted,
      'display_order': displayOrder,
      'tags': tags,
    };
  }

  /// UPDATE용 Map (id, user_id 제외)
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'scheduled_date': _dateToLocalDateString(date),
      'start_time': _timeToString(startTime),
      'end_time': _timeToString(endTime),
      'is_completed': isCompleted,
      'color': color,
      'memo': memo,
      'display_order': displayOrder,
      'tags': tags,
    };
  }

  /// 레거시 호환: 기존 toCreateMap 호출부를 위한 별칭
  Map<String, dynamic> toCreateMap() => toUpdateMap();

  /// DateTime을 "yyyy-MM-dd" 문자열로 변환한다 (PostgreSQL date 대응)
  static String _dateToLocalDateString(DateTime dt) {
    return AppDateUtils.toDateString(dt);
  }

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Todo copyWith({
    String? title,
    DateTime? date,
    TimeOfDay? startTime,
    bool clearStartTime = false,
    TimeOfDay? endTime,
    bool clearEndTime = false,
    bool? isCompleted,
    String? color,
    bool clearColor = false,
    String? memo,
    bool clearMemo = false,
    int? displayOrder,
    List<Map<String, dynamic>>? tags,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      isCompleted: isCompleted ?? this.isCompleted,
      color: clearColor ? null : (color ?? this.color),
      memo: clearMemo ? null : (memo ?? this.memo),
      displayOrder: displayOrder ?? this.displayOrder,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }
}
