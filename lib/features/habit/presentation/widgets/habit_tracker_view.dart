// F4 위젯: HabitTrackerView - 습관 트래커 메인 뷰
// 섹션1: 오늘의 습관 (달성률 DonutChart + 습관 카드 리스트)
// 섹션2: 습관 캘린더 (HabitCalendarSection으로 분리)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/models/habit_log.dart';
import '../../../../shared/widgets/donut_chart.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../providers/habit_provider.dart';
import 'habit_calendar_section.dart';
import 'habit_card.dart';
import 'habit_preset_sheet.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 습관 트래커 뷰 (서브탭 1)
class HabitTrackerView extends ConsumerWidget {
  const HabitTrackerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TodayHabitsSection(
            habitsAsync: ref.watch(activeHabitsProvider),
            logsAsync: ref.watch(habitLogsForDateProvider),
            completionRate: ref.watch(todayHabitCompletionRateProvider),
            today: DateTime(now.year, now.month, now.day),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const HabitCalendarSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

/// 섹션 1: 오늘의 습관
class _TodayHabitsSection extends ConsumerWidget {
  final AsyncValue<List<Habit>> habitsAsync;
  final AsyncValue<List<HabitLog>> logsAsync;
  final double completionRate;
  final DateTime today;
  const _TodayHabitsSection({required this.habitsAsync, required this.logsAsync,
      required this.completionRate, required this.today});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('오늘의 습관',
                  style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary)),
              const Spacer(),
              _AddBtn(onTap: () => _showSheet(context, ref)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DonutChart(percentage: completionRate, size: DonutChartSize.medium,
                  type: DonutChartType.habit, centerLabel: '달성'),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: _CompletionInfo(
                  habitsAsync: habitsAsync, logsAsync: logsAsync)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _HabitList(habitsAsync: habitsAsync, logsAsync: logsAsync,
              today: today, onEmpty: () => _showSheet(context, ref)),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.transparent,
      builder: (ctx) => HabitPresetSheet(onSelected: (preset) async {
        final userId = ref.read(currentUserIdProvider);
        if (userId == null) return;
        // 습관 추가 실패 시 SnackBar로 사용자에게 오류를 알린다
        try {
          await ref.read(createHabitProvider).call(Habit(
            id: ref.read(generateHabitIdProvider).call(),
            name: preset.name, icon: preset.icon,
            color: preset.color,
          ));
        } catch (e) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: const Text('습관 추가에 실패했습니다'),
                backgroundColor: ColorTokens.infoHintBg,
              ),
            );
          }
        }
        if (ctx.mounted) Navigator.of(ctx).pop();
      }),
    );
  }
}
/// 달성 현황 텍스트
class _CompletionInfo extends StatelessWidget {
  final AsyncValue<List<Habit>> habitsAsync;
  final AsyncValue<List<HabitLog>> logsAsync;
  const _CompletionInfo({required this.habitsAsync, required this.logsAsync});
  @override
  Widget build(BuildContext context) {
    return habitsAsync.when(
      data: (habits) => logsAsync.when(
        data: (logs) {
          final done = logs.where((l) => l.isCompleted).length;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$done / ${habits.length} 완료',
                style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              habits.isEmpty ? '습관을 등록해보세요!'
                  : done == habits.length ? '모든 습관을 완료했어요!'
                  : '${habits.length - done}개 남았어요',
              style: AppTypography.bodyMd
                  .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.7)),
            ),
          ]);
        },
        loading: () => const LoadingSkeleton(height: 40),
        // 로그 로드 실패 시 빈 위젯 대신 오류 메시지를 표시한다
        error: (_, __) => Text(
          '로그를 불러오지 못했어요',
          style: AppTypography.bodyMd.copyWith(
            color: ColorTokens.infoHint.withValues(alpha: 0.9),
          ),
        ),
      ),
      loading: () => const LoadingSkeleton(height: 40),
      // 습관 로드 실패 시 빈 위젯 대신 오류 메시지를 표시한다
      error: (_, __) => Text(
        '습관 정보를 불러오지 못했어요',
        style: AppTypography.bodyMd.copyWith(
          color: ColorTokens.infoHint.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
/// 습관 카드 목록
class _HabitList extends ConsumerWidget {
  final AsyncValue<List<Habit>> habitsAsync;
  final AsyncValue<List<HabitLog>> logsAsync;
  final DateTime today;
  final VoidCallback onEmpty;
  const _HabitList({required this.habitsAsync, required this.logsAsync,
      required this.today, required this.onEmpty});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skeletons = Column(children: List.generate(2, (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: LoadingSkeleton(height: 60, borderRadius: 16))));
    return habitsAsync.when(
      data: (habits) => logsAsync.when(
        data: (logs) {
          if (habits.isEmpty) {
            return EmptyState(icon: Icons.emoji_nature_rounded,
              mainText: '아직 등록된 습관이 없어요',
              subText: '인기 습관으로 시작하거나 직접 만들어보세요',
              ctaLabel: '인기 습관으로 시작하기', onCtaTap: onEmpty);
          }
          return AnimatedSwitcher(
            duration: AppAnimation.medium,
            child: Column(key: ValueKey(habits.length),
              children: habits.map((h) {
                final log = logs.firstWhere((l) => l.habitId == h.id,
                  orElse: () => HabitLog(id: '', habitId: h.id,
                      date: today, isCompleted: false, checkedAt: today));
                return HabitCard(key: Key(h.id), habit: h,
                  log: log.id.isEmpty ? null : log, currentStreak: 0,
                  targetDate: today,
                  // 습관 체크/토글 실패 시 SnackBar로 오류를 표시한다
                  onToggle: (c) async {
                    try {
                      await ref.read(toggleHabitProvider).call(h.id, today, c);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('습관 상태 변경에 실패했습니다'),
                            backgroundColor: ColorTokens.infoHintBg,
                          ),
                        );
                      }
                    }
                  });
              }).toList()),
          );
        },
        loading: () => skeletons,
        // 로그 로드 실패 시 빈 위젯 대신 오류 메시지를 표시한다
        error: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Text(
            '습관 기록을 불러오지 못했어요',
            style: AppTypography.bodyMd.copyWith(
              color: ColorTokens.infoHint.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
      loading: () => skeletons,
      // 습관 목록 로드 실패 시 빈 위젯 대신 오류 메시지를 표시한다
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          '습관 목록을 불러오지 못했어요',
          style: AppTypography.bodyMd.copyWith(
            color: ColorTokens.infoHint.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mdLg, vertical: AppSpacing.xs),
          // 추가 버튼: 배경 테마에 맞는 악센트 색상으로 표시한다.
          // 어두운 배경(Glassmorphism/Neon)에서는 mainLight 계열을 사용한다.
          decoration: BoxDecoration(
            color: context.themeColors.accentWithAlpha(0.3),
            borderRadius: BorderRadius.circular(AppRadius.huge),
            border: Border.all(color: context.themeColors.accentWithAlpha(0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, size: AppLayout.iconSm, color: context.themeColors.textPrimary),
            const SizedBox(width: AppSpacing.xs),
            Text('추가', style: AppTypography.captionLg.copyWith(color: context.themeColors.textPrimary)),
          ]),
        ),
      );
}
