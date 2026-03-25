// F4: 스트릭 계산 결과 모델
// StreakCalculator의 반환 타입으로, 현재 연속 일수와 최장 연속 일수를 담는다.

/// 스트릭 계산 결과
class StreakResult {
  final int currentStreak;
  final int longestStreak;

  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
  });

  static const zero = StreakResult(currentStreak: 0, longestStreak: 0);
}
