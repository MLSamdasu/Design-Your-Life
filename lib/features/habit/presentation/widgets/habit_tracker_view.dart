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
import '../../providers/habit_provider.dart';
import 'habit_calendar_section.dart';
import 'habit_card.dart';
import 'habit_preset_sheet.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/bottom_scroll_spacer.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

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
            habits: ref.watch(activeHabitsProvider),
            scheduledHabits: ref.watch(todayScheduledHabitsProvider),
            logs: ref.watch(habitLogsForDateProvider),
            completionRate: ref.watch(todayHabitCompletionRateProvider),
            today: DateTime(now.year, now.month, now.day),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const HabitCalendarSection(),
          // 하단 여백: 마지막 콘텐츠를 화면 중앙까지 스크롤 가능하도록 화면 절반 높이
          const BottomScrollSpacer(),
        ],
      ),
    );
  }
}

/// 섹션 1: 오늘의 습관
class _TodayHabitsSection extends ConsumerWidget {
  final List<Habit> habits;

  /// 오늘 예정된 습관 목록 (빈도 기반 필터링 적용)
  final List<Habit> scheduledHabits;
  final List<HabitLog> logs;
  final double completionRate;
  final DateTime today;
  const _TodayHabitsSection({required this.habits,
      required this.scheduledHabits, required this.logs,
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
                  scheduledHabits: scheduledHabits, logs: logs)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _HabitList(habits: habits, logs: logs,
              today: today, onEmpty: () => _showSheet(context, ref)),
        ],
      ),
    );
  }

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
class _CompletionInfo extends StatelessWidget {
  final List<Habit> scheduledHabits;
  final List<HabitLog> logs;
  const _CompletionInfo({required this.scheduledHabits, required this.logs});
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
          style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary)),
      const SizedBox(height: AppSpacing.xs),
      Text(
        total == 0 ? '습관을 등록해보세요!'
            : done == total ? '모든 습관을 완료했어요!'
            : '${total - done}개 남았어요',
        style: AppTypography.bodyMd
            .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.7)),
      ),
    ]);
  }
}
/// 습관 카드 목록 (스트릭 계산 포함)
class _HabitList extends ConsumerWidget {
  final List<Habit> habits;
  final List<HabitLog> logs;
  final DateTime today;
  final VoidCallback onEmpty;
  const _HabitList({required this.habits, required this.logs,
      required this.today, required this.onEmpty});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (habits.isEmpty) {
      return EmptyState(icon: Icons.emoji_nature_rounded,
        mainText: '아직 등록된 습관이 없어요',
        subText: '인기 습관으로 시작하거나 직접 만들어보세요',
        ctaLabel: '인기 습관으로 시작하기', onCtaTap: onEmpty);
    }
    // 오늘 요일에 해당하는 습관만 필터링한다 (빈도 기반)
    final todayHabits = habits
        .where((h) => h.isScheduledFor(today))
        .toList();
    if (todayHabits.isEmpty) {
      return EmptyState(icon: Icons.calendar_today_rounded,
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
        final log = logs.firstWhere((l) => l.habitId == h.id,
          orElse: () => HabitLog(id: '', habitId: h.id,
              date: today, isCompleted: false, checkedAt: today));
        final streak = ref.watch(streakForHabitProvider(h.id));
        return RepaintBoundary(
          child: HabitCard(key: Key(h.id), habit: h,
            log: log.id.isEmpty ? null : log, currentStreak: streak,
            targetDate: today,
            // 습관 체크/토글: 시간 잠금 거부 시 사유를 SnackBar로 표시한다
            onToggle: (c) async {
              try {
                final lockResult = await ref.read(toggleHabitProvider).call(h.id, today, c);
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
            onEdit: () => _showEditDialog(context, ref, h),
            // 습관 삭제 확인 다이얼로그를 표시한다
            onDelete: () => _showDeleteConfirm(context, ref, h),
          ),
        );
      },
    );
  }
}
/// 습관 수정 다이얼로그를 표시한다 (이름 + 빈도 수정 지원)
Future<void> _showEditDialog(BuildContext context, WidgetRef ref, Habit habit) async {
  final result = await showDialog<Habit>(
    context: context,
    builder: (ctx) => _HabitEditDialog(habit: habit),
  );

  if (result != null && context.mounted) {
    try {
      await ref.read(updateHabitProvider).call(habit.id, result);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, '습관 수정에 실패했습니다');
      }
    }
  }
}

/// 습관 수정 다이얼로그 (이름 + 빈도 편집)
class _HabitEditDialog extends StatefulWidget {
  final Habit habit;
  const _HabitEditDialog({required this.habit});

