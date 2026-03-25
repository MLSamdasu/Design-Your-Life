// F6: 타이머 통계 데이터 모델
// 주간/월간 통계 요약 및 시간대별 분류를 위한 불변 데이터 클래스를 정의한다.
// TimerStatsView에서 Provider를 통해 소비된다.

/// 주간 타이머 통계 요약 모델
/// weeklyStatsProvider에서 생성되어 TimerWeeklyChart에 표시된다
class TimerWeeklyStats {
  /// 주간 총 집중 시간 (분 단위)
  final int totalFocusMinutes;

  /// 주간 총 집중 세션 수
  final int totalSessions;

  /// 실제로 집중한 일 수 (1분 이상)
  final int activeDays;

  /// 일 평균 집중 시간 (분 단위, 7일 기준)
  final double dailyAverage;

  const TimerWeeklyStats({
    required this.totalFocusMinutes,
    required this.totalSessions,
    required this.activeDays,
    required this.dailyAverage,
  });

  /// 빈 통계 (데이터 없을 때)
  static const empty = TimerWeeklyStats(
    totalFocusMinutes: 0,
    totalSessions: 0,
    activeDays: 0,
    dailyAverage: 0,
  );
}

/// 월간 타이머 통계 요약 모델
/// monthlyStatsProvider에서 생성되어 TimerMonthlyStats에 표시된다
class TimerMonthlyStats {
  /// 월간 총 집중 시간 (분 단위)
  final int totalFocusMinutes;

  /// 월간 총 집중 세션 수
  final int totalSessions;

  /// 실제로 집중한 일 수 (1분 이상)
  final int activeDays;

  /// 일 평균 집중 시간 (분 단위, 해당 월 일수 기준)
  final double dailyAverage;

  /// 연속 집중 최장 일수 (스트릭)
  final int longestStreak;

  const TimerMonthlyStats({
    required this.totalFocusMinutes,
    required this.totalSessions,
    required this.activeDays,
    required this.dailyAverage,
    required this.longestStreak,
  });

  /// 빈 통계 (데이터 없을 때)
  static const empty = TimerMonthlyStats(
    totalFocusMinutes: 0,
    totalSessions: 0,
    activeDays: 0,
    dailyAverage: 0,
    longestStreak: 0,
  );
}

/// 월간 일별 집중 시간 구간별 분류 모델
/// 각 구간에 해당하는 일수를 저장한다
class TimerFocusTiers {
  /// 1시간 이하 (≤60분) 일수
  final int under1h;

  /// 3시간 이하 (61~180분) 일수
  final int under3h;

  /// 6시간 이하 (181~360분) 일수
  final int under6h;

  /// 10시간 이하 (361~600분) 일수
  final int under10h;

  /// 10시간 초과 (>600분) 일수
  final int over10h;

  const TimerFocusTiers({
    required this.under1h,
    required this.under3h,
    required this.under6h,
    required this.under10h,
    required this.over10h,
  });

  /// 빈 티어 (데이터 없을 때)
  static const empty = TimerFocusTiers(
    under1h: 0,
    under3h: 0,
    under6h: 0,
    under10h: 0,
    over10h: 0,
  );

  /// 전체 활동 일수 (1분 이상 집중한 날)
  int get totalActiveDays =>
      under1h + under3h + under6h + under10h + over10h;
}
