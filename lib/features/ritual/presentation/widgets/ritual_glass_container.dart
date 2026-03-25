// 데일리 리추얼: 글래스모피즘 컨테이너
// 각 리추얼 페이지의 콘텐츠를 감싸는 반투명 유리 카드이다.
// 테마에 맞는 배경색 + 미세 보더로 입체감을 표현한다.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 리추얼 페이지용 글래스모피즘 컨테이너
/// [child]: 내부 콘텐츠
/// [padding]: 내부 여백 (기본: dialogPadding)
class RitualGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const RitualGlassContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.massive),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: EffectLayout.blurSigmaStandard,
          sigmaY: EffectLayout.blurSigmaStandard,
        ),
        child: Container(
          padding: padding ??
              const EdgeInsets.all(AppSpacing.dialogPadding),
          decoration: BoxDecoration(
            color: tc.overlayLight,
            borderRadius: BorderRadius.circular(AppRadius.massive),
            border: Border.all(
              color: tc.borderLight,
              width: AppLayout.borderThin,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
