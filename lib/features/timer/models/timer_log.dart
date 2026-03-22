// F6: 타이머 로그 데이터 모델
// Hive timerLogsBox에 저장되는 타이머 로그 모델이다.
// 필드: id, user_id, todo_id, todo_title, start_time, end_time,
//   duration_seconds, type, created_at
import '../../../core/utils/date_parser.dart';
import '../../../core/error/app_exception.dart';

/// 타이머 세션 유형
/// 문자열('focus', 'short_break', 'long_break')로 직렬화된다
enum TimerSessionType {
  /// 집중 세션 (25분)
  focus,

  /// 짧은 휴식 세션 (5분)
  shortBreak,

  /// 긴 휴식 세션 (15분, 4회차 후 자동 전환)
  longBreak,
}

/// TimerSessionType → JSON 문자열 변환 헬퍼
extension TimerSessionTypeX on TimerSessionType {
  /// 직렬화용 문자열 반환
  String toJsonValue() {
    switch (this) {
      case TimerSessionType.focus:
        return 'focus';
      case TimerSessionType.shortBreak:
        return 'short_break';
      case TimerSessionType.longBreak:
        return 'long_break';
    }
  }

  /// 사용자에게 표시할 한국어 레이블 반환
  String get displayLabel {
    switch (this) {
      case TimerSessionType.focus:
        return '집중';
      case TimerSessionType.shortBreak:
        return '짧은 휴식';
      case TimerSessionType.longBreak:
        return '긴 휴식';
    }
  }
}

/// 문자열 → TimerSessionType 변환 헬퍼
TimerSessionType timerSessionTypeFromString(String value) {
  switch (value) {
    case 'focus':
      return TimerSessionType.focus;
    case 'shortBreak':
    case 'short_break':
      return TimerSessionType.shortBreak;
    case 'longBreak':
    case 'long_break':
      return TimerSessionType.longBreak;
    default:
      // 알 수 없는 값은 기본적으로 focus로 처리한다
      return TimerSessionType.focus;
  }
}

/// 포모도로 타이머 기록 모델
/// Hive timerLogsBox에 저장된다
class TimerLog {
  final String id;
  final String userId;

  /// 연결된 투두 ID (선택, 연결하지 않은 경우 null)
  final String? todoId;

  /// 연결된 투두 제목 (비정규화, 조회 최적화용)
  final String? todoTitle;

  /// 세션 시작 시각
  final DateTime startTime;

  /// 세션 종료 시각
  final DateTime endTime;

  /// 실제 집중/휴식 시간 (초 단위, 0 이상)
  final int durationSeconds;

  /// 세션 유형 (집중/짧은 휴식/긴 휴식)
  final TimerSessionType type;

  /// 문서 생성 시각
  final DateTime createdAt;

  const TimerLog({
    required this.id,
    required this.userId,
    this.todoId,
    this.todoTitle,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.type,
    required this.createdAt,
  });

  /// Map 데이터에서 TimerLog 객체를 생성한다
  factory TimerLog.fromMap(Map<String, dynamic> map) {
    try {
      return TimerLog(
        id: map['id']?.toString() ?? '',
        userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
        todoId: (map['todo_id'] ?? map['todoId'])?.toString(),
        todoTitle: (map['todo_title'] ?? map['todoTitle']) as String?,
        startTime: DateParser.parse(
            map['start_time'] ?? map['startTime']),
        endTime: DateParser.parse(
            map['end_time'] ?? map['endTime']),
        durationSeconds: (map['duration_seconds'] as num?)?.toInt() ??
            (map['durationSeconds'] as num?)?.toInt() ??
            0,
        type: timerSessionTypeFromString(
            (map['type'] as String?) ?? 'focus'),
        createdAt: DateParser.parse(
            map['created_at'] ?? map['createdAt'] ?? DateTime.now()),
      );
    } on TypeError catch (e) {
      throw AppException.validation(
        'TimerLog 파싱 실패 (id: ${map['id']}): 필드 타입이 올바르지 않습니다. 원인: $e',
      );
    }
  }

  /// INSERT용 Map (id 제외, user_id 포함)
  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'todo_id': todoId,
      'todo_title': todoTitle,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_seconds': durationSeconds,
      'type': type.toJsonValue(),
    };
  }

  /// 레거시 호환: 기존 toMap 호출부를 위한 별칭
  Map<String, dynamic> toMap() => toInsertMap(userId);

  /// 불변 업데이트: 특정 필드만 변경된 새 인스턴스를 반환한다
  TimerLog copyWith({
    String? todoId,
    bool clearTodoId = false,
    String? todoTitle,
    bool clearTodoTitle = false,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    TimerSessionType? type,
  }) {
    return TimerLog(
      id: id,
      userId: userId,
      todoId: clearTodoId ? null : (todoId ?? this.todoId),
      todoTitle: clearTodoTitle ? null : (todoTitle ?? this.todoTitle),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      type: type ?? this.type,
      createdAt: createdAt,
    );
  }
}
