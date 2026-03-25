// F4 위젯: RoutineCard - 루틴 카드
// 루틴명 + 반복 요일 배지 + 시간 + 색상 인디케이터 + 활성/비활성 토글을 표시한다.
// Dismissible로 스와이프 삭제를 지원한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/routine.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'routine_card_body.dart';
import 'routine_card_delete_background.dart';
import 'routine_delete_confirm_dialog.dart';

/// 루틴 카드 위젯
/// Dismissible 스와이프 삭제 + 롱프레스 컨텍스트 메뉴를 제공한다.
class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onToggleActive;

  const RoutineCard({
    required this.routine,
    this.onDelete,
    this.onEdit,
    this.onToggleActive,
    super.key,
  });

  /// 시간을 HH:MM 형식으로 포맷한다
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// 반복 요일 리스트를 한글 요일 문자열로 변환한다
  String _fmtDays(List<int> days) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final sorted = List<int>.from(days)..sort();
    return sorted
        .map((d) => labels[(d - 1).clamp(0, AppLayout.daysInWeek - 1)])
        .join('');
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(routine.colorIndex);
    return Dismissible(
      key: Key('routine_${routine.id}'),
      direction: DismissDirection.endToStart,
      background: const RoutineCardDeleteBackground(),
      // 스와이프 삭제 시 확인 다이얼로그를 표시한다 (P1-17)
      confirmDismiss: (_) => showRoutineDeleteConfirmDialog(context),
      onDismissed: (_) => onDelete?.call(),
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: RoutineCardBody(
          routine: routine,
          color: color,
          daysLabel: _fmtDays(routine.repeatDays),
          timeLabel:
              '${_fmtTime(routine.startTime)} ~ ${_fmtTime(routine.endTime)}',
          onToggleActive: onToggleActive,
        ),
      ),
    );
  }

  /// 롱프레스 컨텍스트 메뉴(수정/삭제)를 표시한다
  void _showContextMenu(BuildContext context) {
    // findRenderObject가 null일 수 있으므로 안전하게 캐스팅한다
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    showMenu<String>(
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
              Icon(Icons.edit_rounded,
                  size: AppLayout.iconMd,
                  color: context.themeColors.textPrimary),
              const SizedBox(width: AppSpacing.md),
              Text('수정',
                  style: AppTypography.bodyMd
                      .copyWith(color: context.themeColors.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: AppLayout.iconMd, color: ColorTokens.error),
              const SizedBox(width: AppSpacing.md),
              Text('삭제',
                  style: AppTypography.bodyMd
                      .copyWith(color: ColorTokens.error)),
            ],
          ),
        ),
      ],
    ).then((value) async {
      // 팝업 닫힌 후 컨텍스트 유효성을 확인한다
      if (!context.mounted) return;
      if (value == 'edit') onEdit?.call();
      // 컨텍스트 메뉴 삭제도 확인 다이얼로그를 표시한다 (P1-17)
      if (value == 'delete' && context.mounted) {
        final confirmed = await showRoutineDeleteConfirmDialog(context);
        if (confirmed) onDelete?.call();
      }
    });
  }
}
