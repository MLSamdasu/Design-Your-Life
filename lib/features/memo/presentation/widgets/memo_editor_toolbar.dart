// F-Memo: 메모 에디터 툴바
// 텍스트 모드 / 그리기 모드 전환 토글을 제공한다.
// 그리기 모드에서는 MemoDrawingTools에 위임한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import 'memo_drawing_tools.dart';

// 하위 호환을 위한 배럴 re-export
export 'memo_drawing_tools.dart';

/// 메모 에디터 상단 툴바
/// 텍스트/드로잉 모드 전환 + 드로잉 도구 표시
class MemoEditorToolbar extends StatelessWidget {
  /// 현재 메모 타입 ('text' 또는 'drawing')
  final String currentType;

  /// 모드 변경 콜백
  final ValueChanged<String> onTypeChanged;

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

  const MemoEditorToolbar({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tc.overlayLight,
        border: Border(
          bottom: BorderSide(
            color: tc.dividerColor,
            width: AppLayout.borderThin,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 모드 전환 토글
          _buildModeToggle(tc),
          // 드로잉 모드일 때 추가 도구 표시
          if (currentType == 'drawing') ...[
            const SizedBox(height: AppSpacing.md),
            MemoDrawingTools(
              selectedColorIndex: selectedColorIndex,
              onColorChanged: onColorChanged,
              selectedThicknessIndex: selectedThicknessIndex,
              onThicknessChanged: onThicknessChanged,
              isEraser: isEraser,
              onEraserToggle: onEraserToggle,
              onUndo: onUndo,
              onClear: onClear,
            ),
          ],
        ],
      ),
    );
  }

  /// 텍스트/드로잉 모드 전환 토글
  Widget _buildModeToggle(ResolvedThemeColors tc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeButton(
          icon: Icons.edit_note,
          label: '텍스트',
          isActive: currentType == 'text',
          onTap: () => onTypeChanged('text'),
          tc: tc,
        ),
        const SizedBox(width: AppSpacing.md),
        _buildModeButton(
          icon: Icons.draw_outlined,
          label: '드로잉',
          isActive: currentType == 'drawing',
          onTap: () => onTypeChanged('drawing'),
          tc: tc,
        ),
      ],
    );
  }

  /// 모드 선택 버튼
  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ResolvedThemeColors tc,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive ? tc.accentWithAlpha(0.15) : ColorTokens.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isActive ? tc.accent : tc.borderLight,
            width: AppLayout.borderThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppLayout.iconMd,
              color: isActive ? tc.accent : tc.textPrimaryWithAlpha(0.60),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.captionLg.copyWith(
                color: isActive ? tc.accent : tc.textPrimaryWithAlpha(0.60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
