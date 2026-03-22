// F5 위젯: MandalartEmptyState - 만다라트 빈 상태 위젯 (SRP 분리)
// mandalart_view.dart에서 추출한다.
// 만다라트가 없을 때 부유 아이콘 + 안내 텍스트 + 생성 버튼을 표시한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import 'mandalart_wizard.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 만다라트가 없을 때 표시되는 빈 상태 위젯
class MandalartEmptyState extends StatefulWidget {
  final VoidCallback onCreateTap;
  final String message;

  const MandalartEmptyState({
    super.key,
    required this.onCreateTap,
    this.message = '아직 만다라트가 없어요',
  });

  @override
  State<MandalartEmptyState> createState() => _MandalartEmptyStateState();
}

class _MandalartEmptyStateState extends State<MandalartEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    // 부유 애니메이션: 2초 주기 위아래 반복
    _floatController = AnimationController(
      vsync: this,
      duration: AppAnimation.snackBar,
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -AppAnimation.floatOffsetLg, end: AppAnimation.floatOffsetLg).animate(
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 부유 아이콘
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: child,
              );
            },
            child: Icon(
              Icons.grid_view_rounded,
              size: AppLayout.iconEmptyLg,
              color: context.themeColors.textPrimaryWithAlpha(0.3),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            widget.message,
            style: AppTypography.bodyLg.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '3단계 위저드로 목표를 만다라트로 구조화해보세요!',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.45),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLayout.iconHuge),
          // 만다라트 생성 버튼
          GestureDetector(
            onTap: widget.onCreateTap,
            child: Container(
              // CTA 버튼 좌우 패딩: iconHuge(28)과 동일 값을 사용한다
              padding: const EdgeInsets.symmetric(horizontal: AppLayout.iconHuge, vertical: AppSpacing.lgXl),
              decoration: BoxDecoration(
                color: ColorTokens.main,
                borderRadius: BorderRadius.circular(AppRadius.xlLg),
                boxShadow: [
                  BoxShadow(
                    color: ColorTokens.main.withValues(alpha: AppAnimation.ctaButtonShadowAlpha),
                    blurRadius: AppLayout.shadowBlurLg,
                    offset: const Offset(0, AppLayout.shadowOffsetMd),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                    color: ColorTokens.white,
                    size: AppLayout.iconLg,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    '만다라트 만들기',
                    style: AppTypography.titleMd.copyWith(
                      // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                      color: ColorTokens.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// MandalartWizard를 AN-06 애니메이션으로 표시하는 공용 헬퍼
Future<void> showMandalartWizard(BuildContext context) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: ColorTokens.barrierBase.withValues(alpha: AppAnimation.barrierAlphaStrong),
    transitionDuration: AppAnimation.medium,
    pageBuilder: (_, __, ___) => const MandalartWizard(),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: AppAnimation.wizardScaleIn, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}
