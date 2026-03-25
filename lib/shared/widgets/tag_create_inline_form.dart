// 태그 인라인 생성 폼 위젯
// TagChipSelector에서 "+" 버튼 클릭 시 표시되는 태그 이름 입력 + 색상 선택 폼이다.
// 태그명 입력 TextField, 8색 TagColorDotPicker, 확인/취소 버튼으로 구성된다.
import 'package:flutter/material.dart';

import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';
import '../models/tag.dart';
import 'tag_color_dot_picker.dart';

/// 태그 이름 입력 + 색상 선택 인라인 폼 (SRP 분리)
class TagCreateInlineForm extends StatelessWidget {
  /// 태그 이름 입력 컨트롤러
  final TextEditingController controller;

  /// 현재 선택된 색상 인덱스
  final int selectedColorIndex;

  /// 색상 변경 콜백
  final ValueChanged<int> onColorChanged;

  /// 확인(추가) 콜백
  final VoidCallback onConfirm;

  /// 취소 콜백
  final VoidCallback onCancel;

  const TagCreateInlineForm({
    super.key,
    required this.controller,
    required this.selectedColorIndex,
    required this.onColorChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: tc.overlayLight,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: tc.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 태그 이름 입력 필드
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: Tag.nameMaxLength,
            style: AppTypography.bodyLg.copyWith(color: tc.textPrimary),
            cursorColor: tc.textPrimary,
            decoration: InputDecoration(
              hintText: '태그 이름 (최대 ${Tag.nameMaxLength}자)',
              hintStyle: AppTypography.bodyLg.copyWith(
                color: tc.hintColor,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.mdLg),

          // 색상 선택 (8색 도트)
          TagColorDotPicker(
            selectedIndex: selectedColorIndex,
            onSelected: onColorChanged,
          ),
          const SizedBox(height: AppSpacing.mdLg),

          // 확인/취소 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // WCAG 2.1 터치 타겟 44px 이상 확보
              GestureDetector(
                onTap: onCancel,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: AppLayout.minTouchTarget,
                    minHeight: AppLayout.minTouchTarget,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '취소',
                    style: AppTypography.captionLg.copyWith(
                      color: tc.textPrimaryWithAlpha(0.55),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              GestureDetector(
                onTap: onConfirm,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: AppLayout.minTouchTarget,
                    minHeight: AppLayout.minTouchTarget,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '추가',
                    style: AppTypography.captionLg.copyWith(
                      // WCAG 대비: 글래스 배경 위에서 테마 텍스트 색상으로 고대비 확보
                      color: context.themeColors.textPrimaryWithAlpha(0.85),
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
