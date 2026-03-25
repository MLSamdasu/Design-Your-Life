// F2 위젯: 캘린더 헤더 액션 버튼 (Google 동기화 + 오늘 버튼)
// SRP 분리: calendar_header.dart에서 액션 버튼들을 추출한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/calendar_sync_provider.dart';
import '../../sync/google_calendar_service.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../providers/calendar_provider.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// Google Calendar 수동 동기화 버튼 (F17)
/// googleCalendarSyncEnabledProvider가 true일 때만 표시된다
class GoogleSyncButton extends ConsumerWidget {
  const GoogleSyncButton({super.key});

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

/// 오늘 버튼 — 현재 날짜로 즉시 이동하는 버튼
class TodayButton extends ConsumerWidget {
  const TodayButton({super.key});

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
        // 좁은 화면 오버플로 방지를 위해 패딩을 축소한다
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
