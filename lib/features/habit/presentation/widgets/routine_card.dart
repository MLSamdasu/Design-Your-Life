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
import '../../../../shared/widgets/animated_strikethrough.dart';

/// 루틴 카드 위젯
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

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDays(List<int> days) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final sorted = List<int>.from(days)..sort();
    return sorted.map((d) => labels[(d - 1).clamp(0, AppLayout.daysInWeek - 1)]).join('');
  }

  /// 루틴 삭제 확인 다이얼로그를 표시한다 (P1-17)
  /// 사용자가 '삭제'를 선택하면 true를 반환하여 Dismissible 삭제를 허용한다
  Future<bool> _showDeleteConfirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        title: Text(
          '루틴 삭제',
          style: AppTypography.titleMd.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        content: Text(
          '이 루틴을 삭제하시겠습니까?',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '취소',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '삭제',
              style: AppTypography.bodyMd.copyWith(
                color: ColorTokens.error,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.eventColor(routine.colorIndex);
    return Dismissible(
      key: Key('routine_${routine.id}'),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(),
      // 스와이프 삭제 시 확인 다이얼로그를 표시한다 (P1-17)
      confirmDismiss: (_) => _showDeleteConfirm(context),
      onDismissed: (_) => onDelete?.call(),
      child: GestureDetector(
        onLongPress: () {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset offset = renderBox.localToGlobal(Offset.zero);
          final Size size = renderBox.size;
          showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              offset.dx + size.width - AppLayout.popupMenuOffsetLeft,
              offset.dy + size.height,
              offset.dx + size.width,
              offset.dy + size.height + AppLayout.popupMenuOffsetBottom,
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
                    Icon(Icons.edit_rounded, size: AppLayout.iconMd, color: context.themeColors.textPrimary),
                    const SizedBox(width: AppSpacing.md),
                    Text('수정', style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: AppLayout.iconMd, color: ColorTokens.error),
                    const SizedBox(width: AppSpacing.md),
                    Text('삭제', style: AppTypography.bodyMd.copyWith(color: ColorTokens.error)),
                  ],
                ),
              ),
            ],
          ).then((value) async {
            if (value == 'edit') onEdit?.call();
            // 컨텍스트 메뉴 삭제도 확인 다이얼로그를 표시한다 (P1-17)
            if (value == 'delete' && context.mounted) {
              final confirmed = await _showDeleteConfirm(context);
              if (confirmed) onDelete?.call();
            }
          });
        },
        child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.mdLg),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lgXl),
        decoration: BoxDecoration(
          color: routine.isActive
              ? context.themeColors.textPrimaryWithAlpha(0.12)
              : context.themeColors.textPrimaryWithAlpha(0.06),
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: routine.isActive
                ? color.withValues(alpha: 0.35)
                : context.themeColors.textPrimaryWithAlpha(0.10),
          ),
        ),
        child: Row(
          children: [
            // 색상 인디케이터 바
            Container(
              width: AppLayout.colorBarWidth,
              height: AppLayout.minTouchTarget,
              decoration: BoxDecoration(
                color: routine.isActive ? color : color.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // 루틴 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 비활성 루틴은 빨간펜 취소선 애니메이션으로 상태를 표시한다
                  AnimatedStrikethrough(
                    text: routine.name,
                    style: AppTypography.bodyMd.copyWith(
                      // WCAG: 비활성 루틴명 알파 0.50 이상으로 가독성 보장
                      color: routine.isActive
                          ? context.themeColors.textPrimary
                          : context.themeColors.textPrimaryWithAlpha(0.50),
                    ),
                    isActive: !routine.isActive,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      // 요일 배지: 좁은 화면에서 축소 가능하도록 Flexible 사용
                      Flexible(
                        child: _DaysBadge(
                          label: _fmtDays(routine.repeatDays),
                          color: color,
                          isActive: routine.isActive,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // WCAG: 테마 인식 고대비 보정으로 어두운 배경에서도 가독성 보장
                      Icon(Icons.access_time_rounded,
                          size: AppLayout.iconXxs,
                          color: context.themeColors.textPrimaryWithAlpha(
                              routine.isActive ? 0.55 : 0.45)),
                      const SizedBox(width: AppSpacing.xxs),
                      // 좁은 화면에서 시간 텍스트 오버플로우 방지
                      Flexible(
                        child: Text(
                          '${_fmtTime(routine.startTime)} ~ ${_fmtTime(routine.endTime)}',
                          // WCAG: 테마 인식 고대비 보정으로 어두운 배경에서도 가독성 보장
                          style: AppTypography.captionMd.copyWith(
                            color: context.themeColors.textPrimaryWithAlpha(
                                routine.isActive ? 0.55 : 0.45),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 활성 토글 스위치
            Transform.scale(
              scale: AppLayout.switchScaleSmall,
              child: Switch(
                value: routine.isActive,
                onChanged: onToggleActive,
                // activeColor deprecated → activeThumbColor 사용
                activeThumbColor: color,
                activeTrackColor: color.withValues(alpha: 0.35),
                inactiveThumbColor: context.themeColors.textPrimaryWithAlpha(0.4),
                inactiveTrackColor: context.themeColors.textPrimaryWithAlpha(0.12),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// 삭제 스와이프 배경
class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: ColorTokens.error.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Icon(Icons.delete_rounded, color: context.themeColors.textPrimary, size: AppLayout.iconNav),
    );
  }
}

/// 요일 배지 위젯
class _DaysBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;

  const _DaysBadge({
    required this.label,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.2)
            : context.themeColors.textPrimaryWithAlpha(0.08),
        borderRadius: BorderRadius.circular(AppRadius.huge),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.4)
              : context.themeColors.textPrimaryWithAlpha(0.12),
        ),
      ),
      child: Text(
        label.isEmpty ? '없음' : label,
        style: AppTypography.captionMd.copyWith(
          // WCAG: 활성 배지도 textPrimary 사용하여 모든 테마에서 가독성 보장
          // 배지 배경이 이미 이벤트 색상(color)으로 색상 연관성을 표현하므로 텍스트는 기본 색상 사용
          color: isActive
              ? context.themeColors.textPrimary
              : context.themeColors.textPrimaryWithAlpha(0.50),
          fontWeight: AppTypography.weightSemiBold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
