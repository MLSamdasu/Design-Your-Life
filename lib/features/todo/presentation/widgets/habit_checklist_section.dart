// 습관 체크리스트 섹션 위젯
// 투두 목록 상단에 오늘의 습관을 체크리스트 형태로 표시한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../habit/providers/habit_provider.dart';

/// 습관 체크리스트 섹션
/// 투두 목록 상단에 오늘의 습관을 체크리스트 형태로 표시한다
class HabitChecklistSection extends ConsumerWidget {
  final List<({Habit habit, bool isCompleted})> habits;
  final DateTime selectedDate;

  const HabitChecklistSection({
    super.key,
    required this.habits,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedCount = habits.where((e) => e.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.06),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 제목 + 완료 카운트
            Row(
              children: [
                Icon(
                  Icons.self_improvement_rounded,
                  size: AppLayout.iconMd,
                  color: context.themeColors.textPrimaryWithAlpha(0.55),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '오늘의 습관',
                  style: AppTypography.captionLg.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.65),
                    fontWeight: AppTypography.weightSemiBold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedCount/${habits.length}',
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.accent,
                    fontWeight: AppTypography.weightSemiBold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // 습관 아이템 목록
            ...habits.map((entry) => _buildHabitItem(
              context, ref, entry.habit, entry.isCompleted,
            )),
          ],
        ),
      ),
    );
  }

  /// 개별 습관 체크 아이템
  Widget _buildHabitItem(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          // 체크박스
          GestureDetector(
            onTap: () {
              ref.read(toggleHabitProvider)(
                habit.id, selectedDate, !isCompleted,
              );
            },
            child: AnimatedContainer(
              duration: AppAnimation.slow,
              curve: Curves.easeInOut,
              width: AppLayout.iconMd,
              height: AppLayout.iconMd,
              decoration: BoxDecoration(
                color: isCompleted
                    ? context.themeColors.accent
                    : ColorTokens.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: isCompleted
                      ? context.themeColors.accent
                      : context.themeColors.textPrimaryWithAlpha(0.3),
                  width: AppLayout.borderMedium,
                ),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      size: AppLayout.iconSm,
                      color: context.themeColors.dialogSurface,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // 습관 아이콘
          if (habit.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Text(habit.icon!, style: AppTypography.bodyMd),
            ),
          // 습관 이름 (완료 시 빨간펜 취소선 애니메이션 적용)
          Expanded(
            child: AnimatedStrikethrough(
              text: habit.name,
              style: AppTypography.bodySm.copyWith(
                color: context.themeColors.textPrimary,
              ),
              isActive: isCompleted,
            ),
          ),
        ],
      ),
    );
  }
}
