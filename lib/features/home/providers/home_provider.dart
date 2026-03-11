// F1: 홈 대시보드 투두 + 습관 Riverpod Provider
// todayTodosProvider, todayHabitsProvider
// Hive 캐시를 통해 대시보드 요약 데이터를 조회한다.
// SRP 분리: 뷰 데이터 모델 → home_models.dart, D-Day/주간 → home_dday_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/utils/date_utils.dart';
import 'home_models.dart';

export 'home_models.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

/// 오늘 투두 요약 Provider (FutureProvider)
/// Hive 캐시를 통해 오늘 날짜의 투두를 조회하여 집계한다
final todayTodosProvider = FutureProvider<TodoSummary>((ref) async {
  final cache = ref.watch(hiveCacheServiceProvider);
  final today = AppDateUtils.startOfDay(DateTime.now());
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  try {
    // Hive에서 모든 투두를 가져와 오늘 날짜의 투두만 필터링한다
    final allTodos = cache.getAll(AppConstants.todosBox);
    final docs = allTodos
        .where((d) => d['scheduled_date'] == dateStr)
        .toList();

    // display_order로 정렬한다
    docs.sort((a, b) {
      final orderA = (a['display_order'] as num?)?.toInt() ?? 0;
      final orderB = (b['display_order'] as num?)?.toInt() ?? 0;
      return orderA.compareTo(orderB);
    });

    final total = docs.length;
    final completed = docs
        .where((d) => d['is_completed'] == true)
        .length;
    final rate = total > 0 ? (completed / total) * 100 : 0.0;

    // 미완료 우선 정렬 후 최대 5개
    final previewDocs = [
      ...docs.where((d) => d['is_completed'] != true),
      ...docs.where((d) => d['is_completed'] == true),
    ].take(5).toList();

    return TodoSummary(
      totalCount: total,
      completedCount: completed,
      completionRate: rate,
      previewItems: previewDocs.map((doc) {
        return TodoPreviewItem(
          id: doc['id']?.toString() ?? '',
          title: doc['title'] as String? ?? '',
          isCompleted: doc['is_completed'] as bool? ?? false,
        );
      }).toList(),
    );
  } catch (_) {
    return TodoSummary.empty;
  }
});

/// 오늘 습관 요약 Provider (FutureProvider)
/// Hive 캐시를 통해 오늘 활성 습관과 로그를 각각 조회하여 결합한다
final todayHabitsProvider = FutureProvider<HabitSummary>((ref) async {
  final cache = ref.watch(hiveCacheServiceProvider);
  final today = AppDateUtils.startOfDay(DateTime.now());
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  try {
    // Hive에서 활성 습관 목록을 가져온다
    final allHabits = cache.getAll(AppConstants.habitsBox);
    final habits = allHabits
        .where((h) => h['is_active'] == true)
        .toList();

    // created_at 기준으로 정렬한다
    habits.sort((a, b) {
      final aTime = a['created_at']?.toString() ?? '';
      final bTime = b['created_at']?.toString() ?? '';
      return aTime.compareTo(bTime);
    });

    // Hive에서 오늘의 습관 로그를 가져온다
    final allLogs = cache.getAll(AppConstants.habitLogsBox);
    final logs = allLogs
        .where((d) => d['log_date'] == dateStr)
        .toList();

    if (habits.isEmpty) return HabitSummary.empty;

    // 완료된 습관 ID 집합 추출
    final completedIds = logs
        .where((d) => d['is_completed'] == true)
        .map((d) => d['habit_id']?.toString() ?? '')
        .toSet();

    final total = habits.length;
    final completedCount = habits
        .where((h) => completedIds.contains(h['id']?.toString()))
        .length;
    final rate = total > 0 ? (completedCount / total) * 100 : 0.0;

    // 미완료 우선 최대 3개
    final preview = [
      ...habits.where((h) =>
          !completedIds.contains(h['id']?.toString())),
      ...habits.where((h) =>
          completedIds.contains(h['id']?.toString())),
    ].take(3).toList();

    return HabitSummary(
      totalCount: total,
      completedCount: completedCount,
      achievementRate: rate,
      previewItems: preview.map((doc) {
        return HabitPreviewItem(
          id: doc['id']?.toString() ?? '',
          name: doc['name'] as String? ?? '',
          icon: doc['icon'] as String?,
          isCompleted: completedIds.contains(doc['id']?.toString()),
          streak: 0,
        );
      }).toList(),
    );
  } catch (_) {
    return HabitSummary.empty;
  }
});
