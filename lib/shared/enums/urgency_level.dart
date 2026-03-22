// D-day 긴급도 열거형
// D-3 이내의 일정을 4단계로 구분하여 시각적 우선순위를 제공한다
enum UrgencyLevel {
  /// D-Day (당일): 가장 긴급 — 빨간색 강조
  imminent,

  /// D-1 (내일): 매우 긴급 — 주황색 강조
  critical,

  /// D-2 (모레): 긴급 — 노란색 강조
  warning,

  /// D-3 (3일 후): 일반 — 파란색 표시
  normal;

  /// 남은 일수로 긴급도 계산 (D-3 이내만 사용)
  static UrgencyLevel fromDaysRemaining(int daysRemaining) {
    if (daysRemaining <= 0) return UrgencyLevel.imminent;
    if (daysRemaining == 1) return UrgencyLevel.critical;
    if (daysRemaining == 2) return UrgencyLevel.warning;
    return UrgencyLevel.normal;
  }
}
