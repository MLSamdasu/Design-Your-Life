// 공유 모델: TodoTimeUtils (투두 시간 직렬화 유틸리티)
// Todo 모델의 시간/날짜 직렬화·역직렬화 헬퍼 (SRP 분리)
import 'package:flutter/material.dart';
import '../../core/utils/date_utils.dart';

/// Todo 시간 필드 직렬화·역직렬화 헬퍼
/// TimeOfDay ↔ "HH:mm:ss" 문자열 변환, DateTime → "yyyy-MM-dd" 변환을 담당한다
class TodoTimeUtils {
  const TodoTimeUtils._();

  /// LocalTime 문자열("HH:mm:ss")에서 TimeOfDay로 변환한다
  static TimeOfDay? timeFromString(dynamic value) {
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
  static String? timeToString(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  }

  /// DateTime을 "yyyy-MM-dd" 문자열로 변환한다 (PostgreSQL date 대응)
  static String dateToLocalDateString(DateTime dt) {
    return AppDateUtils.toDateString(dt);
  }
}
