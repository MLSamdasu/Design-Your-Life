// F-Memo: 메모 검색 바 위젯
// 메모 리스트 상단에서 검색어를 입력받아 필터링에 사용한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 메모 검색 입력 바
class MemoSearchBar extends StatelessWidget {
  /// 검색어 컨트롤러
  final TextEditingController controller;

  /// 검색어 변경 시 호출되는 콜백
  final VoidCallback onChanged;

  const MemoSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        decoration: BoxDecoration(
          color: tc.overlayLight,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          onChanged: (_) => onChanged(),
          style: AppTypography.bodyLg.copyWith(color: tc.textPrimary),
          cursorColor: tc.textPrimary,
          decoration: InputDecoration(
            hintText: '메모 검색...',
            hintStyle: AppTypography.bodyLg.copyWith(color: tc.hintColor),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.mdLg,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: tc.textPrimaryWithAlpha(0.50),
              size: AppLayout.iconMd,
            ),
          ),
        ),
      ),
    );
  }
}
