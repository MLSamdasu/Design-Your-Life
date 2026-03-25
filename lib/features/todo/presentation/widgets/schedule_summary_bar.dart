// 일정 요약 바 위젯
// 오늘의 일정/루틴/타이머 세션 수를 요약하는 작은 정보 바
// 투두 목록 상단에 표시하여 캘린더/루틴/타이머 데이터와의 연결감을 제공한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../providers/todo_provider.dart';

/// 오늘의 일정/루틴/타이머 세션 수를 요약하는 작은 정보 바
/// 루틴 칩 탭 시 주간 루틴 서브탭으로 전환한다
class ScheduleSummaryBar extends ConsumerWidget {
  final int eventCount;
  final int routineCount;
  final int timerCount;

  const ScheduleSummaryBar({
    super.key,
    required this.eventCount,
    required this.routineCount,
    required this.timerCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.06),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 이벤트 수 — Flexible로 감싸 좁은 화면에서 오버플로를 방지한다
            if (eventCount > 0) ...[
              Flexible(
                child: _buildInfoChip(
                  context,
                  icon: Icons.event_rounded,
                  label: '일정 $eventCount',
                ),
              ),
              if (routineCount > 0 || timerCount > 0)
                _buildDot(context),
            ],
            // 루틴 수 — 탭 시 주간 루틴 서브탭으로 전환
            if (routineCount > 0) ...[
              Flexible(
                child: GestureDetector(
                  onTap: () => ref.read(todoSubTabProvider.notifier).state =
                      TodoSubTab.weeklyRoutine,
                  child: _buildInfoChip(
                    context,
                    icon: Icons.repeat_rounded,
                    label: '루틴 $routineCount',
                  ),
                ),
              ),
              if (timerCount > 0)
                _buildDot(context),
            ],
            // 타이머 세션 수
            if (timerCount > 0)
              Flexible(
                child: _buildInfoChip(
                  context,
                  icon: Icons.timer_rounded,
                  label: '타이머 $timerCount',
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 아이콘 + 레이블 조합 칩
  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppLayout.iconSm,
          color: context.themeColors.textPrimaryWithAlpha(0.50),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            label,
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// 구분 점
  Widget _buildDot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.30),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
