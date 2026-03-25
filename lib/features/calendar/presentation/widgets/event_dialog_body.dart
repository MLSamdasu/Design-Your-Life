// F2 위젯: EventDialogBody - Glass Modal 다이얼로그 래퍼
// SRP 분리: 다이얼로그의 유리 효과 배경 + 스크롤 레이아웃만 담당한다
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// Glass Modal 스타일 다이얼로그 본문 래퍼
/// BackdropFilter + GlassDecoration.modal + SingleChildScrollView 구조
class EventDialogBody extends StatelessWidget {
  /// 다이얼로그 내부에 표시할 자식 위젯 목록
  final List<Widget> children;

  const EventDialogBody({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorTokens.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.massive,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: EffectLayout.modalBlurSigma,
            sigmaY: EffectLayout.modalBlurSigma,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: GlassDecoration.modal(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
