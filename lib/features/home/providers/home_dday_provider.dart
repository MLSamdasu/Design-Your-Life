// F1: 홈 D-Day + 주간 요약 Provider (SRP 분리)
// home_provider.dart에서 추출한다.
// 포함: upcomingDdaysProvider, weekSummaryProvider
// Hive 캐시를 통해 데이터를 조회한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/enums/urgency_level.dart';
import 'home_provider.dart';

/// 다가오는 D-Day 목록 Provider (FutureProvider)
/// Hive 캐시를 통해 오늘 이후 이벤트를 조회한다
final upcomingDdaysProvider = FutureProvider<List<DdayItem>>((ref) async {
  final cache = ref.watch(hiveCacheServiceProvider);
  final today = AppDateUtils.startOfDay(DateTime.now());
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  try {
    // Hive에서 모든 이벤트를 가져와 오늘 이후 이벤트만 필터링한다
    final allEvents = cache.getAll(AppConstants.eventsBox);
    final docs = allEvents
        .where((doc) {
          final startDate = doc['start_date']?.toString();
          if (startDate == null) return false;
          return startDate.compareTo(todayStr) >= 0;
        })
        .toList();

    // start_date 기준 오름차순 정렬
    docs.sort((a, b) {
      final aDate = a['start_date']?.toString() ?? '';
      final bDate = b['start_date']?.toString() ?? '';
      return aDate.compareTo(bDate);
    });

    // 최대 10개까지만 표시한다
    final limitedDocs = docs.take(10).toList();

    final items = limitedDocs
        .map((doc) {
          // start_date가 null인 이벤트는 D-Day 계산이 불가하므로 건너뛴다
          if (doc['start_date'] == null) return null;
          final startDate = DateTime.parse(doc['start_date'] as String);
          final diff = startDate.difference(today).inDays;

          final urgency = diff <= 3
              ? UrgencyLevel.critical
              : diff <= 7
                  ? UrgencyLevel.warning
                  : UrgencyLevel.normal;

          final label = '${startDate.month}월 ${startDate.day}일';
          return DdayItem(
            id: doc['id']?.toString() ?? '',
            eventName: doc['title'] as String? ?? '',
            daysRemaining: diff,
            dateLabel: label,
            urgencyLevel: urgency,
          );
        })
        .whereType<DdayItem>()
        .toList();

    items.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return items;
  } catch (_) {
    return const [];
  }
});

/// 오늘의 요약 Provider (파생)
/// todayTodosProvider와 todayHabitsProvider의 오늘 데이터를 결합한다
final weekSummaryProvider = Provider<AsyncValue<WeeklySummary>>((ref) {
  final todosAsync = ref.watch(todayTodosProvider);
  final habitsAsync = ref.watch(todayHabitsProvider);

  return todosAsync.when(
    data: (todos) => habitsAsync.when(
      data: (habits) => AsyncData(WeeklySummary(
        todoWeekRate: todos.completionRate,
        habitWeekRate: habits.achievementRate,
      )),
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
    ),
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
  );
});
