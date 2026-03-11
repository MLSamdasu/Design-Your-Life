// F4: TimeLockValidator (F4.4) - 순수 함수
// targetDate: DateTime, now: DateTime을 받아
// isEditable(bool)과 reason(String)을 반환한다.
// 자정 기준: 오늘(00:00~23:59)만 편집 가능, 과거일은 잠금한다.

/// 시간 잠금 검증 결과
class TimeLockResult {
  final bool isEditable;
  final String reason;

  const TimeLockResult({
    required this.isEditable,
    required this.reason,
  });
}

/// 시간 잠금 검증기 (F4.4 순수 함수)
/// 습관 체크는 오늘(00:00~23:59)만 가능하다.
/// 자정 이후 어제 습관은 읽기 전용이 된다.
abstract class TimeLockValidator {
  /// targetDate가 편집 가능한지 검증한다
  /// now: 현재 시각 (클라이언트 시간, DateTime.now())
  static TimeLockResult validate(DateTime targetDate, DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final targetStart = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    if (targetStart.isAtSameMomentAs(todayStart)) {
      return const TimeLockResult(
        isEditable: true,
        reason: '오늘 날짜입니다',
      );
    }

    if (targetStart.isBefore(todayStart)) {
      return const TimeLockResult(
        isEditable: false,
        reason: '지난 날짜는 수정할 수 없어요',
      );
    }

    // 미래 날짜: 읽기 전용
    return const TimeLockResult(
      isEditable: false,
      reason: '미래 날짜는 아직 체크할 수 없어요',
    );
  }

  /// 오늘인지 빠르게 확인 (UI 비활성화 여부)
  static bool isToday(DateTime targetDate, DateTime now) {
    return targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;
  }
}
