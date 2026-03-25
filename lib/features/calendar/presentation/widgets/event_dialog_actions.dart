// F2 위젯: EventDialogActions - 다이얼로그 하단 버튼 영역
// SRP 분리: 저장/취소/삭제 버튼 렌더링 + 삭제 확인 다이얼로그 표시
import 'package:flutter/material.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/glass_button.dart';

/// 일정 다이얼로그 하단 액션 버튼 영역
/// 편집 모드에서는 삭제/취소/저장 3버튼, 생성 모드에서는 취소/저장 2버튼
class EventDialogActions extends StatelessWidget {
  /// 편집 모드 여부 (true이면 삭제 버튼 표시)
  final bool isEditMode;

  /// 저장 중 상태 (true이면 버튼 비활성화 + '저장 중...' 표시)
  final bool isSaving;

  /// 저장 버튼 탭 시 호출
  final VoidCallback onSave;

  /// 취소 버튼 탭 시 호출
  final VoidCallback onCancel;

  /// 삭제 버튼 탭 시 호출 (편집 모드 전용)
  final VoidCallback? onDelete;

  const EventDialogActions({
    super.key,
    required this.isEditMode,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 편집 모드에서만 삭제 버튼을 표시한다 (Expanded로 균등 분배)
        if (isEditMode) ...[
          Expanded(
            child: GlassButton(
              label: '삭제',
              variant: GlassButtonVariant.ghost,
              onTap: isSaving ? null : onDelete,
              leadingIcon: Icons.delete_outline_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
        Expanded(
          child: GlassButton(
            label: '취소',
            variant: GlassButtonVariant.ghost,
            onTap: onCancel,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: GlassButton(
            label: isSaving ? '저장 중...' : '저장',
            variant: GlassButtonVariant.primary,
            onTap: isSaving ? null : onSave,
          ),
        ),
      ],
    );
  }
}

/// 이벤트 삭제 확인 다이얼로그를 표시하는 헬퍼 함수
/// 사용자가 삭제를 확인하면 true, 취소하면 false를 반환한다
Future<bool> showDeleteEventConfirmDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.themeColors.dialogSurface,
      title: Text(
        '일정 삭제',
        style: AppTypography.titleMd.copyWith(
          color: context.themeColors.textPrimary,
        ),
      ),
      content: Text(
        '이 일정을 삭제하시겠습니까?',
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
