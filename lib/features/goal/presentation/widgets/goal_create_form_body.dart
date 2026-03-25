// F5 위젯: GoalCreateFormBody - 목표 생성 다이얼로그 폼 본문
// 제목, 설명, 기간, 연도/월, 태그, 체크포인트, 액션 버튼을 배치한다.
// SRP 분리: goal_create_dialog.dart에서 폼 본문 레이아웃을 추출
import 'package:flutter/material.dart';

import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../../../shared/widgets/tag_chip_selector.dart';
import 'goal_create_form_fields.dart';
import 'goal_dialog_action_buttons.dart';
import 'goal_checkpoint_input_section.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 목표 생성/수정 다이얼로그의 폼 본문 위젯
/// Glass 모달 내부에 배치되는 폼 필드와 버튼을 구성한다
class GoalCreateFormBody extends StatelessWidget {
  /// 폼 유효성 검사 키
  final GlobalKey<FormState> formKey;

  /// 수정 모드 여부
  final bool isEditMode;

  /// 현재 선택된 기간
  final GoalPeriod period;

  /// 기간 변경 콜백
  final ValueChanged<GoalPeriod> onPeriodChanged;

  /// 현재 선택된 연도
  final int year;

  /// 연도 변경 콜백
  final ValueChanged<int> onYearChanged;

  /// 현재 선택된 월
  final int month;

  /// 월 변경 콜백
  final ValueChanged<int> onMonthChanged;

  /// 제목 입력 컨트롤러
  final TextEditingController titleController;

  /// 설명 입력 컨트롤러
  final TextEditingController descController;

  /// 선택된 태그 ID 집합
  final Set<String> selectedTagIds;

  /// 태그 변경 콜백
  final ValueChanged<Set<String>> onTagsChanged;

  /// 체크포인트 입력 컨트롤러 목록
  final List<TextEditingController> checkpointControllers;

  /// 체크포인트 추가 콜백
  final VoidCallback onCheckpointAdd;

  /// 체크포인트 삭제 콜백
  final void Function(int) onCheckpointRemove;

  /// 제출 중 여부
  final bool isSubmitting;

  /// 취소 콜백
  final VoidCallback onCancel;

  /// 제출 콜백
  final VoidCallback onSubmit;

  const GoalCreateFormBody({
    super.key,
    required this.formKey,
    required this.isEditMode,
    required this.period,
    required this.onPeriodChanged,
    required this.year,
    required this.onYearChanged,
    required this.month,
    required this.onMonthChanged,
    required this.titleController,
    required this.descController,
    required this.selectedTagIds,
    required this.onTagsChanged,
    required this.checkpointControllers,
    required this.onCheckpointAdd,
    required this.onCheckpointRemove,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 다이얼로그 제목 (수정/생성 모드 구분)
          Text(
            isEditMode ? '목표 수정' : '새 목표 추가',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // 기간 선택 탭 (goal_create_form_fields.dart)
          PeriodSelector(
            selected: period,
            onChanged: onPeriodChanged,
          ),
          const SizedBox(height: AppSpacing.xl),

          // 연도/월 선택 (goal_create_form_fields.dart)
          YearMonthSelector(
            period: period,
            year: year,
            month: month,
            onYearChanged: onYearChanged,
            onMonthChanged: onMonthChanged,
          ),
          const SizedBox(height: AppSpacing.xl),

          // 목표 제목 입력 (goal_create_form_fields.dart)
          GlassTextFormField(
            controller: titleController,
            hintText: '목표 제목을 입력해주세요',
            maxLength: 200,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return '목표 제목을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // 목표 설명 입력 (선택, goal_create_form_fields.dart)
          GlassTextFormField(
            controller: descController,
            hintText: '설명을 입력해주세요 (선택)',
            maxLength: 1000,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),

          // 태그 선택 (TagChipSelector 공용 위젯 재사용)
          TagChipSelector(
            selectedTagIds: selectedTagIds,
            onChanged: onTagsChanged,
          ),
          const SizedBox(height: AppSpacing.xl),

          // 체크포인트 입력 섹션 (선택, 생성 모드에서만 표시)
          if (!isEditMode)
            GoalCheckpointInputSection(
              controllers: checkpointControllers,
              onAdd: onCheckpointAdd,
              onRemove: onCheckpointRemove,
            ),
          const SizedBox(height: AppSpacing.xxxl),

          // 버튼 행 (취소 / 추가 또는 저장)
          GoalDialogActionButtons(
            isSubmitting: isSubmitting,
            submitLabel: isEditMode ? '저장' : '추가',
            onCancel: onCancel,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}
