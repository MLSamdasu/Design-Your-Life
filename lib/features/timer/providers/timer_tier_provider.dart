// F6: 타이머 집중 시간 구간별 분류 Provider
// 월별 일별 집중 시간을 5개 구간으로 분류하여 티어 분포를 계산한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_stats.dart';
import 'timer_stats_provider.dart';

// ─── 월간 집중 시간 구간별 분류 ────────────────────────────────────────────

/// 특정 월의 일별 집중 시간을 5개 구간으로 분류한다
/// 1시간 이하 / 3시간 이하 / 6시간 이하 / 10시간 이하 / 10시간 초과
final monthlyFocusTiersProvider =
    Provider.family<TimerFocusTiers, DateTime>((ref, month) {
  final dayMap = ref.watch(monthlyFocusMapProvider(month));

  // 활동이 있는 날(1분 이상)만 구간별로 분류한다
  int under1h = 0;
  int under3h = 0;
  int under6h = 0;
  int under10h = 0;
  int over10h = 0;

  for (final minutes in dayMap.values) {
    if (minutes <= 0) continue;
    if (minutes <= 60) {
      under1h++;
    } else if (minutes <= 180) {
      under3h++;
    } else if (minutes <= 360) {
      under6h++;
    } else if (minutes <= 600) {
      under10h++;
    } else {
      over10h++;
    }
  }

  return TimerFocusTiers(
    under1h: under1h,
    under3h: under3h,
    under6h: under6h,
    under10h: under10h,
    over10h: over10h,
  );
});
