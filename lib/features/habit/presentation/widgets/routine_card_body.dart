// F4 위젯: RoutineCardBody - 루틴 카드 본체
// 색상 인디케이터 바 + 루틴 정보(이름, 요일 배지, 시간) + 활성 토글 스위치를 렌더링한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/routine.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import 'routine_card_days_badge.dart';

/// 루틴 카드 본체 위젯
/// 색상 바, 루틴 이름/요일/시간, 활성 토글을 포함한다.
class RoutineCardBody extends StatelessWidget {
  final Routine routine;
  final Color color;
  final String daysLabel;
  final String timeLabel;
  final ValueChanged<bool>? onToggleActive;

  const RoutineCardBody({
    required this.routine,
    required this.color,
    required this.daysLabel,
    required this.timeLabel,
    this.onToggleActive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.mdLg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lgXl,
      ),
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
            width: AppLayout.colorBarWidth,
            height: AppLayout.minTouchTarget,
            decoration: BoxDecoration(
              color: routine.isActive ? color : color.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // 루틴 정보 (이름 + 요일 배지 + 시간)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 비활성 루틴은 빨간펜 취소선 애니메이션으로 상태를 표시한다
                AnimatedStrikethrough(
                  text: routine.name,
                  style: AppTypography.bodyMd.copyWith(
                    // WCAG: 비활성 루틴명 알파 0.50 이상으로 가독성 보장
                    color: routine.isActive
                        ? context.themeColors.textPrimary
                        : context.themeColors.textPrimaryWithAlpha(0.50),
                  ),
                  isActive: !routine.isActive,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    // 요일 배지: 좁은 화면에서 축소 가능하도록 Flexible 사용
                    Flexible(
                      child: RoutineCardDaysBadge(
                        label: daysLabel,
                        color: color,
                        isActive: routine.isActive,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // WCAG: 테마 인식 고대비 보정으로 어두운 배경에서도 가독성 보장
                    Icon(Icons.access_time_rounded,
                        size: AppLayout.iconXxs,
                        color: context.themeColors.textPrimaryWithAlpha(
                            routine.isActive ? 0.55 : 0.45)),
                    const SizedBox(width: AppSpacing.xxs),
                    // 좁은 화면에서 시간 텍스트 오버플로우 방지
                    Flexible(
                      child: Text(
                        timeLabel,
                        // WCAG: 테마 인식 고대비 보정으로 어두운 배경에서도 가독성 보장
                        style: AppTypography.captionMd.copyWith(
                          color: context.themeColors.textPrimaryWithAlpha(
                              routine.isActive ? 0.55 : 0.45),
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
            scale: MiscLayout.switchScaleSmall,
            child: Switch(
              value: routine.isActive,
              onChanged: onToggleActive,
              // activeColor deprecated → activeThumbColor 사용
              activeThumbColor: color,
              activeTrackColor: color.withValues(alpha: 0.35),
              inactiveThumbColor:
                  context.themeColors.textPrimaryWithAlpha(0.4),
              inactiveTrackColor:
                  context.themeColors.textPrimaryWithAlpha(0.12),
            ),
          ),
        ],
      ),
    );
  }
}
