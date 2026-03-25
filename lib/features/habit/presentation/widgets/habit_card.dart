// F4 위젯: HabitCard - 습관 카드 (체크박스 + 습관명 + 이모지 + 스트릭)
// 시간 잠금: 오늘이 아닌 날짜는 체크박스를 비활성화한다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/models/habit_log.dart';
import '../../../../shared/widgets/animated_strikethrough.dart';
import '../../../../features/habit/services/time_lock_validator.dart';
import 'streak_badge.dart';
import 'habit_checkbox.dart';
import 'habit_card_popup_menu.dart';

/// 습관 카드 위젯 — AN-04: 원형 체크박스 bounce 애니메이션 300ms easeOutBack
class HabitCard extends StatefulWidget {
  final Habit habit;
  final HabitLog? log;
  final int currentStreak;
  final DateTime targetDate;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    required this.habit,
    required this.log,
    required this.currentStreak,
    required this.targetDate,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  // 300ms 디바운스: 빠른 연속 탭에 의한 API 중복 호출을 방지한다
  bool _isDebouncePending = false;

  bool get _isChecked => widget.log?.isCompleted ?? false; // 체크 여부
  bool get _isEditable => // 오늘인지 여부 (시간 잠금 검증)
      TimeLockValidator.isToday(widget.targetDate, DateTime.now());

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    if (_isChecked) _checkController.value = 1.0;
  }

  @override
  void didUpdateWidget(HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.log?.isCompleted ?? false) != _isChecked) {
      if (_isChecked) {
        _checkController.forward();
      } else {
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  /// 300ms 디바운스 체크 토글 — 빠른 연속 탭 시 중복 호출 방지
  void _handleTap() {
    if (!_isEditable) return;
    if (_isDebouncePending) return;
    _isDebouncePending = true;
    HapticFeedback.lightImpact();
    widget.onToggle(!_isChecked);
    Future.delayed(AppAnimation.slow, () {
      // 위젯이 소멸된 후 상태 변경을 방지한다 (탭 전환 중 디바운스 타이머 만료 시)
      if (!mounted) return;
      _isDebouncePending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = ColorTokens.eventColor(widget.habit.colorIndex);
    return GestureDetector(
      onLongPress: () => showHabitCardPopupMenu(
        context: context,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: _isChecked
            ? context.themeColors.textPrimaryWithAlpha(0.12)
            : context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all( // 완료 시 habitCheck 토큰 기반 초록 보더
          color: _isChecked
              ? ColorTokens.habitCheck.withValues(alpha: 0.3)
              : context.themeColors.textPrimaryWithAlpha(0.12),
        ),
      ),
      child: Row(
        children: [
          // 이모지 아이콘
          if (widget.habit.icon != null) ...[
            Text(
              widget.habit.icon!,
              // emojiLg 토큰 사용 (22px 이모지 전용)
              style: AppTypography.emojiLg,
            ),
            const SizedBox(width: AppSpacing.lg),
          ] else ...[
            Container(
              width: AppSpacing.md,
              height: AppLayout.colorBarHeight,
              decoration: BoxDecoration(
                color: habitColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
          // 습관명 + 스트릭 뱃지
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 습관명 (완료 시 빨간펜 취소선 애니메이션 적용)
                AnimatedStrikethrough(
                  text: widget.habit.name,
                  style: AppTypography.bodyMd.copyWith(
                    color: _isChecked
                        ? context.themeColors.textPrimaryWithAlpha(0.6)
                        : context.themeColors.textPrimary,
                  ),
                  isActive: _isChecked,
                ),
                if (widget.currentStreak > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  StreakBadge(streak: widget.currentStreak),
                ],
              ],
            ),
          ),
          // 원형 체크박스 (AN-04) — 접근성: Semantics + 최소 44x44px 터치 타겟
          Semantics(
            label: '${widget.habit.name} 습관 완료 체크박스',
            checked: _isChecked,
            enabled: _isEditable,
            child: SizedBox(
              width: AppLayout.minTouchTarget,
              height: AppLayout.minTouchTarget,
              child: GestureDetector(
                onTap: _handleTap,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _checkController,
                    builder: (context, _) {
                      final scale = 1.0 +
                          (_checkController.value > 0.5
                              ? (1 - _checkController.value) * EffectLayout.checkboxBounceScale
                              : -_checkController.value * EffectLayout.checkboxShrinkScale);
                      return Transform.scale(
                        scale: scale,
                        child: HabitCheckbox(
                          isChecked: _isChecked,
                          isEditable: _isEditable,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
