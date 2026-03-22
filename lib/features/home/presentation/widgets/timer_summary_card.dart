// F1: 홈 대시보드 오늘의 집중 시간 요약 카드
// todayOnlyFocusMinutesProvider에서 항상 오늘 날짜 기준 총 집중 시간을 표시한다.
// 탭 시 타이머 화면으로 이동한다.
// GlassCard(defaultCard variant) 사용.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../timer/models/timer_log.dart';
import '../../../timer/providers/timer_provider.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 홈 대시보드 - 오늘의 집중 시간 요약 카드
/// 타이머 화면 진입점 역할을 한다
class TimerSummaryCard extends ConsumerWidget {
  const TimerSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 홈 대시보드 전용: 항상 오늘 날짜 기준으로 타이머 데이터를 표시한다
    // 동기 Provider이므로 직접 사용한다
    final logs = ref.watch(todayOnlyTimerLogsProvider);
    final focusMinutes = ref.watch(todayOnlyFocusMinutesProvider);

    // focus 타입의 세션 수를 계산한다
    final sessionCount = logs
        .where((log) => log.type == TimerSessionType.focus)
        .length;

    return GestureDetector(
      // 카드 탭 시 타이머 탭으로 전환한다
      onTap: () => context.go(RoutePaths.timer),
      child: GlassCard(
        variant: GlassCardVariant.defaultCard,
        child: _buildContent(context, focusMinutes, sessionCount),
      ),
    );
  }

  /// 실제 콘텐츠 UI
  Widget _buildContent(BuildContext context, int focusMinutes, int sessionCount) {
    final hours = focusMinutes ~/ 60;
    final minutes = focusMinutes % 60;
    final timeLabel = hours > 0 ? '$hours시간 $minutes분' : '$minutes분';

    return Row(
      children: [
        // 타이머 아이콘 컨테이너
        Container(
          width: AppLayout.iconEmpty,
          height: AppLayout.iconEmpty,
          // 타이머 아이콘 배경: 배경 테마에 맞는 악센트 색상으로 표시한다
          decoration: BoxDecoration(
            color: context.themeColors.accentWithAlpha(0.20),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: context.themeColors.accentWithAlpha(0.30),
            ),
          ),
          child: Icon(
            Icons.timer_rounded,
            // WCAG 대비: accent 배경 위에서 테마 색상으로 고대비 확보
            color: context.themeColors.textPrimaryWithAlpha(0.8),
            size: AppLayout.iconXxl,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),

        // 집중 시간 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 집중 시간',
                style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                focusMinutes == 0
                    ? '아직 집중 기록이 없어요'
                    : '$timeLabel · $sessionCount세션 완료',
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.70),
                ),
              ),
            ],
          ),
        ),

        // 타이머 시작 화살표 아이콘
        Icon(
          Icons.chevron_right_rounded,
          color: context.themeColors.textPrimaryWithAlpha(0.40),
          size: AppLayout.iconXl,
        ),
      ],
    );
  }
}
