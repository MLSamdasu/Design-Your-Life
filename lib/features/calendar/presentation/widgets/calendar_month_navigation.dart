// F2 위젯: MonthNavigation — 월/연도 네비게이션 (이전/다음 이동 + 현재 기간 텍스트)
// SRP 분리: calendar_header.dart에서 네비게이션 로직을 추출한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/view_type.dart';
import '../../providers/calendar_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 월/연도 네비게이션 (이전/다음 이동 + 현재 기간 텍스트)
class MonthNavigation extends ConsumerWidget {
  final ViewType currentView;
  final DateTime focusedMonth;
  final DateTime selectedDate;

  const MonthNavigation({
    super.key,
    required this.currentView,
    required this.focusedMonth,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headerText = _headerText();
    return Row(
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => _navigatePrev(ref),
        ),
        const SizedBox(width: AppSpacing.lg),
        Text(
          headerText,
          style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary),
        ),
        const SizedBox(width: AppSpacing.lg),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          onTap: () => _navigateNext(ref),
        ),
      ],
    );
  }

  /// 뷰 타입에 따른 헤더 텍스트 결정
  String _headerText() {
    switch (currentView) {
      case ViewType.monthly:
        return '${focusedMonth.year}년 ${focusedMonth.month}월';
      case ViewType.weekly:
        final weekStart = selectedDate
            .subtract(Duration(days: selectedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${weekStart.month}/${weekStart.day} ~ ${weekEnd.month}/${weekEnd.day}';
      case ViewType.daily:
        return '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일';
    }
  }

  /// 이전 기간으로 이동
  void _navigatePrev(WidgetRef ref) {
    switch (currentView) {
      case ViewType.monthly:
        final prev = DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
        ref.read(focusedCalendarMonthProvider.notifier).state = prev;
        break;
      case ViewType.weekly:
        final prev = selectedDate.subtract(const Duration(days: 7));
        ref.read(selectedCalendarDateProvider.notifier).state = prev;
        ref.read(focusedCalendarMonthProvider.notifier).state =
            DateTime(prev.year, prev.month, 1);
        break;
      case ViewType.daily:
        final prev = selectedDate.subtract(const Duration(days: 1));
        ref.read(selectedCalendarDateProvider.notifier).state = prev;
        ref.read(focusedCalendarMonthProvider.notifier).state =
            DateTime(prev.year, prev.month, 1);
        break;
    }
  }

  /// 다음 기간으로 이동
  void _navigateNext(WidgetRef ref) {
    switch (currentView) {
      case ViewType.monthly:
        final next = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);
        ref.read(focusedCalendarMonthProvider.notifier).state = next;
        break;
      case ViewType.weekly:
        final next = selectedDate.add(const Duration(days: 7));
        ref.read(selectedCalendarDateProvider.notifier).state = next;
        ref.read(focusedCalendarMonthProvider.notifier).state =
            DateTime(next.year, next.month, 1);
        break;
      case ViewType.daily:
        final next = selectedDate.add(const Duration(days: 1));
        ref.read(selectedCalendarDateProvider.notifier).state = next;
        ref.read(focusedCalendarMonthProvider.notifier).state =
            DateTime(next.year, next.month, 1);
        break;
    }
  }
}

/// 원형 네비게이션 버튼 (이전/다음)
/// WCAG 2.1 기준 최소 터치 타겟 44x44px 적용
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        child: Center(
          child: Container(
            width: AppLayout.containerMd,
            height: AppLayout.containerMd,
            decoration: BoxDecoration(
              color: context.themeColors.textPrimaryWithAlpha(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: context.themeColors.textPrimaryWithAlpha(0.70),
              size: AppLayout.iconXl,
            ),
          ),
        ),
      ),
    );
  }
}