  @override
  State<_HabitEditDialog> createState() => _HabitEditDialogState();
}

class _HabitEditDialogState extends State<_HabitEditDialog> {
  late TextEditingController _nameCtrl;
  late bool _isCustomFrequency;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.habit.name);
    _isCustomFrequency = widget.habit.frequency != HabitFrequency.daily;
    _selectedDays = Set<int>.from(widget.habit.repeatDays);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// 저장 가능 조건: 이름이 비어있지 않고, 특정 요일 선택 시 1개 이상
  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      (!_isCustomFrequency || _selectedDays.isNotEmpty);

  void _submit() {
    if (!_canSubmit) return;
    final frequency =
        _isCustomFrequency ? HabitFrequency.weekly : HabitFrequency.daily;
    final repeatDays = _isCustomFrequency
        ? (_selectedDays.toList()..sort())
        : <int>[];
    Navigator.of(context).pop(widget.habit.copyWith(
      name: _nameCtrl.text.trim(),
      frequency: frequency,
      repeatDays: repeatDays,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '습관 수정',
        style: AppTypography.titleMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 습관 이름
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              maxLength: AppLayout.habitNameMaxLength,
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '습관 이름',
                hintStyle: AppTypography.bodyMd.copyWith(
                  // WCAG 최소 대비를 충족하도록 알파값을 0.55로 상향 조정
                  color: context.themeColors.textPrimaryWithAlpha(0.55),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 빈도 라벨
            Text(
              '반복 빈도',
              style: AppTypography.captionLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.65),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 매일 / 특정 요일 토글
            Row(
              children: [
                Expanded(
                  child: _FrequencyChip(
                    label: '매일',
                    isSelected: !_isCustomFrequency,
                    onTap: () => setState(() {
                      _isCustomFrequency = false;
                      _selectedDays.clear();
                    }),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _FrequencyChip(
                    label: '특정 요일',
                    isSelected: _isCustomFrequency,
                    onTap: () => setState(() => _isCustomFrequency = true),
                  ),
                ),
              ],
            ),

            // 요일 선택기 (특정 요일인 경우만)
            if (_isCustomFrequency) ...[
              const SizedBox(height: AppSpacing.lg),
              _DaySelectorRow(
                selectedDays: _selectedDays,
                onToggle: (day) => setState(() {
                  _selectedDays.contains(day)
                      ? _selectedDays.remove(day)
                      : _selectedDays.add(day);
                }),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '취소',
            style: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
        ),
        TextButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(
            '저장',
            style: AppTypography.bodyMd.copyWith(
              color: _canSubmit
                  ? ColorTokens.main
                  : context.themeColors.textPrimaryWithAlpha(0.3),
            ),
          ),
        ),
      ],
    );
  }
}

/// 다이얼로그용 빈도 선택 칩
class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FrequencyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: isSelected
              ? context.themeColors.accentWithAlpha(0.85)
              : context.themeColors.textPrimaryWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isSelected
                ? context.themeColors.accent
                : context.themeColors.textPrimaryWithAlpha(0.18),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.captionLg.copyWith(
              color: context.themeColors.textPrimary,
              fontWeight: isSelected ? AppTypography.weightBold : AppTypography.weightRegular,
            ),
          ),
        ),
      ),
    );
  }
}

/// 다이얼로그용 요일 선택 행 (월~일)
class _DaySelectorRow extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<int> onToggle;
  const _DaySelectorRow({required this.selectedDays, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(AppLayout.daysInWeek, (i) {
        final day = i + 1;
        final sel = selectedDays.contains(day);
        // WCAG 2.1 최소 터치 타겟(44px) 확보: 시각적 원은 32px 유지, 터치 영역만 확장
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onToggle(day),
          child: SizedBox(
            width: AppLayout.minTouchTarget,
            height: AppLayout.minTouchTarget,
            child: Center(
              child: Container(
                width: AppLayout.containerMd,
                height: AppLayout.containerMd,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel
                      ? context.themeColors.accentWithAlpha(0.85)
                      : context.themeColors.textPrimaryWithAlpha(0.08),
                  border: Border.all(
                    color: sel
                        ? context.themeColors.accent
                        : context.themeColors.textPrimaryWithAlpha(0.18),
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: AppTypography.captionSm.copyWith(
                      color: sel
                          ? context.themeColors.textPrimary
                          : context.themeColors.textPrimaryWithAlpha(0.6),
                      fontWeight: sel ? AppTypography.weightBold : AppTypography.weightRegular,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// 습관 삭제 확인 다이얼로그를 표시한다 (goal_card 패턴)
Future<void> _showDeleteConfirm(BuildContext context, WidgetRef ref, Habit habit) async {
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
