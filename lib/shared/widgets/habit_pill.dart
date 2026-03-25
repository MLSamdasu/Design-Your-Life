// 공용 위젯: HabitPill (습관 카드 필 형태)
// 이모지 아이콘 + 습관명 + 완료 상태 + 원형 체크박스 + 스트릭 뱃지
// Subtle 카드 스타일 적용 (radius-2xl: 16px, opacity 0.12)
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import 'habit_pill_checkbox.dart';

export 'habit_pill_checkbox.dart';

/// 습관 카드 필 위젯
/// 홈 대시보드 습관 프리뷰, 습관 탭 리스트에서 사용한다
class HabitPill extends StatefulWidget {
  final String? icon;
  final String name;
  final bool isCompleted;
  final int streak;
  final VoidCallback? onToggle;

  const HabitPill({
    super.key,
    this.icon,
    required this.name,
    required this.isCompleted,
    this.streak = 0,
    this.onToggle,
  });

  @override
  State<HabitPill> createState() => _HabitPillState();
}

class _HabitPillState extends State<HabitPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // AN-04: 완료 체크 애니메이션 (300ms, easeOutBack)
    _controller = AnimationController(
      duration: AppAnimation.medium,
      vsync: this,
      value: widget.isCompleted ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(HabitPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompleted != widget.isCompleted) {
      if (widget.isCompleted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    if (widget.onToggle == null) return;
    widget.onToggle!();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Subtle 카드 스타일 패딩 (수직 10px, 수평 14px)
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lgXl, vertical: AppSpacing.mdLg),
      decoration: BoxDecoration(
        color: context.themeColors.overlayMedium,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Row(
        children: [
          // 이모지 아이콘 (선택)
          if (widget.icon != null) ...[
            Text(widget.icon!, style: AppTypography.emojiMd),
            const SizedBox(width: AppSpacing.mdLg),
          ] else ...[
            Icon(
              Icons.loop_rounded,
              color: context.themeColors.textPrimaryWithAlpha(0.70),
              size: AppLayout.iconXl,
            ),
            const SizedBox(width: AppSpacing.mdLg),
          ],
          // 습관 이름
          Expanded(
            child: Text(
              widget.name,
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 스트릭 뱃지 (streak > 0일 때만 표시)
          if (widget.streak > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: context.themeColors.overlayStrong,
                borderRadius: BorderRadius.circular(AppRadius.huge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔥', style: AppTypography.captionEmoji),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    '${widget.streak}일',
                    style: AppTypography.captionLg.copyWith(
                      color: context.themeColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.mdLg),
          ],
          // 원형 체크박스 (22x22)
          HabitPillCheckbox(
            habitName: widget.name,
            isCompleted: widget.isCompleted,
            controller: _controller,
            onToggle: _handleToggle,
          ),
        ],
      ),
    );
  }
}
