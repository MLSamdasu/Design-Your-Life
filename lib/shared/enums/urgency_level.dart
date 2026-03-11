// D-day 긴급도 열거형
// D-day 카드에서 일정의 긴급도를 시각적으로 구분하는 데 사용한다
enum UrgencyLevel {
  /// 위험: D-3 이하 (빨간색 강조 표시)
  critical,

  /// 경고: D-7 이하 (노란색 표시)
  warning,

  /// 일반: D-8 이상 (기본 표시)
  normal;

  /// 남은 일수로 긴급도 계산
  static UrgencyLevel fromDaysRemaining(int daysRemaining) {
    if (daysRemaining <= 3) return UrgencyLevel.critical;
    if (daysRemaining <= 7) return UrgencyLevel.warning;
    return UrgencyLevel.normal;
  }
}
