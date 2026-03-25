// F4: StreakCalculator 배럴 파일
// SRP 분리: StreakResult(모델) + StreakCalculator(daily) + WeeklyStreakCalculator(weekly/custom)
// 기존 import 경로 호환성을 위해 re-export한다.
export 'streak_result.dart';
export 'streak_calculator_impl.dart';
export 'weekly_streak_calculator.dart';
