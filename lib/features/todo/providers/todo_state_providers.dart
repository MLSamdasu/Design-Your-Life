// F3: 투두 UI 상태 Provider
// 날짜 선택, 서브탭, 년/월 포커스 등 UI 상태를 관리한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';

// ─── 날짜 선택 Provider ─────────────────────────────────────────────────────

/// 투두 탭에서 선택된 날짜 Provider
/// 초기값: 공유 todayDateProvider에서 가져온 오늘 날짜 (자정 경계 불일치 방지)
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return ref.read(todayDateProvider);
});

// ─── 서브탭 Provider ────────────────────────────────────────────────────────

/// 투두 서브탭 유형
enum TodoSubTab {
  /// 일정표 (타임라인)
  dailySchedule,

  /// 주간 루틴 (신규)
  weeklyRoutine,

  /// 할 일 (체크리스트)
  todoList,
}

/// 투두 서브탭 Provider
/// dailySchedule / todoList 전환
final todoSubTabProvider = StateProvider<TodoSubTab>((ref) {
  return TodoSubTab.dailySchedule;
});

// ─── 년/월 피커 Provider ────────────────────────────────────────────────────

/// 투두 화면 헤더의 년/월 표시용 포커스 날짜
/// selectedDateProvider와 동기화된다
final todoFocusedMonthProvider = StateProvider<DateTime>((ref) {
  final selected = ref.watch(selectedDateProvider);
  return DateTime(selected.year, selected.month, 1);
});
