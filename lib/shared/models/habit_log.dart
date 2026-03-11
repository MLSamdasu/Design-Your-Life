// 공유 모델: HabitLog (습관 일별 체크 기록)
// Hive habitLogsBox에 저장되는 습관 체크 기록 모델이다.
// 필드: id, habit_id, user_id, log_date, is_completed, completed_at
import '../../core/utils/date_parser.dart';
import '../../core/error/app_exception.dart';

/// 습관 일별 체크 기록 모델
/// Hive habitLogsBox에 저장된다
class HabitLog {
  final String id;
  final String habitId;
  final DateTime date;
  final bool isCompleted;
  final DateTime checkedAt;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    this.isCompleted = false,
    required this.checkedAt,
  });

  /// UI 호환: userId (빈 문자열)
  String get userId => '';

  /// Map 데이터에서 HabitLog 객체를 생성한다
  factory HabitLog.fromMap(Map<String, dynamic> map) {
    try {
      return HabitLog(
        id: map['id']?.toString() ?? '',
        // habit_id 필드 (bigint)
        habitId: (map['habit_id'] ?? map['habitId']).toString(),
        // log_date 필드 (date)
        date: DateParser.parse(
            map['log_date'] ?? map['logDate'] ?? map['date']),
        // is_completed 필드 (boolean)
        isCompleted: map['is_completed'] as bool? ??
            map['completed'] as bool? ??
            map['isCompleted'] as bool? ??
            false,
        // completed_at 필드 (timestamptz)
        checkedAt: DateParser.parse(
            map['completed_at'] ?? map['completedAt'] ?? map['checkedAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'HabitLog 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (체크 생성 시)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'habit_id': int.tryParse(habitId) ?? habitId,
      'log_date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'is_completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    };
  }

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  HabitLog copyWith({
    bool? isCompleted,
    DateTime? checkedAt,
  }) {
    return HabitLog(
      id: id,
      habitId: habitId,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }
}
