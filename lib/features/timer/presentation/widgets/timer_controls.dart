// F6: 타이머 컨트롤 버튼 위젯
// TimerPhase에 따라 다른 버튼 조합을 표시한다.
// GlassButton(shared/widgets)을 재사용하여 디자인 일관성을 유지한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/glass_button.dart';
import '../../models/timer_state.dart';
import '../../providers/timer_provider.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 타이머 컨트롤 버튼 위젯
/// TimerPhase: idle/running/paused/completed 별로 다른 버튼을 표시한다
class TimerControls extends ConsumerWidget {
  /// 투두 선택 바텀시트 표시 콜백 (투두 연결 버튼 탭 시)
  final VoidCallback? onSelectTodo;

  const TimerControls({
    this.onSelectTodo,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerStateProvider);
    final notifier = ref.read(timerStateProvider.notifier);

    return _buildButtons(timerState, notifier);
  }

  /// Phase에 따른 버튼 조합을 반환한다
  Widget _buildButtons(TimerState state, TimerStateNotifier notifier) {
    switch (state.phase) {
      case TimerPhase.idle:
        // 대기 상태: 시작 버튼만 표시
        return Column(
          children: [
            GlassButton(
              label: '시작',
              leadingIcon: Icons.play_arrow_rounded,
              variant: GlassButtonVariant.primary,
              fullWidth: true,
              onTap: () => notifier.start(
                todoId: state.linkedTodoId,
                todoTitle: state.linkedTodoTitle,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 투두 연결 버튼
            GlassButton(
              label: state.linkedTodoTitle != null
                  ? '연결된 투두: ${state.linkedTodoTitle}'
                  : '투두 연결하기',
              leadingIcon: Icons.link_rounded,
              variant: GlassButtonVariant.secondary,
              fullWidth: true,
              onTap: onSelectTodo,
            ),
          ],
        );

      case TimerPhase.running:
        // 실행 중: 일시정지 + 정지(로그 저장) + 리셋 — compact 모드로 오버플로우 방지
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: GlassButton(
                label: '일시정지',
                leadingIcon: Icons.pause_rounded,
                variant: GlassButtonVariant.primary,
                fullWidth: true,
                compact: true,
                onTap: notifier.pause,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: GlassButton(
                label: '정지',
                leadingIcon: Icons.stop_rounded,
                variant: GlassButtonVariant.secondary,
                fullWidth: true,
                compact: true,
                onTap: notifier.stop,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: GlassButton(
                label: '리셋',
                leadingIcon: Icons.refresh_rounded,
                variant: GlassButtonVariant.secondary,
                fullWidth: true,
                compact: true,
                onTap: notifier.reset,
              ),
            ),
          ],
        );

      case TimerPhase.paused:
        // 일시정지 상태: 재개 + 정지(로그 저장) + 리셋 — compact 모드로 오버플로우 방지
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: GlassButton(
                label: '재개',
                leadingIcon: Icons.play_arrow_rounded,
                variant: GlassButtonVariant.primary,
                fullWidth: true,
                compact: true,
                onTap: notifier.resume,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: GlassButton(
                label: '정지',
                leadingIcon: Icons.stop_rounded,
                variant: GlassButtonVariant.secondary,
                fullWidth: true,
                compact: true,
                onTap: notifier.stop,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: GlassButton(
                label: '리셋',
                leadingIcon: Icons.refresh_rounded,
                variant: GlassButtonVariant.secondary,
                fullWidth: true,
                compact: true,
                onTap: notifier.reset,
              ),
            ),
          ],
        );

      case TimerPhase.completed:
        // 완료 상태: 다음 세션 + 리셋 버튼
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: GlassButton(
                label: '다음 세션',
                leadingIcon: Icons.skip_next_rounded,
                variant: GlassButtonVariant.primary,
                fullWidth: true,
                onTap: notifier.nextSession,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: GlassButton(
                label: '리셋',
                leadingIcon: Icons.refresh_rounded,
                variant: GlassButtonVariant.secondary,
                fullWidth: true,
                onTap: notifier.reset,
              ),
            ),
          ],
        );
    }
  }
}
