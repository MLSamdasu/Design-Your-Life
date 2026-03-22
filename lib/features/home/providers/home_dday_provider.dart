// F1: 홈 D-Day + 오늘의 요약 Provider (Single Source of Truth)
// allEventsRawProvider에서 파생하여 이벤트 CRUD 시 자동 갱신된다.
// 포함: upcomingDdaysProvider, todaySummaryProvider
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/enums/urgency_level.dart';
import 'home_provider.dart';

/// 다가오는 D-Day 목록 Provider (동기)
/// allEventsRawProvider(Single Source of Truth)에서 파생하여
/// 이벤트 CRUD 시 eventDataVersionProvider 증가 → 이 Provider 자동 갱신
final upcomingDdaysProvider = Provider<List<DdayItem>>((ref) {
  // Single Source of Truth: allEventsRawProvider에서 파생한다
  final allEvents = ref.watch(allEventsRawProvider);
  // 자정 경계 불일치 방지: 공유 todayDateProvider를 사용한다
  final today = ref.watch(todayDateProvider);
  final todayStr = AppDateUtils.toDateString(today);

  try {
    // D-3 이내(오늘~3일 후) 이벤트만 필터링한다
    final maxDateStr = AppDateUtils.toDateString(
      today.add(const Duration(days: 3)),
    );

    final docs = allEvents
        .where((doc) {
          final raw = doc['start_date']?.toString();
          if (raw == null) return false;
          // 날짜 부분(YYYY-MM-DD)만 추출하여 범위를 비교한다
          final datePart = raw.length >= 10 ? raw.substring(0, 10) : raw;
          return datePart.compareTo(todayStr) >= 0 &&
              datePart.compareTo(maxDateStr) <= 0;
        })
        .toList();

    // start_date 기준 오름차순 정렬
    docs.sort((a, b) {
      final aDate = a['start_date']?.toString() ?? '';
      final bDate = b['start_date']?.toString() ?? '';
      return aDate.compareTo(bDate);
    });

    final items = docs
        .map((doc) {
          if (doc['start_date'] == null) return null;
          final startDate = DateTime.parse(doc['start_date'] as String);
          final diff = startDate.difference(today).inDays;

          // D-Day/D-1/D-2/D-3 4단계 긴급도 적용
          final urgency = UrgencyLevel.fromDaysRemaining(diff);

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
  } catch (e, stack) {
    ErrorHandler.logServiceError('HomeProvider:upcomingDdays', e, stack);
    return const [];
  }
});

/// 오늘의 요약 Provider (동기 파생)
/// todayTodosProvider와 todayHabitsProvider의 오늘 데이터를 결합한다
final todaySummaryProvider = Provider<TodaySummary>((ref) {
  final todos = ref.watch(todayTodosProvider);
  final habits = ref.watch(todayHabitsProvider);

  return TodaySummary(
    todoTodayRate: todos.completionRate,
    habitTodayRate: habits.achievementRate,
  );
});
