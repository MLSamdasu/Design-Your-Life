// 데일리 리추얼: 페이지 인디케이터 점 위젯
// 현재 페이지를 작은 점(dot)으로 표시하며, 활성 페이지는 확대+색상 변경된다.
// 하단에 배치하여 사용자에게 전체 진행 상황을 보여준다.

import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 데일리 리추얼 페이지 인디케이터
/// [pageCount]: 전체 페이지 수
/// [currentPage]: 현재 활성 페이지 인덱스
class RitualPageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;

  const RitualPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: AppAnimation.normal,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            // 활성 페이지는 악센트 컬러, 비활성은 반투명 텍스트 색상
            color: isActive
                ? tc.accent
                : tc.textPrimaryWithAlpha(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
