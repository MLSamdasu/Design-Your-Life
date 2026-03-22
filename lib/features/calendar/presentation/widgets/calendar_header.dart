// F2 위젯: CalendarHeader - 캘린더 상단 헤더
// SRP 분리: calendar_screen.dart에서 헤더 + 월 네비게이션을 추출한다
// F17: Google Calendar 연동 활성화 시 수동 동기화 버튼을 헤더 우측에 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/calendar_sync/calendar_sync_provider.dart';
import '../../../../core/calendar_sync/google_calendar_service.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/view_type.dart';
import '../../providers/calendar_provider.dart';
import 'calendar_view_switcher.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/global_action_bar.dart';

/// 캘린더 화면 상단 헤더 (월/연도 네비게이션 + 뷰 전환 탭)
class CalendarHeader extends ConsumerWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(calendarViewTypeProvider);
    final focusedMonth = ref.watch(focusedCalendarMonthProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);

    return Container(
      // 다른 화면 헤더(투두, 습관)와 동일한 상단 패딩(16px)을 적용한다
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageVertical, AppSpacing.pageHorizontal, 0),
      child: Column(
        children: [
          // 월/연도 네비게이션 행
          Row(
            children: [
              Expanded(
                child: _MonthNavigation(
                  currentView: currentView,
                  focusedMonth: focusedMonth,
                  selectedDate: selectedDate,
                ),
              ),
              // F17: Google Calendar 연동 활성화 시 수동 동기화 버튼 표시
              _GoogleSyncButton(),
              // 오늘 버튼
              _TodayButton(),
              const SizedBox(width: AppSpacing.xs),
              // 업적 + 설정 아이콘 버튼
              const GlobalActionBar(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const CalendarViewSwitcher(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Google Calendar 수동 동기화 버튼 (F17)
/// googleCalendarSyncEnabledProvider가 true일 때만 표시된다
class _GoogleSyncButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncEnabled = ref.watch(googleCalendarSyncEnabledProvider);
    // 연동이 비활성화된 경우 버튼을 표시하지 않는다
    if (!syncEnabled) return const SizedBox.shrink();

    final syncStatus = ref.watch(calendarSyncStatusProvider);
    final isSyncing = syncStatus == CalendarSyncStatus.syncing;

    return GestureDetector(
      onTap: isSyncing
          ? null // 동기화 중에는 버튼 비활성화
          : () => ref.read(syncGoogleCalendarProvider)(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        child: Center(
          child: isSyncing
              // 동기화 중: 회전 애니메이션 대신 단순 아이콘 표시 (AnimatedRotation 불필요)
              // WCAG 최소 대비: 동기화 중 아이콘도 0.55 이상 보장
              ? Icon(
                  Icons.sync_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.55),
                  size: AppLayout.iconXl,
                )
              : Icon(
                  Icons.sync_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.70),
                  size: AppLayout.iconXl,
                ),
        ),
      ),
    );
  }
}

/// 오늘 버튼
class _TodayButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final today = DateTime.now();
        ref.read(selectedCalendarDateProvider.notifier).state =
            DateTime(today.year, today.month, today.day);
        ref.read(focusedCalendarMonthProvider.notifier).state =
            DateTime(today.year, today.month, 1);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.15),
          borderRadius: BorderRadius.circular(AppRadius.huge),
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.25),
            width: AppLayout.borderThin,
          ),
        ),
        child: Text(
          '오늘',
          style: AppTypography.captionLg.copyWith(color: context.themeColors.textPrimary),
        ),
      ),
    );
  }
}

/// 월/연도 네비게이션 (이전/다음 이동 + 현재 기간 텍스트)
class _MonthNavigation extends ConsumerWidget {
  final ViewType currentView;
  final DateTime focusedMonth;
  final DateTime selectedDate;

  const _MonthNavigation({
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
