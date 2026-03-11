// F2: 캘린더 UI 상태 Provider
// selectedViewTypeProvider: 월간/주간/일간 전환 상태 (StateProvider)
// selectedCalendarDateProvider: 선택된 날짜 상태 (StateProvider)
// 서브탭 상태는 라우트가 아닌 StateProvider로 관리한다 (spec.md 3.5절)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/enums/view_type.dart';

/// 캘린더 뷰 유형 상태 (월간/주간/일간)
/// StateProvider로 관리하여 라우트 변경 없이 탭 전환
final calendarViewTypeProvider = StateProvider<ViewType>((ref) {
  // 기본: 월간 뷰
  return ViewType.monthly;
});

/// 선택된 캘린더 날짜 상태
/// 월간 그리드에서 날짜를 탭하면 업데이트된다
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  // 기본: 오늘
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 현재 표시 중인 월 (월간 뷰의 캘린더 포커스 월)
final focusedCalendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});
