// F6: 타이머 세션 정보 위젯
// 현재 세션 유형(집중/짧은 휴식/긴 휴식)과 진행 회차를 표시한다.
// GlassCard(variant: subtle)을 사용한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../services/timer_engine.dart';
import '../../models/timer_log.dart';
import '../../models/timer_state.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 현재 세션 정보 표시 위젯
/// 세션 유형 아이콘 + "집중 1/4" 형태의 텍스트를 표시한다
class TimerSessionInfo extends StatelessWidget {
  /// 현재 타이머 상태
  final TimerState timerState;

  const TimerSessionInfo({
    required this.timerState,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sessionLabel = _buildSessionLabel();
    final sessionIcon = _buildSessionIcon();
    // 세션 색상은 context를 통해 현재 테마를 인식해 결정한다
    final sessionColor = _buildSessionColor(context);

    return GlassCard(
      variant: GlassCardVariant.subtle,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.mdLg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 세션 유형 아이콘
          Icon(
            sessionIcon,
            color: sessionColor,
            size: AppLayout.iconLg,
          ),
          const SizedBox(width: AppSpacing.md),

          // 세션 유형 레이블
          Text(
            sessionLabel,
            style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          // 구분선
          Container(
            width: 1,
            height: 14,
            color: context.themeColors.textPrimaryWithAlpha(0.25),
          ),

          const SizedBox(width: AppSpacing.lg),

          // 세션 회차 표시 (집중 세션인 경우에만 표시)
          if (timerState.sessionType == TimerSessionType.focus) ...[
            Text(
              _buildSessionCount(),
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.70),
              ),
            ),
          ] else ...[
            // 휴식 세션 시 남은 포모도로 수 표시
            Text(
              _buildBreakLabel(),
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.70),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 세션 유형별 레이블 반환
  String _buildSessionLabel() {
    switch (timerState.sessionType) {
      case TimerSessionType.focus:
        return '집중';
      case TimerSessionType.shortBreak:
        return '짧은 휴식';
      case TimerSessionType.longBreak:
        return '긴 휴식';
    }
  }

  /// 세션 유형별 아이콘 반환
  IconData _buildSessionIcon() {
    switch (timerState.sessionType) {
      case TimerSessionType.focus:
        return Icons.psychology_rounded;
      case TimerSessionType.shortBreak:
        return Icons.coffee_rounded;
      case TimerSessionType.longBreak:
        return Icons.self_improvement_rounded;
    }
  }

  /// 세션 유형별 색상 반환
  /// 집중 세션은 배경 테마에 맞는 악센트 색상을 사용해 가독성을 확보한다
  Color _buildSessionColor(BuildContext context) {
    switch (timerState.sessionType) {
      case TimerSessionType.focus:
        // 어두운 배경에서는 mainLight, 밝은 배경에서는 main을 사용한다
        return context.themeColors.accent;
      case TimerSessionType.shortBreak:
        return ColorTokens.success;
      case TimerSessionType.longBreak:
        return ColorTokens.info;
    }
  }

  /// 집중 세션 회차 문자열 반환 ("1/4" 형식)
  String _buildSessionCount() {
    // 현재 회차: completedSessions % sessionsBeforeLongBreak + 1
    final cyclePosition =
        timerState.completedSessions % TimerEngine.sessionsBeforeLongBreak + 1;
    return '$cyclePosition/${TimerEngine.sessionsBeforeLongBreak}';
  }

  /// 휴식 세션 안내 문자열 반환
  String _buildBreakLabel() {
    return '${timerState.completedSessions}회 완료';
  }
}
