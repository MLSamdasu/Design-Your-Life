// F7-W3a: 드로잉 도구 아이콘 버튼
// 지우개, Undo, Clear 등 도구 버튼의 공용 위젯이다.
// DrawingToolbar에서 분리하여 SRP를 준수한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';

/// 드로잉 도구 아이콘 버튼 (지우개, Undo, Clear 공용)
/// 활성 상태 시 악센트 색상 배경, 비활성 시 투명 배경
class DrawingToolButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const DrawingToolButton({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: AppSpacing.xxs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? context.themeColors.accent.withValues(alpha: 0.2)
                : ColorTokens.transparent,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? context.themeColors.accent
                : context.themeColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 전체 삭제 확인 다이얼로그를 표시한다
/// 확인 시 onClearAll 콜백을 호출한다
Future<void> showClearConfirmDialog(
  BuildContext context,
  VoidCallback onClearAll,
) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('전체 삭제'),
      content: const Text('모든 그림을 삭제할까요?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onClearAll();
          },
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}
