// F1: 홈 대시보드 요약/일정 데이터 모델
// home_models.dart에서 분리한 UpcomingEventItem, TodaySummary (SRP 분리)

/// 다가오는 일정 아이템 (이벤트 + 미완료 투두 통합)
class UpcomingEventItem {
  /// 이벤트 또는 투두 ID
  final String id;

  /// 일정/투두 제목
  final String title;

  /// 시간 라벨 ("14:00 ~ 15:30" 또는 "종일")
  final String timeLabel;

  /// 색상 인덱스 (0~8, ColorTokens.eventColor 참조)
  final int colorIndex;

  /// 투두에서 변환된 항목인지 여부
  final bool isTodoEvent;

  /// Google Calendar에서 가져온 항목인지 여부
  final bool isGoogleEvent;

  /// 투두 완료 여부 (isTodoEvent가 true일 때만 유의미하다)
  final bool isCompleted;

  const UpcomingEventItem({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.colorIndex,
    required this.isTodoEvent,
    this.isGoogleEvent = false,
    this.isCompleted = false,
  });
}

/// 오늘의 요약 (투두 완료율 + 습관 달성률 + 구글 일정 개수)
class TodaySummary {
  final double todoTodayRate;
  final double habitTodayRate;

  /// 오늘의 Google Calendar 이벤트 개수
  final int googleEventCount;

  const TodaySummary({
    required this.todoTodayRate,
    required this.habitTodayRate,
    this.googleEventCount = 0,
  });

  static const empty = TodaySummary(
    todoTodayRate: 0,
    habitTodayRate: 0,
    googleEventCount: 0,
  );
}
