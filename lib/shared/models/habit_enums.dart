// 습관 관련 열거형 정의
// Habit 모델에서 사용하는 빈도 유형을 정의한다.

/// 습관 빈도 유형 (daily, weekly, custom)
enum HabitFrequency {
  /// 매일
  daily,

  /// 특정 요일 (주간)
  weekly,

  /// 커스텀 (특정 요일 선택)
  custom,
}
