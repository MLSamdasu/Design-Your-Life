// F4 위젯: RoutineWeeklySection - 주간 시간표 섹션
// 활성 루틴을 기반으로 주간 시간표를 GlassmorphicCard 안에 표시한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/routine.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import 'weekly_timetable.dart';

/// 주간 시간표 섹션 위젯
class RoutineWeeklySection extends StatelessWidget {
  final List<Routine> routines;
  const RoutineWeeklySection({super.key, required this.routines});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Text('주간 시간표',
              style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary)),
        ),
        GlassmorphicCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: WeeklyTimetable(routines: routines),
        ),
      ],
    );
  }
}
