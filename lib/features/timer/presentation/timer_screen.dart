// F6: 포모도로 타이머 메인 화면
// StatefulShellRoute 6번째 탭으로 메인 네비게이션에 포함된다.
// SegmentedControl로 '타이머'/'통계' 서브탭을 전환한다.
// 투두 연결은 timerStateProvider.linkTodo()로 사전 설정 후 탭 전환한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../shared/widgets/segmented_control.dart';
import '../../../shared/widgets/global_action_bar.dart';
import '../models/timer_log.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';
import '../providers/timer_stats_provider.dart';
import 'widgets/timer_controls.dart';
import 'widgets/timer_display.dart';
import 'widgets/timer_log_list.dart';
import 'widgets/timer_session_info.dart';
import 'widgets/timer_stats_view.dart';
import 'widgets/timer_settings_sheet.dart';
import 'widgets/timer_todo_selector.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../shared/widgets/bottom_scroll_spacer.dart';

/// 서브탭 레이블 목록 (타이머 / 통계)
const _subTabLabels = ['타이머', '통계'];

/// 포모도로 타이머 메인 화면
/// SegmentedControl로 타이머/통계 서브탭을 전환한다
class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerStateProvider);
    final subTab = ref.watch(timerSubTabProvider);
    final sessionsBeforeLong = ref.watch(timerSessionsBeforeLongBreakProvider);

    return Scaffold(
      // 배경을 투명으로 설정하여 앱 그라디언트 배경이 보이게 한다
      backgroundColor: ColorTokens.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더: 제목 + 집중 시간 뱃지 + 업적/설정 아이콘
            _TimerHeader(timerState: timerState),
            const SizedBox(height: AppSpacing.lg),
            // 서브탭 스위처 (타이머 / 통계)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.md,
              ),
              child: SegmentedControl<int>(
                values: const [0, 1],
                selected: subTab,
                labelBuilder: (i) => _subTabLabels[i],
                onChanged: (i) =>
                    ref.read(timerSubTabProvider.notifier).state = i,
              ),
            ),
            // 서브탭 콘텐츠
            Expanded(
              child: subTab == 0
                  ? _TimerContent(
                      timerState: timerState,
                      sessionsBeforeLongBreak: sessionsBeforeLong,
                    )
                  : const TimerStatsView(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 타이머 화면 상단 헤더
/// 다른 탭 화면(습관, 목표 등)과 동일한 레이아웃 패턴:
/// 좌측 제목 + 우측 GlobalActionBar
class _TimerHeader extends ConsumerWidget {
  final TimerState timerState;
  const _TimerHeader({required this.timerState});

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
    // P1-14: 이전 이름에서 변경 — selectedDate 기준으로 필터링한다
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

/// 타이머 서브탭 콘텐츠 (기존 타이머 UI)
class _TimerContent extends StatelessWidget {
  final TimerState timerState;

  /// 사용자가 설정한 긴 휴식 전 세션 횟수
  final int sessionsBeforeLongBreak;

  const _TimerContent({
    required this.timerState,
    required this.sessionsBeforeLongBreak,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          // 세션 정보 (집중/휴식 유형 + 회차)
          Center(
            child: TimerSessionInfo(
              timerState: timerState,
              sessionsBeforeLongBreak: sessionsBeforeLongBreak,
            ),
          ),
          const SizedBox(height: AppSpacing.huge),
          // 원형 타이머 디스플레이
          Center(child: TimerDisplay(timerState: timerState)),
          const SizedBox(height: AppSpacing.huge),
          // 세션 완료 축하 메시지
          if (timerState.phase == TimerPhase.completed) ...[
            _CompletedBanner(timerState: timerState),
            const SizedBox(height: AppSpacing.xxl),
          ],
          // 타이머 컨트롤 버튼
          TimerControls(
            onSelectTodo: () => TimerTodoSelector.show(context),
          ),
          const SizedBox(height: AppSpacing.huge),
          // 오늘의 타이머 기록 목록
          const TimerLogList(),
          const BottomScrollSpacer(),
        ],
      ),
    );
  }
}

/// 세션 완료 축하 배너
class _CompletedBanner extends StatelessWidget {
  final TimerState timerState;
  const _CompletedBanner({required this.timerState});

  @override
  Widget build(BuildContext context) {
    final isFocus = timerState.sessionType == TimerSessionType.focus;
    final message =
        isFocus ? '집중 완료! 수고했어요 🎉' : '휴식 완료! 다시 시작할까요?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isFocus
            ? context.themeColors.accentWithAlpha(0.20)
            : ColorTokens.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isFocus
              ? context.themeColors.accentWithAlpha(0.30)
              : ColorTokens.success.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.bodyMd.copyWith(
          color: context.themeColors.textPrimary,
          fontWeight: AppTypography.weightSemiBold,
        ),
      ),
    );
  }
}
