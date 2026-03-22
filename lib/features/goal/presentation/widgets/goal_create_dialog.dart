// F5 위젯: GoalCreateDialog - 목표 생성 다이얼로그
// 목표 이름(필수), 설명(선택), 기간(년간/월간), 연도, 월(월간일 때)을 입력받는다.
// SRP 분리: 폼 필드 위젯 → goal_create_form_fields.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../../../shared/widgets/tag_chip_selector.dart';
import '../../providers/goal_provider.dart';
import 'goal_create_form_fields.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// 목표 생성/수정 다이얼로그 (Glass 모달 스타일)
/// AN-06: Scale(0.9->1) + Fade 애니메이션으로 표시된다
/// existingGoal이 전달되면 수정 모드로 동작한다
class GoalCreateDialog extends ConsumerStatefulWidget {
  /// 기본 선택 기간 (목표 리스트의 현재 탭에 맞춰 설정)
  final GoalPeriod defaultPeriod;

  /// 기본 연도
  final int defaultYear;

  /// 수정 모드일 때 기존 목표 데이터
  final Goal? existingGoal;

  const GoalCreateDialog({
    this.defaultPeriod = GoalPeriod.yearly,
    required this.defaultYear,
    this.existingGoal,
    super.key,
  });

  @override
  ConsumerState<GoalCreateDialog> createState() => _GoalCreateDialogState();
}

