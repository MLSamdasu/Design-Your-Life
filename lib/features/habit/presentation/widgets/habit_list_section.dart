// 습관 카드 목록 섹션: 스트릭 계산 + 삭제 확인 다이얼로그
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/models/habit_log.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../providers/habit_provider.dart';
import 'habit_card.dart';
import 'habit_edit_dialog.dart';

/// 습관 카드 목록 (스트릭 계산 포함)
class HabitListSection extends ConsumerWidget {
  final List<Habit> habits;
  final List<HabitLog> logs;
  final DateTime today;
  final VoidCallback onEmpty;
  const HabitListSection({
    super.key,
    required this.habits,
    required this.logs,
    required this.today,
    required this.onEmpty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (habits.isEmpty) {
      return EmptyState(
          icon: Icons.emoji_nature_rounded,
          mainText: '아직 등록된 습관이 없어요',
          subText: '인기 습관으로 시작하거나 직접 만들어보세요',
          ctaLabel: '인기 습관으로 시작하기',
          onCtaTap: onEmpty);
    }
    // 오늘 요일에 해당하는 습관만 필터링한다 (빈도 기반)
    final todayHabits =
        habits.where((h) => h.isScheduledFor(today)).toList();
    if (todayHabits.isEmpty) {
      return EmptyState(
          icon: Icons.calendar_today_rounded,
          mainText: '오늘은 예정된 습관이 없어요',
          subText: '다른 요일에 예정된 습관이 있습니다');
    }
    // ListView.builder로 습관 카드를 지연 빌드하여 성능을 개선한다
    // 부모 SingleChildScrollView 내부이므로 shrinkWrap + NeverScrollableScrollPhysics 사용
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: todayHabits.length,
      itemBuilder: (context, index) {
        final h = todayHabits[index];
        final log = logs.firstWhere(
          (l) => l.habitId == h.id,
          orElse: () => HabitLog(
              id: '',
              habitId: h.id,
              date: today,
              isCompleted: false,
              checkedAt: today),
        );
        final streak = ref.watch(streakForHabitProvider(h.id));
        return RepaintBoundary(
          child: HabitCard(
            key: Key(h.id),
            habit: h,
            log: log.id.isEmpty ? null : log,
            currentStreak: streak,
            targetDate: today,
            // 습관 체크/토글: 시간 잠금 거부 시 사유를 SnackBar로 표시한다
            onToggle: (c) async {
              try {
                final lockResult = await ref
                    .read(toggleHabitProvider)
                    .call(h.id, today, c);
                if (lockResult != null && context.mounted) {
                  // 시간 잠금으로 거부된 경우 사유를 사용자에게 표시한다
                  AppSnackBar.showError(context, lockResult.reason);
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.showError(context, '습관 상태 변경에 실패했습니다');
                }
              }
            },
            // 습관 수정 다이얼로그를 표시한다
            onEdit: () => showHabitEditDialog(context, ref, h),
            // 습관 삭제 확인 다이얼로그를 표시한다
            onDelete: () => showHabitDeleteConfirm(context, ref, h),
          ),
        );
      },
    );
  }
}

/// 습관 삭제 확인 다이얼로그를 표시한다 (goal_card 패턴)
Future<void> showHabitDeleteConfirm(
    BuildContext context, WidgetRef ref, Habit habit) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '습관 삭제',
        style: AppTypography.titleMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: Text(
        '이 습관과 관련된 기록이 모두 삭제됩니다.\n정말 삭제하시겠습니까?',
        style: AppTypography.bodyMd.copyWith(
          color: context.themeColors.textPrimaryWithAlpha(0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            '취소',
            style: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            '삭제',
            style: AppTypography.bodyMd.copyWith(
              color: ColorTokens.error,
            ),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    try {
      await ref.read(deleteHabitProvider).call(habit.id);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '습관 삭제에 실패했습니다');
      }
    }
  }
}
