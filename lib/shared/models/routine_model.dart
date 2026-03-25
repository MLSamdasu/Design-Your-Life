// 공유 모델: Routine (주간 반복 루틴) — 클래스 정의 + copyWith
// Hive routinesBox에 저장되는 루틴 모델이다.
// 필드: id, user_id, name, days_of_week, start_time, end_time,
//   color, is_active, created_at, updated_at
// days_of_week: text[] 배열 ("MON","TUE",...) — Java DayOfWeek enum 약어
// start_time/end_time: time 타입 "HH:mm:ss"
// color: text "#RRGGBB" hex 문자열
import 'package:flutter/material.dart';

import '../../core/utils/date_parser.dart';
import '../../core/error/app_exception.dart';

part 'routine_serialization.dart';

/// 주간 반복 루틴 모델
/// Hive routinesBox에 저장된다
class Routine {
  final String id;
  final String userId;
  final String name;
  final List<int> repeatDays;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int colorIndex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Routine({
    required this.id,
    required this.userId,
    required this.name,
    required this.repeatDays,
    required this.startTime,
    required this.endTime,
    required this.colorIndex,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Map 데이터에서 Routine 객체를 생성한다
  factory Routine.fromMap(Map<String, dynamic> map) =>
      _RoutineSerialization.fromMap(map);

  /// INSERT용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) =>
      _RoutineSerialization.toInsertMap(this, userId);

  /// UPDATE용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toUpdateMap() =>
      _RoutineSerialization.toUpdateMap(this);

  /// 레거시 호환: 기존 toMap 호출부를 위한 별칭
  Map<String, dynamic> toMap() => toUpdateMap();

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  Routine copyWith({
    String? name,
    List<int>? repeatDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? colorIndex,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id,
      userId: userId,
      name: name ?? this.name,
      repeatDays: repeatDays ?? this.repeatDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorIndex: colorIndex ?? this.colorIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
