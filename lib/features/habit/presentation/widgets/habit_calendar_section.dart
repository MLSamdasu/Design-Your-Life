// F4 위젯: HabitCalendarSection - 습관 캘린더 섹션
// 월간 달력 + 선택 날짜 습관 상세 패널을 표시한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/models/habit_log.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../providers/habit_provider.dart';
import 'habit_calendar.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';

/// 섹션 2: 습관 캘린더 + 선택일 상세
class HabitCalendarSection extends ConsumerWidget {
  const HabitCalendarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(habitSelectedDateProvider);
    final habits = ref.watch(activeHabitsProvider);
    final logs = ref.watch(habitLogsForDateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text(
            '습관 캘린더',
            style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
          ),
        ),
        GlassmorphicCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: const HabitCalendar(),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassmorphicCard(
          variant: GlassVariant.subtle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selectedDate.month}월 ${selectedDate.day}일 습관',
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // 동기 Provider이므로 null 체크 불필요 — 즉시 데이터를 사용한다
              () {
                // P3: 선택된 날짜에 예정된 습관만 표시한다 (빈도 기반 필터링)
                final scheduled = habits.where((h) => h.isScheduledFor(selectedDate)).toList();
                if (scheduled.isEmpty) {
                  return Text(
                    habits.isEmpty ? '등록된 습관이 없어요' : '이 날짜에 예정된 습관이 없어요',
                    style: AppTypography.captionMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.5),
                    ),
                  );
                }
                return Column(
                  children: scheduled.map((h) {
                    final log = logs.firstWhere(
                      (l) => l.habitId == h.id,
                      orElse: () => HabitLog(
                        id: '',
                        habitId: h.id,
                        date: selectedDate,
                        isCompleted: false,
                        checkedAt: selectedDate,
                      ),
                    );
                    return HabitDetailRow(
                      habit: h,
                      isCompleted: log.isCompleted,
                    );
                  }).toList(),
                );
              }(),
            ],
          ),
        ),
      ],
    );
  }
}

/// 습관 상세 행 (캘린더 선택일 표시)
class HabitDetailRow extends StatelessWidget {
  final Habit habit;
  final bool isCompleted;

  const HabitDetailRow({
    required this.habit,
    required this.isCompleted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: AppLayout.iconMd,
            // 완료: habitCheck 토큰 사용 (초록)
            color: isCompleted
                ? ColorTokens.habitCheck
                : context.themeColors.textPrimaryWithAlpha(0.35),
          ),
          const SizedBox(width: AppSpacing.md),
          if (habit.icon != null) ...[
            // emojiSm 토큰 사용 (14px 이모지 전용)
            Text(habit.icon!, style: AppTypography.emojiSm),
            const SizedBox(width: AppSpacing.sm),
          ],
          // 긴 습관명이 Row를 넘지 않도록 Expanded로 감싼다
          // 완료 시 빨간펜 취소선 애니메이션으로 시각적 일관성 유지
          Expanded(
            child: AnimatedStrikethrough(
              text: habit.name,
              style: AppTypography.bodySm.copyWith(
                color: isCompleted
                    ? context.themeColors.textPrimaryWithAlpha(0.55)
                    : context.themeColors.textPrimaryWithAlpha(0.8),
              ),
              isActive: isCompleted,
            ),
          ),
        ],
      ),
    );
  }
}
