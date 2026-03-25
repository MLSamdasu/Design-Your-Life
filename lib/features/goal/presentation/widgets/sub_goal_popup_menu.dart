// F5 위젯: SubGoalPopupMenu - 하위 목표 팝업 메뉴
// 수정/삭제/실천과제 추가 액션을 제공하는 팝업 메뉴 버튼이다.
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 하위 목표 팝업 메뉴 콜백 타입
typedef SubGoalMenuCallback = Future<void> Function();

/// 하위 목표 수정/삭제/실천과제 추가 팝업 메뉴 버튼
class SubGoalPopupMenu extends StatelessWidget {
  /// 수정 메뉴 선택 시 호출되는 콜백
  final SubGoalMenuCallback onEdit;

  /// 삭제 메뉴 선택 시 호출되는 콜백
  final SubGoalMenuCallback onDelete;

  /// 실천과제 추가 메뉴 선택 시 호출되는 콜백
  final SubGoalMenuCallback onAddTask;

  const SubGoalPopupMenu({
    required this.onEdit,
    required this.onDelete,
    required this.onAddTask,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppLayout.iconXxl,
      height: AppLayout.iconXxl,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: AppLayout.iconSm,
        icon: Icon(
          Icons.more_vert_rounded,
          color: context.themeColors.textPrimaryWithAlpha(0.5),
          size: AppLayout.iconSm,
        ),
        color: context.themeColors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        // 각 액션이 Future<void>를 반환하므로 반드시 await 해야
        // Hive 쓰기 완료 전에 위젯이 언마운트되는 크래시를 방지한다
        onSelected: (value) async {
          if (value == 'edit') await onEdit();
          if (value == 'delete') await onDelete();
          if (value == 'addTask') await onAddTask();
        },
        itemBuilder: (context) => [
          _buildMenuItem(
            context,
            value: 'addTask',
            icon: Icons.add_rounded,
            label: '실천과제 추가',
          ),
          _buildMenuItem(
            context,
            value: 'edit',
            icon: Icons.edit_rounded,
            label: '수정',
          ),
          _buildMenuItem(
            context,
            value: 'delete',
            icon: Icons.delete_outline_rounded,
            label: '삭제',
            color: ColorTokens.error,
          ),
        ],
      ),
    );
  }

  /// 팝업 메뉴 아이템 하나를 생성한다
  PopupMenuItem<String> _buildMenuItem(
    BuildContext context, {
    required String value,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final itemColor = color ?? context.themeColors.textPrimary;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: AppLayout.iconSm, color: itemColor),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(color: itemColor),
          ),
        ],
      ),
    );
  }
}
