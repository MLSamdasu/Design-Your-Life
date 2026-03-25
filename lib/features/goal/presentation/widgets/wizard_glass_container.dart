// F5 위젯: 만다라트 위저드용 글래스모피즘 컨테이너
// 블러 배경 + 유리 질감 모달 래퍼를 제공한다.
// 내부 자식(헤더·본문·푸터)을 Column으로 배치한다.
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';

/// 글래스모피즘 모달 래퍼
/// 만다라트 위저드의 시각적 컨테이너 역할만 수행한다
class WizardGlassContainer extends StatelessWidget {
  /// Column에 배치할 자식 위젯 목록
  final List<Widget> children;

  const WizardGlassContainer({
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppLayout.dialogMaxWidthLg,
          maxHeight: AppLayout.dialogMaxHeight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassDecoration.elevatedBlurSigma,
              sigmaY: GlassDecoration.elevatedBlurSigma,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                decoration: GlassDecoration.modal(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
