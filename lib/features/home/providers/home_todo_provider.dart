// F1: 홈 대시보드 — 오늘 투두 요약 Provider
// allTodosRawProvider(Single Source of Truth)에서 파생하여
// 투두 CRUD 시 자동으로 홈 대시보드가 갱신된다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import 'home_models.dart';

/// 오늘 투두 요약 Provider (동기)
/// allTodosRawProvider(Single Source of Truth)에서 파생하여
/// 투두 CRUD 시 todoDataVersionProvider 증가 → 이 Provider 자동 갱신
final todayTodosProvider = Provider<TodoSummary>((ref) {
  // 단일 진실 원천(SSOT): allTodosRawProvider에서 파생한다
  final allTodos = ref.watch(allTodosRawProvider);
  // 자정 경계 불일치 방지: 공유 todayDateProvider를 사용한다
  final today = ref.watch(todayDateProvider);
  final dateStr = AppDateUtils.toDateString(today);

  try {
    // 오늘 날짜의 투두만 필터링한다
    final docs = allTodos
        .where((d) =>
            (d['scheduled_date'] as String?)?.startsWith(dateStr) == true)
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
  } catch (e, stack) {
    ErrorHandler.logServiceError('HomeProvider:todayTodos', e, stack);
    return TodoSummary.empty;
  }
});
