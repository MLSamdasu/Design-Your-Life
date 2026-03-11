// F4 위젯: RoutineCard - 루틴 카드
// 루틴명 + 반복 요일 배지 + 시간 + 색상 인디케이터 + 활성/비활성 토글을 표시한다.
// Dismissible로 스와이프 삭제를 지원한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/routine.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 루틴 카드 위젯
class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleActive;

  const RoutineCard({
    required this.routine,
    this.onDelete,
    this.onToggleActive,
    super.key,
  });

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDays(List<int> days) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final sorted = List<int>.from(days)..sort();
    return sorted.map((d) => labels[(d - 1).clamp(0, 6)]).join('');
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(routine.colorIndex);
    return Dismissible(
      key: Key('routine_${routine.id}'),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.mdLg),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lgXl),
        decoration: BoxDecoration(
          color: routine.isActive
              ? context.themeColors.textPrimaryWithAlpha(0.12)
              : context.themeColors.textPrimaryWithAlpha(0.06),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: routine.isActive
                ? color.withValues(alpha: 0.35)
                : context.themeColors.textPrimaryWithAlpha(0.10),
          ),
        ),
        child: Row(
          children: [
            // 색상 인디케이터 바
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: routine.isActive ? color : color.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // 루틴 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.name,
                    style: AppTypography.bodyMd.copyWith(
                      color: routine.isActive
                          ? context.themeColors.textPrimary
                          : context.themeColors.textPrimaryWithAlpha(0.45),
                      decoration:
                          routine.isActive ? null : TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      // 요일 배지는 축소 불가하게 유지한다
                      Flexible(
                        flex: 0,
                        child: _DaysBadge(
                          label: _fmtDays(routine.repeatDays),
                          color: color,
                          isActive: routine.isActive,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(Icons.access_time_rounded,
                          size: 11,
                          color: context.themeColors.textPrimary.withValues(
                              alpha: routine.isActive ? 0.55 : 0.25)),
                      const SizedBox(width: 3),
                      // 좁은 화면에서 시간 텍스트 오버플로우 방지
                      Flexible(
                        child: Text(
                          '${_fmtTime(routine.startTime)} ~ ${_fmtTime(routine.endTime)}',
                          style: AppTypography.captionMd.copyWith(
                            color: context.themeColors.textPrimary.withValues(
                                alpha: routine.isActive ? 0.55 : 0.25),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 활성 토글 스위치
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: routine.isActive,
                onChanged: onToggleActive,
                // activeColor deprecated → activeThumbColor 사용
                activeThumbColor: color,
                activeTrackColor: color.withValues(alpha: 0.35),
                inactiveThumbColor: context.themeColors.textPrimaryWithAlpha(0.4),
                inactiveTrackColor: context.themeColors.textPrimaryWithAlpha(0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 삭제 스와이프 배경
class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: ColorTokens.error.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Icon(Icons.delete_rounded, color: context.themeColors.textPrimary, size: 22),
    );
  }
}

/// 요일 배지 위젯
class _DaysBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;

  const _DaysBadge({
    required this.label,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.2)
            : context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.huge),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.4)
              : context.themeColors.textPrimaryWithAlpha(0.12),
        ),
      ),
      child: Text(
        label.isEmpty ? '없음' : label,
        style: AppTypography.captionMd.copyWith(
          color: isActive ? color : context.themeColors.textPrimaryWithAlpha(0.35),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
