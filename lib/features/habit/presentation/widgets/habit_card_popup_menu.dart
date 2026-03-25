// F4 위젯: HabitCardPopupMenu - 습관 카드 팝업 메뉴
// 길게 누르면 표시되는 수정/삭제 메뉴를 제공한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 습관 카드 팝업 메뉴 표시
/// 카드를 길게 눌렀을 때 수정/삭제 옵션을 보여준다.
Future<void> showHabitCardPopupMenu({
  required BuildContext context,
  required VoidCallback? onEdit,
  required VoidCallback? onDelete,
}) async {
  // findRenderObject가 null일 수 있으므로 안전하게 캐스팅한다
  final renderBox = context.findRenderObject() as RenderBox?;
  if (renderBox == null) return;
  final Offset offset = renderBox.localToGlobal(Offset.zero);
  final Size size = renderBox.size;

  final value = await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(
      offset.dx + size.width - MiscLayout.popupMenuOffsetLeft,
      offset.dy + size.height,
      offset.dx + size.width,
      offset.dy + size.height + MiscLayout.popupMenuOffsetBottom,
    ),
    color: context.themeColors.dialogSurface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    items: [
      PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            Icon(
              Icons.edit_rounded,
              size: AppLayout.iconSm,
              color: context.themeColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '수정',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: AppLayout.iconSm,
              color: ColorTokens.error,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '삭제',
              style: AppTypography.bodyMd.copyWith(
                color: ColorTokens.error,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  if (value == 'edit') onEdit?.call();
  if (value == 'delete') onDelete?.call();
}
