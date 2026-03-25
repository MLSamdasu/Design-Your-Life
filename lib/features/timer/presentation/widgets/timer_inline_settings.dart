// F6: 타이머 인라인 설정 위젯
// 타이머 화면 오른쪽에 표시되는 컴팩트한 설정 컨트롤이다.
// 집중 시간(분)과 세션 횟수를 +/- 버튼으로 조절할 수 있다.
// idle 상태에서만 조작 가능하며, 변경 시 Hive에 즉시 저장된다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../models/timer_state.dart';
import '../../providers/timer_provider.dart';
import 'timer_settings_persistence.dart';

/// 타이머 화면 우측에 표시되는 컴팩트 설정 위젯
/// 집중 시간과 세션 횟수를 간편하게 조절할 수 있다
class TimerInlineSettings extends ConsumerWidget {
  const TimerInlineSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.themeColors;
    final phase = ref.watch(timerStateProvider).phase;
    final isIdle = phase == TimerPhase.idle;
    final focusMin = ref.watch(timerFocusMinutesProvider);
    final sessions = ref.watch(timerSessionsBeforeLongBreakProvider);

    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.overlayLight,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 집중 시간 컨트롤
          _CompactStepper(
            label: '${focusMin}m',
            icon: Icons.timer_outlined,
            enabled: isIdle,
            onIncrement: () => _changeFocus(ref, focusMin, 5),
            onDecrement: () => _changeFocus(ref, focusMin, -5),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 구분선
          Container(
            width: 24,
            height: 1,
            color: colors.borderLight,
          ),
          const SizedBox(height: AppSpacing.lg),
          // 세션 횟수 컨트롤
          _CompactStepper(
            label: '$sessions회',
            icon: Icons.repeat_rounded,
            enabled: isIdle,
            onIncrement: () => _changeSessions(ref, sessions, 1),
            onDecrement: () => _changeSessions(ref, sessions, -1),
          ),
        ],
      ),
    );
  }

  /// 집중 시간을 5분 단위로 변경한다 (5~60분 범위)
  void _changeFocus(WidgetRef ref, int current, int delta) {
    final next = (current + delta).clamp(5, 60);
    if (next != current) saveFocusMinutes(ref, next);
  }

  /// 세션 횟수를 1단위로 변경한다 (2~8회 범위)
  void _changeSessions(WidgetRef ref, int current, int delta) {
    final next = (current + delta).clamp(2, 8);
    if (next != current) saveSessionsBeforeLong(ref, next);
  }
}

/// 컴팩트 수직 스테퍼 (아이콘 + 값 + 위/아래 화살표)
class _CompactStepper extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CompactStepper({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final disabledAlpha = 0.35;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 증가 버튼
        _StepperButton(
          icon: Icons.keyboard_arrow_up_rounded,
          onTap: enabled ? onIncrement : null,
          disabledAlpha: disabledAlpha,
        ),
        const SizedBox(height: AppSpacing.xs),
        // 아이콘
        Icon(
          icon,
          size: 14,
          color: colors.accent.withValues(
            alpha: enabled ? 1.0 : disabledAlpha,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        // 현재 값
        Text(
          label,
          style: AppTypography.captionMd.copyWith(
            color: colors.textPrimary.withValues(
              alpha: enabled ? 1.0 : disabledAlpha,
            ),
            fontWeight: AppTypography.weightSemiBold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // 감소 버튼
        _StepperButton(
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: enabled ? onDecrement : null,
          disabledAlpha: disabledAlpha,
        ),
      ],
    );
  }
}

/// 스테퍼 +/- 버튼
class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double disabledAlpha;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.disabledAlpha,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.themeColors;
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isEnabled
              ? colors.overlayLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          size: 18,
          color: colors.textPrimary.withValues(
            alpha: isEnabled ? 0.7 : disabledAlpha,
          ),
        ),
      ),
    );
  }
}
