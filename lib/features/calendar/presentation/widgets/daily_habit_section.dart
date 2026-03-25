// F2 위젯: DailyHabitSection - 일간 뷰의 오늘의 습관 체크리스트 섹션
// 종일 이벤트와 타임라인 사이에 표시된다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/widgets/animated_checkbox.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../providers/calendar_provider.dart';
import '../../../habit/providers/habit_provider.dart';

/// 습관 체크리스트 데이터 (습관 + 완료 여부)
typedef HabitDayEntry = ({Habit habit, bool isCompleted});

/// 일간 뷰의 오늘의 습관 체크리스트 섹션
/// 종일 이벤트와 타임라인 사이에 표시된다
class DailyHabitSection extends ConsumerWidget {
  /// 오늘의 습관 목록
  final List<HabitDayEntry> habitsForDay;

  const DailyHabitSection({
    super.key,
    required this.habitsForDay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (habitsForDay.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 습관',
            style: AppTypography.captionLg.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...habitsForDay.map((entry) => _buildHabitCheckItem(
                context, ref, entry.habit, entry.isCompleted,
              )),
          Divider(
            color: context.themeColors.textPrimaryWithAlpha(0.12),
            height: 1,
          ),
        ],
      ),
    );
  }

  /// 습관 체크 아이템 위젯 (일간 뷰 종일 영역)
  /// AnimatedCheckbox를 사용하여 스케일 바운스를 적용한다
  Widget _buildHabitCheckItem(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          // 체크박스 (AnimatedCheckbox: 스케일 바운스 + 색상 전환 포함)
          AnimatedCheckbox(
            isCompleted: isCompleted,
            size: AppLayout.iconMd,
            onTap: () {
              final selectedDate = ref.read(selectedCalendarDateProvider);
              ref.read(toggleHabitProvider)(
                  habit.id, selectedDate, !isCompleted);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          // 습관 아이콘
          if (habit.icon != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Text(habit.icon!, style: AppTypography.bodyMd),
            ),
          // 습관 이름 (완료 시 빨간펜 취소선 애니메이션 + 행 전체 투명도 적용)
          Expanded(
            child: AnimatedOpacity(
              opacity: isCompleted ? 0.50 : 1.0,
              duration: AppAnimation.textFade,
              curve: Curves.easeInOut,
              child: AnimatedStrikethrough(
                text: habit.name,
                style: AppTypography.bodySm.copyWith(
                  color: context.themeColors.textPrimary,
                ),
                isActive: isCompleted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
