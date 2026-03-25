// F6-H: 포모도로 타이머 화면 상단 헤더
// 좌측 제목 + 오늘 총 집중 시간 뱃지 + 설정/업적 아이콘을 표시한다.
// 입력: TimerState (현재 타이머 상태)
// 출력: 헤더 Row 위젯
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../shared/widgets/global_action_bar.dart';
import '../models/timer_state.dart';
import '../providers/timer_query_providers.dart';
import 'widgets/timer_settings_sheet.dart';

/// 타이머 화면 상단 헤더
/// 다른 탭 화면(습관, 목표 등)과 동일한 레이아웃 패턴:
/// 좌측 제목 + 우측 GlobalActionBar
class TimerHeader extends ConsumerWidget {
  final TimerState timerState;
  const TimerHeader({super.key, required this.timerState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal, AppSpacing.pageVertical,
        AppSpacing.pageHorizontal, 0,
      ),
      child: Row(
        children: [
          // 화면 제목
          Expanded(
            child: Text(
              '포모도로 타이머',
              style: AppTypography.headingSm.copyWith(
                color: context.themeColors.textPrimary,
              ),
            ),
          ),
          // 오늘 총 집중 시간 뱃지
          _buildFocusMinutesBadge(context, ref),
          const SizedBox(width: AppSpacing.md),
          // P1-5: 타이머 설정 바텀시트 진입 버튼
          GestureDetector(
            onTap: () => TimerSettingsSheet.show(context),
            child: Icon(
              Icons.tune_rounded,
              size: AppLayout.iconMd,
              color: context.themeColors.textPrimaryWithAlpha(0.65),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // 업적 + 설정 아이콘 버튼
          const GlobalActionBar(),
        ],
      ),
    );
  }

  /// 오늘 총 집중 시간 뱃지
  Widget _buildFocusMinutesBadge(BuildContext context, WidgetRef ref) {
    // P1-14: selectedDate 기준으로 필터링한다
    final minutes = ref.watch(selectedDateFocusMinutesProvider);
    if (minutes == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.mdLg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.themeColors.accentWithAlpha(0.25),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: context.themeColors.accentWithAlpha(0.40),
        ),
      ),
      child: Text(
        '$minutes분',
        style: AppTypography.captionLg.copyWith(
          color: context.themeColors.accent,
        ),
      ),
    );
  }
}
