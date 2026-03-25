// F6-C: 포모도로 타이머 서브탭 콘텐츠
// 타이머 디스플레이, 세션 정보, 컨트롤 버튼, 완료 배너, 기록 목록을 포함한다.
// 오른쪽에 인라인 설정 위젯(집중 시간/세션 횟수 조절)을 배치한다.
// 입력: TimerState, sessionsBeforeLongBreak
// 출력: 타이머 콘텐츠 스크롤 영역 위젯
import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../shared/widgets/bottom_scroll_spacer.dart';
import '../models/timer_log.dart';
import '../models/timer_state.dart';
import 'widgets/timer_controls.dart';
import 'widgets/timer_display.dart';
import 'widgets/timer_inline_settings.dart';
import 'widgets/timer_log_list.dart';
import 'widgets/timer_session_info.dart';
import 'widgets/timer_todo_selector.dart';

/// 타이머 서브탭 콘텐츠 (기존 타이머 UI)
class TimerContent extends StatelessWidget {
  final TimerState timerState;

  /// 사용자가 설정한 긴 휴식 전 세션 횟수
  final int sessionsBeforeLongBreak;

  const TimerContent({
    super.key,
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
          // 세션 정보 + 타이머 디스플레이 + 우측 인라인 설정
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 타이머 영역 (세션 정보 + 원형 디스플레이) — 중앙 정렬
              Expanded(
                child: Column(
                  children: [
                    TimerSessionInfo(
                      timerState: timerState,
                      sessionsBeforeLongBreak: sessionsBeforeLongBreak,
                    ),
                    const SizedBox(height: AppSpacing.huge),
                    TimerDisplay(timerState: timerState),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // 우측 인라인 설정 위젯 (고정 폭)
              const TimerInlineSettings(),
            ],
          ),
          const SizedBox(height: AppSpacing.huge),
          // 세션 완료 축하 메시지
          if (timerState.phase == TimerPhase.completed) ...[
            CompletedBanner(timerState: timerState),
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
class CompletedBanner extends StatelessWidget {
  final TimerState timerState;
  const CompletedBanner({super.key, required this.timerState});

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
