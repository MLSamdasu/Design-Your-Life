// 오늘의 습관 섹션: 달성률 차트 + 습관 추가 버튼 + 완료 현황
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/models/habit_log.dart';
import '../../../../shared/widgets/donut_chart.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../providers/habit_provider.dart';
import 'habit_list_section.dart';
import 'habit_preset_sheet.dart';

/// 섹션 1: 오늘의 습관 (달성률 + 습관 카드 리스트)
class TodayHabitsSection extends ConsumerWidget {
  final List<Habit> habits;

  /// 오늘 예정된 습관 목록 (빈도 기반 필터링 적용)
  final List<Habit> scheduledHabits;
  final List<HabitLog> logs;
  final double completionRate;
  final DateTime today;
  const TodayHabitsSection({
    super.key,
    required this.habits,
    required this.scheduledHabits,
    required this.logs,
    required this.completionRate,
    required this.today,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('오늘의 습관',
                  style: AppTypography.titleLg
                      .copyWith(color: context.themeColors.textPrimary)),
              const Spacer(),
              AddHabitButton(onTap: () => _showSheet(context, ref)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DonutChart(
                  percentage: completionRate,
                  size: DonutChartSize.medium,
                  type: DonutChartType.habit,
                  centerLabel: '달성'),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                  child: CompletionInfo(
                      scheduledHabits: scheduledHabits, logs: logs)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          HabitListSection(
              habits: habits,
              logs: logs,
              today: today,
              onEmpty: () => _showSheet(context, ref)),
        ],
      ),
    );
  }

  /// 습관 프리셋 시트를 표시하고 선택된 습관을 생성한다
  void _showSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.transparent,
      builder: (ctx) => HabitPresetSheet(onSelected: (result) async {
        // 습관 추가 실패 시 SnackBar로 사용자에게 오류를 알린다
        try {
          await ref.read(createHabitProvider).call(Habit(
                id: ref.read(generateHabitIdProvider).call(),
                name: result.preset.name,
                icon: result.preset.icon,
                color: result.preset.color,
                frequency: result.frequency,
                repeatDays: result.repeatDays,
              ));
        } catch (e) {
          if (ctx.mounted) {
            AppSnackBar.showError(ctx, '습관 추가에 실패했습니다');
          }
        }
        if (ctx.mounted) Navigator.of(ctx).pop();
      }),
    );
  }
}

/// 달성 현황 텍스트
/// 오늘 예정된 습관 기준으로 완료 수를 표시한다
class CompletionInfo extends StatelessWidget {
  final List<Habit> scheduledHabits;
  final List<HabitLog> logs;
  const CompletionInfo({
    super.key,
    required this.scheduledHabits,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final scheduledIds = scheduledHabits.map((h) => h.id).toSet();
    // 오늘 예정된 습관 중 완료된 로그만 카운트한다
    final done = logs
        .where((l) => l.isCompleted && scheduledIds.contains(l.habitId))
        .length;
    final total = scheduledHabits.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$done / $total 완료',
          style: AppTypography.titleLg
              .copyWith(color: context.themeColors.textPrimary)),
      const SizedBox(height: AppSpacing.xs),
      Text(
        total == 0
            ? '습관을 등록해보세요!'
            : done == total
                ? '모든 습관을 완료했어요!'
                : '${total - done}개 남았어요',
        style: AppTypography.bodyMd
            .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.7)),
      ),
    ]);
  }
}

/// 습관 추가 버튼 (헤더 우측)
class AddHabitButton extends StatelessWidget {
  final VoidCallback onTap;
  const AddHabitButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.mdLg, vertical: AppSpacing.xs),
          // 추가 버튼: 배경 테마에 맞는 악센트 색상으로 표시한다.
          // 어두운 배경(Glassmorphism/Neon)에서는 mainLight 계열을 사용한다.
          decoration: BoxDecoration(
            color: context.themeColors.accentWithAlpha(0.3),
            borderRadius: BorderRadius.circular(AppRadius.huge),
            border:
                Border.all(color: context.themeColors.accentWithAlpha(0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded,
                size: AppLayout.iconSm,
                color: context.themeColors.textPrimary),
            const SizedBox(width: AppSpacing.xs),
            Text('추가',
                style: AppTypography.captionLg
                    .copyWith(color: context.themeColors.textPrimary)),
          ]),
        ),
      );
}
