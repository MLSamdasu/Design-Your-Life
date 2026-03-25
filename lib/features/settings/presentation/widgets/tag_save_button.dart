// 태그 저장 버튼 위젯
// 태그 생성/편집 폼의 하단 CTA 버튼을 렌더링한다.
// 저장 중 상태에 따라 비활성화 스타일을 적용한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 태그 폼 하단 저장/수정 완료 버튼
class TagSaveButton extends StatelessWidget {
  /// 저장 진행 중 여부
  final bool isSaving;

  /// 편집 모드 여부 (true면 '수정 완료', false면 '태그 추가')
  final bool isEditMode;

  /// 버튼 탭 콜백
  final VoidCallback? onTap;

  const TagSaveButton({
    super.key,
    required this.isSaving,
    required this.isEditMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSaving ? null : onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
        decoration: BoxDecoration(
          color: isSaving
              ? ColorTokens.main.withValues(alpha: 0.5)
              : ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: isSaving
              ? null
              : [
                  BoxShadow(
                    color: ColorTokens.main.withValues(alpha: 0.3),
                    blurRadius: EffectLayout.ctaShadowBlur,
                    offset: const Offset(0, EffectLayout.ctaShadowOffsetY),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            isSaving
                ? '저장 중...'
                : (isEditMode ? '수정 완료' : '태그 추가'),
            // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
            style: AppTypography.titleMd.copyWith(color: ColorTokens.white),
          ),
        ),
      ),
    );
  }
}
