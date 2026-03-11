// Enum: ViewType - 캘린더 뷰 타입
// monthly: 월간 뷰, weekly: 주간 뷰, daily: 일간 뷰
// StateProvider와 함께 사용하여 라우트 변경 없이 뷰 전환을 처리한다

/// 캘린더 뷰 유형
enum ViewType {
  /// 월간 뷰 (기본)
  monthly,

  /// 주간 뷰 (7일 타임라인)
  weekly,

  /// 일간 뷰 (24시간 타임라인)
  daily,
}
