// F4 위젯: HabitCard - 습관 카드
// 체크박스 + 습관명 + 이모지 아이콘 + 스트릭 카운터를 표시한다.
// 시간 잠금: 오늘이 아닌 날짜는 체크박스를 비활성화한다.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/habit.dart';
import '../../../../shared/models/habit_log.dart';
import '../../../../features/habit/services/time_lock_validator.dart';
import 'streak_badge.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 습관 카드 위젯 (오늘의 습관 섹션)
/// AN-04: 원형 체크박스 bounce 애니메이션 300ms easeOutBack
class HabitCard extends StatefulWidget {
  final Habit habit;
  final HabitLog? log;
  final int currentStreak;
  final DateTime targetDate;
  final ValueChanged<bool> onToggle;

  const HabitCard({
    required this.habit,
    required this.log,
    required this.currentStreak,
    required this.targetDate,
    required this.onToggle,
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

  /// 체크 여부
  bool get _isChecked => widget.log?.isCompleted ?? false;

  /// 오늘인지 여부 (시간 잠금 검증)
  bool get _isEditable =>
      TimeLockValidator.isToday(widget.targetDate, DateTime.now());

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: AppAnimation.medium,
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

  /// 300ms 디바운스로 체크 토글 (TodoItemTile과 동일한 패턴)
  /// 빠른 연속 탭 시 API 호출이 중복 발생하는 것을 방지한다
  void _handleTap() {
    if (!_isEditable) return;
    if (_isDebouncePending) return;
    _isDebouncePending = true;
    HapticFeedback.lightImpact();
    widget.onToggle(!_isChecked);
    Future.delayed(AppAnimation.medium, () {
      _isDebouncePending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = ColorTokens.eventColor(widget.habit.colorIndex);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: _isChecked
            ? context.themeColors.textPrimaryWithAlpha(0.12)
            : context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          // 완료 시 habitCheck 토큰 기반 초록 보더
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
              width: 8,
              height: 36,
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
                Text(
                  widget.habit.name,
                  style: AppTypography.bodyMd.copyWith(
                    color: _isChecked
                        ? context.themeColors.textPrimaryWithAlpha(0.6)
                        : context.themeColors.textPrimary,
                    decoration:
                        _isChecked ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.currentStreak > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  StreakBadge(streak: widget.currentStreak),
                ],
              ],
            ),
          ),
          // 원형 체크박스 (AN-04)
          // 접근성: Semantics + 최소 44x44px 터치 타겟 보장
          Semantics(
            label: '${widget.habit.name} 습관 완료 체크박스',
            checked: _isChecked,
            enabled: _isEditable,
            child: SizedBox(
              width: 44,
              height: 44,
              child: GestureDetector(
                onTap: _handleTap,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _checkController,
                    builder: (context, _) {
                      final scale = 1.0 +
                          (_checkController.value > 0.5
                              ? (1 - _checkController.value) * 0.3
                              : -_checkController.value * 0.15);
                      return Transform.scale(
                        scale: scale,
                        child: _HabitCheckbox(
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
    );
  }
}

/// 습관 원형 체크박스
class _HabitCheckbox extends StatelessWidget {
  final bool isChecked;
  final bool isEditable;

  const _HabitCheckbox({
    required this.isChecked,
    required this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.normal,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 완료 상태: habitCheck 토큰 (초록 계열) 기반 색상
        color: isChecked
            ? ColorTokens.habitCheck.withValues(alpha: 0.4)
            : ColorTokens.transparent,
        border: Border.all(
          color: isChecked
              ? ColorTokens.habitCheck.withValues(alpha: 0.6)
              : isEditable
                  ? context.themeColors.textPrimaryWithAlpha(0.3)
                  : context.themeColors.textPrimaryWithAlpha(0.15),
          width: 2,
        ),
      ),
      child: isChecked
          ? Icon(
              Icons.check_rounded,
              size: AppLayout.iconSm,
              color: context.themeColors.textPrimary,
            )
          : null,
    );
  }
}