class _GoalCreateDialogState extends ConsumerState<GoalCreateDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late GoalPeriod _period;
  late int _year;
  int _month = DateTime.now().month;
  bool _isSubmitting = false;

  /// 선택된 태그 ID 집합 (태그 시스템)
  Set<String> _selectedTagIds = {};

  /// 체크포인트 입력 컨트롤러 목록
  final List<TextEditingController> _checkpointControllers = [];

  /// 수정 모드 여부
  bool get _isEditMode => widget.existingGoal != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGoal;
    if (existing != null) {
      // 수정 모드: 기존 데이터로 폼 필드를 채운다
      _titleController.text = existing.title;
      _descController.text = existing.description ?? '';
      _period = existing.period;
      _year = existing.year;
      _month = existing.month ?? DateTime.now().month;
      _selectedTagIds = existing.tagIds.toSet();
    } else {
      _period = widget.defaultPeriod;
      _year = widget.defaultYear;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final c in _checkpointControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// 목표 저장 처리
  /// 폼 유효성 검사 후 로컬 Hive에 목표를 저장한다
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final errorMsg = _isEditMode ? '목표 수정에 실패했습니다' : '목표 추가에 실패했습니다';

    try {
      final now = DateTime.now();
      final existing = widget.existingGoal;
      final goal = Goal(
        id: existing?.id ?? '',
        userId: existing?.userId ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        period: _period,
        year: _year,
        month: _period == GoalPeriod.monthly ? _month : null,
        isCompleted: existing?.isCompleted ?? false,
        tagIds: _selectedTagIds.toList(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditMode) {
        // 수정 모드: 기존 목표를 갱신한다
        await ref
            .read(goalNotifierProvider.notifier)
            .updateGoal(existing!.id, goal);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        // 생성 모드: 목표 + 체크포인트를 원자적으로 생성한다
        // state 변경과 버전 갱신을 한 번만 수행하여 크래시를 방지한다
        final checkpointTitles = <String>[];
        for (final c in _checkpointControllers) {
          final title = c.text.trim();
          if (title.isNotEmpty) checkpointTitles.add(title);
        }
        final goalId = await ref
            .read(goalNotifierProvider.notifier)
            .createGoalWithCheckpoints(goal, checkpointTitles);
        if (!mounted) return;
        if (goalId != null) {
          Navigator.of(context).pop(goalId);
        } else {
          setState(() => _isSubmitting = false);
          AppSnackBar.showError(context, errorMsg);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackBar.showError(context, errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.dialogMaxWidthLg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassDecoration.elevatedBlurSigma,
              sigmaY: GlassDecoration.elevatedBlurSigma,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
              decoration: GlassDecoration.modal(),
              // 태그 섹션 추가로 콘텐츠가 길어질 수 있으므로
              // SingleChildScrollView로 오버플로우를 방지한다
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 다이얼로그 제목 (수정/생성 모드 구분)
                    Text(
                      _isEditMode ? '목표 수정' : '새 목표 추가',
                      style: AppTypography.titleMd.copyWith(
                    color: context.themeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 기간 선택 탭 (goal_create_form_fields.dart)
                    PeriodSelector(
                      selected: _period,
                      onChanged: (p) => setState(() => _period = p),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 연도/월 선택 (goal_create_form_fields.dart)
                    YearMonthSelector(
                      period: _period,
                      year: _year,
                      month: _month,
                      onYearChanged: (y) => setState(() => _year = y),
                      onMonthChanged: (m) => setState(() => _month = m),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 목표 제목 입력 (goal_create_form_fields.dart)
                    GlassTextFormField(
                      controller: _titleController,
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
                      controller: _descController,
                      hintText: '설명을 입력해주세요 (선택)',
                      maxLength: 1000,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 태그 선택 (TagChipSelector 공용 위젯 재사용)
                    TagChipSelector(
                      selectedTagIds: _selectedTagIds,
                      onChanged: (tagIds) =>
                          setState(() => _selectedTagIds = tagIds),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // 체크포인트 입력 섹션 (선택, 생성 모드에서만 표시)
                    if (!_isEditMode)
                      _CheckpointInputSection(
                        controllers: _checkpointControllers,
                        onAdd: () => setState(() {
                          _checkpointControllers.add(TextEditingController());
                        }),
                        onRemove: (index) => setState(() {
                          _checkpointControllers[index].dispose();
                          _checkpointControllers.removeAt(index);
                        }),
                      ),
                    const SizedBox(height: AppSpacing.xxxl),

                    // 버튼 행 (취소 / 추가 또는 저장)
                    _DialogActionButtons(
                      isSubmitting: _isSubmitting,
                      submitLabel: _isEditMode ? '저장' : '추가',
                      onCancel: () => Navigator.of(context).pop(),
                      onSubmit: _submit,
                    ),
                  ],
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

// ─── 다이얼로그 액션 버튼 ─────────────────────────────────────────────────

/// 다이얼로그 하단 버튼 행 (취소 / 추가 또는 저장)
class _DialogActionButtons extends StatelessWidget {
  final bool isSubmitting;
  final String submitLabel;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _DialogActionButtons({
    required this.isSubmitting,
    this.submitLabel = '추가',
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 취소 버튼
        Expanded(
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
              foregroundColor: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
            child: Text(
              '취소',
              style: AppTypography.titleMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // 추가 버튼 (로딩 중 비활성화)
        Expanded(
          child: ElevatedButton(
            onPressed: isSubmitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.main,
              foregroundColor: ColorTokens.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              elevation: AppLayout.elevationNone,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: AppLayout.iconMd,
                    height: AppLayout.iconMd,
                    child: CircularProgressIndicator(
                      strokeWidth: AppLayout.spinnerStrokeWidth,
                      // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                      color: ColorTokens.white,
                    ),
                  )
                : Text(
                    submitLabel,
                    style: AppTypography.titleMd.copyWith(
                      // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                      color: ColorTokens.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── 체크포인트 입력 섹션 ─────────────────────────────────────────────────

/// 목표 생성 시 체크포인트(중간 단계) 입력 섹션
/// 각 체크포인트는 SubGoal로 저장되어 진행률 자동 계산에 사용된다
class _CheckpointInputSection extends StatelessWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _CheckpointInputSection({
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Text(
          '체크포인트 (선택)',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '목표 달성 과정의 중간 단계를 추가하세요',
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.4),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // 체크포인트 목록
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                // 순번 뱃지
                Container(
                  width: AppLayout.badgeSm,
                  height: AppLayout.badgeSm,
                  decoration: BoxDecoration(
                    color: context.themeColors.accentWithAlpha(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTypography.captionSm.copyWith(
                        // WCAG 대비: accent 배경 위에서 테마 텍스트 색상으로 고대비 확보
                        color: context.themeColors.textPrimaryWithAlpha(0.85),
                        fontWeight: AppTypography.weightSemiBold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // 입력 필드
                Expanded(
                  child: GlassTextFormField(
                    controller: controllers[index],
                    hintText: '체크포인트 ${index + 1}',
                    maxLength: 200,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // 삭제 버튼
                GestureDetector(
                  onTap: () => onRemove(index),
                  child: SizedBox(
                    width: AppLayout.minTouchTarget,
                    height: AppLayout.minTouchTarget,
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: AppLayout.iconMd,
                        color: context.themeColors.textPrimaryWithAlpha(0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        // 추가 버튼
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: context.themeColors.textPrimaryWithAlpha(0.2),
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: AppLayout.iconMd,
                  color: context.themeColors.accentWithAlpha(0.7),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '체크포인트 추가',
                  style: AppTypography.bodyMd.copyWith(
                    color: context.themeColors.accentWithAlpha(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
