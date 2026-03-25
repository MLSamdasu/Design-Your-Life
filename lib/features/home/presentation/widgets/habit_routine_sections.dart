// F1: 습관/루틴 통합 카드의 섹션 서브위젯
// HabitRoutineSummaryCard 내부에서 습관 필 목록과 루틴 목록을 각각 담당한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/habit_pill.dart';
import '../../../habit/providers/habit_provider.dart';
import '../../providers/home_provider.dart';
import 'routine_item_row.dart';

/// 습관 필 목록 섹션 (소제목 + HabitPill 리스트)
class HabitPillListSection extends StatelessWidget {
  final HabitSummary habitSummary;
  final WidgetRef ref;

  const HabitPillListSection({
    super.key,
    required this.habitSummary,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 습관 섹션 소제목
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            '습관',
            style: AppTypography.captionLg.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
              fontWeight: AppTypography.weightSemiBold,
            ),
          ),
        ),

        // 습관 필 목록
        ...habitSummary.previewItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
            child: HabitPill(
              icon: item.icon,
              name: item.name,
              isCompleted: item.isCompleted,
              streak: item.streak,
              // 홈 미리보기에서도 습관 토글을 지원한다
              onToggle: () => ref.read(toggleHabitProvider)(
                item.id,
                DateTime.now(),
                !item.isCompleted,
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// 홈 화면용 루틴 섹션 (소제목 + RoutineItemRow 리스트)
/// 습관 탭의 RoutineListSection과 이름 충돌 방지를 위해 별도 접두어 사용
class HomeRoutineListSection extends StatelessWidget {
  final RoutineSummary routineSummary;

  const HomeRoutineListSection({
    super.key,
    required this.routineSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 루틴 섹션 소제목
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            '루틴',
            style: AppTypography.captionLg.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.55),
              fontWeight: AppTypography.weightSemiBold,
            ),
          ),
        ),

        // 루틴 아이템 (시간순, 완료 토글 지원)
        ...routineSummary.routineItems.map((item) {
          return RoutineItemRow(
            item: item,
            date: DateTime.now(),
          );
        }),
      ],
    );
  }
}
