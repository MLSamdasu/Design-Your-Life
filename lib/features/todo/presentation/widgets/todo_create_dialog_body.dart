// F3 위젯: TodoCreateDialogBody - 투두 생성 다이얼로그 폼 본문
// 제목, 날짜, 시간, 색상, 태그, 메모, 저장 버튼을 포함하는 폼 Column이다.
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/tag_chip_selector.dart';
import 'todo_date_picker_row.dart';
import 'todo_form_fields.dart';
import 'todo_time_picker.dart';

/// 투두 생성/수정 다이얼로그의 폼 본문 위젯
/// Glass 모달 내부의 스크롤 가능한 폼 영역을 구성한다
class TodoCreateDialogBody extends StatelessWidget {
  final String headerTitle;
  final VoidCallback onClose;
  final TextEditingController titleController;
  final TextEditingController memoController;
  final GlobalKey<FormState> formKey;
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final bool hasTime;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<bool> onTimeToggled;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;
  final ValueChanged<int> onQuickDuration;
  final int selectedColorIndex;
  final ValueChanged<int> onColorSelected;
  final Set<String> selectedTagIds;
  final ValueChanged<Set<String>> onTagsChanged;
  final String submitLabel;
  final VoidCallback onSubmit;

  const TodoCreateDialogBody({
    required this.headerTitle,
    required this.onClose,
    required this.titleController,
    required this.memoController,
    required this.formKey,
    required this.selectedDate,
    required this.onPickDate,
    required this.hasTime,
    required this.startTime,
    required this.endTime,
    required this.onTimeToggled,
    required this.onPickStartTime,
    required this.onPickEndTime,
    required this.onQuickDuration,
    required this.selectedColorIndex,
    required this.onColorSelected,
    required this.selectedTagIds,
    required this.onTagsChanged,
    required this.submitLabel,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: mq.size.width >= AppLayout.responsiveBreakpointSm
                ? AppLayout.dialogMaxWidthLg
                : AppLayout.dialogMaxWidthSm,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xxl,
              right: AppSpacing.xxl,
              bottom: mq.viewInsets.bottom + AppSpacing.xxl,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: GlassDecoration.elevatedBlurSigma,
                  sigmaY: GlassDecoration.elevatedBlurSigma,
                ),
                child: Container(
                  decoration: GlassDecoration.modal(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TodoDialogHeader(title: headerTitle, onClose: onClose),
                          const SizedBox(height: AppSpacing.xxl),
                          // 제목 입력
                          TodoGlassTextField(
                            controller: titleController,
                            hintText: '할 일을 입력해주세요',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return '제목을 입력해주세요';
                              if (v.trim().length > 200) return '200자 이내로 입력해주세요';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TodoDatePickerRow(selectedDate: selectedDate, onTap: onPickDate),
                          const SizedBox(height: AppSpacing.xl),
                          TodoTimeRangeSection(
                            hasTime: hasTime,
                            startTime: startTime,
                            endTime: endTime,
                            onToggled: onTimeToggled,
                            onPickStartTime: onPickStartTime,
                            onPickEndTime: onPickEndTime,
                            onQuickDuration: onQuickDuration,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TodoColorSection(
                            selectedIndex: selectedColorIndex,
                            onSelected: onColorSelected,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TagChipSelector(
                            selectedTagIds: selectedTagIds,
                            onChanged: onTagsChanged,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          TodoGlassTextField(
                            controller: memoController,
                            hintText: '메모 (선택)',
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          TodoPrimaryButton(label: submitLabel, onTap: onSubmit),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
