// 공용 위젯: HabitPill (습관 카드 필 형태)
// 이모지 아이콘 + 습관명 + 완료 상태 + 원형 체크박스 + 스트릭 뱃지
// design-system.md 14.2절 습관 체크(원형) 스펙 참조
// Subtle 카드 스타일 적용 (radius-2xl: 16px, opacity 0.12)
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 습관 카드 필 위젯
/// 홈 대시보드 습관 프리뷰, 습관 탭 리스트에서 사용한다
class HabitPill extends StatefulWidget {
  /// 습관 이모지 아이콘
  final String? icon;

  /// 습관 이름
  final String name;

  /// 오늘 완료 여부
  final bool isCompleted;

  /// 연속 달성 일수 (0이면 뱃지 숨김)
  final int streak;

  /// 완료 토글 콜백
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
        borderRadius: BorderRadius.circular(AppRadius.xxl), // radius-2xl (16px)
      ),
      child: Row(
        children: [
          // 이모지 아이콘 (선택)
          if (widget.icon != null) ...[
            Text(
              widget.icon!,
              // emojiMd 토큰 사용 (20px 이모지 전용)
              style: AppTypography.emojiMd,
            ),
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
                // SUB 컬러 기반 뱃지 배경
                color: context.themeColors.overlayStrong,
                borderRadius: BorderRadius.circular(AppRadius.huge), // radius-3xl (캡슐)
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // captionEmoji 토큰 사용 (10px 이모지 전용)
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

          // 원형 체크박스 (22x22) + 접근성: Semantics + 최소 44x44px 터치 타겟
          Semantics(
            label: '${widget.name} 습관 완료 토글',
            checked: widget.isCompleted,
            button: true,
            child: SizedBox(
              width: AppLayout.minTouchTarget,
              height: AppLayout.minTouchTarget,
              child: GestureDetector(
                onTap: _handleToggle,
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final value = _controller.value;
                // Scale bounce: 1.0 -> 0.85 -> 1.15 -> 1.0
                final scale = value > 0
                    ? 1.0 + (value * 0.15).clamp(-0.15, 0.15) * (1 - value)
                    : 1.0;
                return Transform.scale(
                  scale: scale.clamp(0.85, 1.15),
                  child: AnimatedContainer(
                    duration: AppAnimation.normal,
                    width: AppLayout.iconNav,
                    height: AppLayout.iconNav,
                    decoration: BoxDecoration(
                      // 완료: habitCheck 토큰 기반 초록 배경
                      color: widget.isCompleted
                          ? ColorTokens.habitCheck.withValues(alpha: 0.40)
                          : ColorTokens.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isCompleted
                            ? ColorTokens.habitCheck.withValues(alpha: 0.60)
                            : context.themeColors.textPrimaryWithAlpha(0.30),
                        width: AppLayout.borderThick,
                      ),
                    ),
                    child: widget.isCompleted
                        // 체크 아이콘: habitCheck 배경이 alpha 0.40이므로
                        // 라이트 테마에서 흰색이 안 보인다. 테마 인식 색상 사용
                        ? Icon(Icons.check, color: context.themeColors.textPrimary, size: AppSpacing.lg)
                        : null,
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
