// F4-State: 습관 상태/리포지토리 Provider
// 서브탭, 선택 날짜, 포커스 월, 리포지토리, 활성 습관 목록 등
// 다른 습관 Provider 파일이 의존하는 기반 Provider를 정의한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/data_store_providers.dart';
import '../../../core/providers/global_providers.dart';
import '../../../shared/models/habit.dart';
import '../services/habit_repository.dart';
import '../services/habit_log_repository.dart';

// ─── 서브탭 Provider ────────────────────────────────────────────────────────

/// 습관 서브탭 유형
enum HabitSubTab {
  /// 습관 트래커
  tracker,

  /// 내 루틴
  routine,
}

/// 습관 화면 서브탭 Provider
final habitSubTabProvider = StateProvider<HabitSubTab>((ref) {
  return HabitSubTab.tracker;
});

// ─── Repository Provider ────────────────────────────────────────────────────

/// HabitRepository Provider
/// HiveCacheService를 주입하여 로컬 퍼스트로 동작한다
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return HabitRepository(cache: cache);
});

/// HabitLogRepository Provider
/// HiveCacheService를 주입하여 로컬 퍼스트로 동작한다
final habitLogRepositoryProvider = Provider<HabitLogRepository>((ref) {
  final cache = ref.watch(hiveCacheServiceProvider);
  return HabitLogRepository(cache: cache);
});

// ─── 습관 목록 Provider ───────────────────────────────────────────────────

/// 활성 습관 목록 Provider (동기 Provider)
/// allHabitsRawProvider(Single Source of Truth)에서 파생하여 CRUD 시 자동 갱신된다
/// Hive는 동기 API이므로 FutureProvider가 불필요하다 — AsyncValue 로딩 깜빡임을 제거한다
final activeHabitsProvider = Provider<List<Habit>>((ref) {
  // 단일 진실 원천(SSOT): allHabitsRawProvider에서 파생한다
  final allHabits = ref.watch(allHabitsRawProvider);
  return allHabits
      .where((h) => h['is_active'] == true)
      .map((h) => Habit.fromMap(h))
      .toList();
});

// ─── 선택된 날짜 Provider ───────────────────────────────────────────────────

/// 습관 캘린더에서 선택된 날짜 Provider
final habitSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 습관 캘린더 현재 표시 월 Provider
final habitFocusedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});
