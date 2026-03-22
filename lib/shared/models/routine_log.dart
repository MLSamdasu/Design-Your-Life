// 공유 모델: RoutineLog (루틴 일별 완료 기록)
// Hive routineLogsBox에 저장되는 루틴 완료 기록 모델이다.
// HabitLog 패턴을 따른다.
import '../../core/utils/date_parser.dart';
import '../../core/utils/date_utils.dart';
import '../../core/error/app_exception.dart';

/// 루틴 일별 완료 기록 모델
/// Hive routineLogsBox에 저장된다
class RoutineLog {
  final String id;
  final String routineId;
  final DateTime date;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoutineLog({
    required this.id,
    required this.routineId,
    required this.date,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Map 데이터에서 RoutineLog 객체를 생성한다
  factory RoutineLog.fromMap(Map<String, dynamic> map) {
    try {
      return RoutineLog(
        id: map['id']?.toString() ?? '',
        // null 안전: 두 키 모두 없을 경우 빈 문자열로 폴백한다
        routineId: (map['routine_id'] ?? map['routineId'] ?? '').toString(),
        date: DateParser.parse(
            map['log_date'] ?? map['logDate'] ?? map['date']),
        isCompleted: map['is_completed'] as bool? ??
            map['isCompleted'] as bool? ??
            false,
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
        updatedAt: DateParser.parse(
            map['updated_at'] ?? map['updatedAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'RoutineLog 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (HabitLog.toInsertMap 패턴 — 'id' 제외)
  /// Hive put(boxName, id, map) 호출 시 id를 키로 별도 전달한다
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'routine_id': routineId,
      'log_date': AppDateUtils.toDateString(date),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 불변 업데이트
  RoutineLog copyWith({
    bool? isCompleted,
    DateTime? updatedAt,
  }) {
    return RoutineLog(
      id: id,
      routineId: routineId,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
