// 공용 위젯: EmptyState
// 3요소 포함: 기능 상징 아이콘 + 안내 텍스트(없음+행동 한 쌍) + CTA 버튼.
// 빈 상태와 에러 상태를 명확히 구분하여 표시한다.
import 'package:flutter/material.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 빈 상태 UI 위젯
/// design-system.md 12절 스펙: 아이콘(48px) + 메인 텍스트 + 서브 텍스트 + CTA
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String mainText;
  final String? subText;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final double minHeight;

  const EmptyState({
    required this.icon,
    required this.mainText,
    this.subText,
    this.ctaLabel,
    this.onCtaTap,
    this.minHeight = 120,
    super.key,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    // 아이콘 부유 애니메이션: 4px 수직 이동, 2000ms 반복
    _floatController = AnimationController(
      duration: AppAnimation.snackBar,
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 부유 아이콘
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_floatAnimation.value),
                  child: child,
                );
              },
              child: Icon(
                widget.icon,
                size: AppLayout.iconEmpty,
                color: context.themeColors.textPrimaryWithAlpha(0.3),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // 메인 안내 텍스트
            Text(
              widget.mainText,
              style: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            // 서브 텍스트 (선택)
            if (widget.subText != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.subText!,
                style: AppTypography.captionMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            // CTA 버튼 (선택)
            if (widget.ctaLabel != null && widget.onCtaTap != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _CtaButton(label: widget.ctaLabel!, onTap: widget.onCtaTap!),
            ],
          ],
        ),
      ),
    );
  }
}

/// 빈 상태 CTA 버튼 (Secondary Glass Button 스타일)
class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CtaButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: context.themeColors.overlayStrong,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.30),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.titleMd.copyWith(color: context.themeColors.textPrimary),
        ),
      ),
    );
  }
}
