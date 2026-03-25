// F7-W3: 드로잉 도구 모음 위젯
// 펜 두께, 색상, 지우개 모드, Undo, 전체 삭제 기능을 제공한다.
// 캔버스 하단에 컴팩트한 수평 바 형태로 배치된다.
// 입력: 현재 펜 설정 상태 / 출력: 각 속성 변경 콜백
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import 'drawing_tool_button.dart';

/// 드로잉 도구 모음 (캔버스 하단 수평 바)
/// 펜 두께 3단계, 색상 8종, 지우개, Undo, Clear 기능을 제공한다
class DrawingToolbar extends StatelessWidget {
  /// 현재 선택된 펜 색상
  final Color selectedColor;

  /// 현재 선택된 펜 두께
  final double selectedWidth;

  /// 지우개 모드 활성화 여부
  final bool isErasing;

  /// 펜 색상 변경 콜백
  final ValueChanged<Color> onColorChanged;

  /// 펜 두께 변경 콜백
  final ValueChanged<double> onWidthChanged;

  /// 지우개 모드 토글 콜백
  final VoidCallback onEraserToggle;

  /// 마지막 스트로크 삭제 콜백
  final VoidCallback onUndo;

  /// 전체 스트로크 삭제 콜백
  final VoidCallback onClearAll;

  const DrawingToolbar({
    super.key,
    required this.selectedColor,
    required this.selectedWidth,
    required this.isErasing,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onEraserToggle,
    required this.onUndo,
    required this.onClearAll,
  });

  /// 프리셋 펜 두께 목록 (가는/중간/굵은)
  static const _widths = [2.0, 4.0, 8.0];

  /// 프리셋 색상 목록 (8종)
  static const _colors = [
    Color(0xFF000000), // 검정
    Color(0xFFE53935), // 빨강
    Color(0xFF1E88E5), // 파랑
    Color(0xFF43A047), // 초록
    Color(0xFFFB8C00), // 주황
    Color(0xFF8E24AA), // 보라
    Color(0xFF6D4C41), // 갈색
    Color(0xFF757575), // 회색
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.themeColors.overlayLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.shadowBase,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 펜 두께 선택 버튼 그룹
            ..._buildWidthButtons(),
            const SizedBox(width: AppSpacing.sm),
            // 색상 팔레트 (수평 스크롤)
            Expanded(child: _buildColorPalette()),
            const SizedBox(width: AppSpacing.sm),
            // 도구 버튼 (지우개, Undo, Clear)
            ..._buildToolButtons(context),
          ],
        ),
      ),
    );
  }

  /// 펜 두께 선택 버튼을 생성한다
  List<Widget> _buildWidthButtons() {
    return _widths.map((w) {
      final isSelected = (selectedWidth - w).abs() < 0.1 && !isErasing;
      return GestureDetector(
        onTap: () => onWidthChanged(w),
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: AppSpacing.xxs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: selectedColor, width: 2)
                : null,
          ),
          child: Center(
            child: Container(
              width: w + 2,
              height: w + 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? selectedColor : ColorTokens.gray400,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// 색상 팔레트를 생성한다
  Widget _buildColorPalette() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _colors.map((color) {
          final isSelected =
              selectedColor.toARGB32() == color.toARGB32() && !isErasing;
          return GestureDetector(
            onTap: () => onColorChanged(color),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: ColorTokens.white, width: 2.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 도구 버튼 (지우개, Undo, Clear)을 생성한다
  List<Widget> _buildToolButtons(BuildContext context) {
    return [
      // 지우개 토글
      DrawingToolButton(
        icon: Icons.auto_fix_high_rounded,
        isActive: isErasing,
        onTap: onEraserToggle,
        tooltip: '지우개',
      ),
      // Undo
      DrawingToolButton(
        icon: Icons.undo_rounded,
        isActive: false,
        onTap: onUndo,
        tooltip: '되돌리기',
      ),
      // 전체 삭제
      DrawingToolButton(
        icon: Icons.delete_outline_rounded,
        isActive: false,
        onTap: () => showClearConfirmDialog(context, onClearAll),
        tooltip: '전체 삭제',
      ),
    ];
  }
}
