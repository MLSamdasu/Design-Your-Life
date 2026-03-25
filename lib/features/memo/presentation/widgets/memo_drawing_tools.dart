// F-Memo: 드로잉 전용 도구 바
// 펜 색상, 두께, 지우개, 되돌리기, 전체 지우기 버튼을 제공한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 드로잉 툴바에서 사용할 펜 색상 목록
const kPenColors = [
  ColorTokens.gray900,
  ColorTokens.error,
  ColorTokens.info,
  ColorTokens.success,
  ColorTokens.warning,
];

/// 드로잉 툴바에서 사용할 펜 두께 목록
const kPenThicknesses = [1.5, 3.0, 5.0];

/// 드로잉 도구 바 위젯
/// 색상 선택 + 두께 선택 + 지우개/되돌리기/전체 지우기 도구를 표시한다
class MemoDrawingTools extends StatelessWidget {
  /// 현재 선택된 펜 색상 인덱스
  final int selectedColorIndex;

  /// 펜 색상 변경 콜백
  final ValueChanged<int> onColorChanged;

  /// 현재 선택된 펜 두께 인덱스
  final int selectedThicknessIndex;

  /// 펜 두께 변경 콜백
  final ValueChanged<int> onThicknessChanged;

  /// 지우개 모드 여부
  final bool isEraser;

  /// 지우개 토글 콜백
  final VoidCallback onEraserToggle;

  /// 되돌리기 콜백
  final VoidCallback? onUndo;

  /// 전체 지우기 콜백
  final VoidCallback? onClear;

  const MemoDrawingTools({
    super.key,
    this.selectedColorIndex = 0,
    required this.onColorChanged,
    this.selectedThicknessIndex = 0,
    required this.onThicknessChanged,
    this.isEraser = false,
    required this.onEraserToggle,
    this.onUndo,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return Row(
      children: [
        // 펜 색상 선택
        ..._buildColorButtons(tc),
        const SizedBox(width: AppSpacing.lg),
        // 구분선
        Container(
          width: AppLayout.borderThin,
          height: AppLayout.containerMd,
          color: tc.dividerColor,
        ),
        const SizedBox(width: AppSpacing.lg),
        // 펜 두께 선택
        ..._buildThicknessButtons(tc),
        const Spacer(),
        // 지우개 토글
        _buildToolButton(
          icon: Icons.auto_fix_normal,
          isActive: isEraser,
          onTap: onEraserToggle,
          tc: tc,
        ),
        const SizedBox(width: AppSpacing.xs),
        // 되돌리기
        _buildToolButton(
          icon: Icons.undo,
          isActive: false,
          onTap: onUndo,
          tc: tc,
        ),
        const SizedBox(width: AppSpacing.xs),
        // 전체 지우기
        _buildToolButton(
          icon: Icons.delete_sweep_outlined,
          isActive: false,
          onTap: onClear,
          tc: tc,
        ),
      ],
    );
  }

  /// 펜 색상 버튼 리스트
  List<Widget> _buildColorButtons(ResolvedThemeColors tc) {
    return List.generate(kPenColors.length, (i) {
      final isActive = !isEraser && selectedColorIndex == i;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: GestureDetector(
          onTap: () => onColorChanged(i),
          child: Container(
            width: AppLayout.checkboxMd,
            height: AppLayout.checkboxMd,
            decoration: BoxDecoration(
              color: kPenColors[i],
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(
                      color: tc.accent,
                      width: AppLayout.borderAccent,
                    )
                  : null,
            ),
          ),
        ),
      );
    });
  }

  /// 펜 두께 버튼 리스트
  List<Widget> _buildThicknessButtons(ResolvedThemeColors tc) {
    return List.generate(kPenThicknesses.length, (i) {
      final isActive = selectedThicknessIndex == i;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: GestureDetector(
          onTap: () => onThicknessChanged(i),
          child: Container(
            width: AppLayout.minButtonSize,
            height: AppLayout.minButtonSize,
            decoration: BoxDecoration(
              color: isActive
                  ? tc.accentWithAlpha(0.15)
                  : ColorTokens.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Container(
                width: kPenThicknesses[i] * 2 + 4,
                height: kPenThicknesses[i] * 2 + 4,
                decoration: BoxDecoration(
                  color: tc.textPrimaryWithAlpha(0.70),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// 도구 아이콘 버튼 (지우개, 되돌리기, 전체 지우기)
  Widget _buildToolButton({
    required IconData icon,
    required bool isActive,
    VoidCallback? onTap,
    required ResolvedThemeColors tc,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppLayout.containerMd,
        height: AppLayout.containerMd,
        decoration: BoxDecoration(
          color: isActive
              ? tc.accentWithAlpha(0.15)
              : ColorTokens.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          icon,
          size: AppLayout.iconMd,
          color: isDisabled
              ? tc.textPrimaryWithAlpha(0.30)
              : isActive
                  ? tc.accent
                  : tc.textPrimaryWithAlpha(0.65),
        ),
      ),
    );
  }
}
