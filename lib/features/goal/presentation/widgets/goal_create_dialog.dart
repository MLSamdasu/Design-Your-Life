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
import '../../providers/goal_provider.dart';
import 'goal_create_form_fields.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 목표 생성 다이얼로그 (Glass 모달 스타일)
/// AN-06: Scale(0.9->1) + Fade 애니메이션으로 표시된다
class GoalCreateDialog extends ConsumerStatefulWidget {
  /// 기본 선택 기간 (목표 리스트의 현재 탭에 맞춰 설정)
  final GoalPeriod defaultPeriod;

  /// 기본 연도
  final int defaultYear;

  const GoalCreateDialog({
    this.defaultPeriod = GoalPeriod.yearly,
    required this.defaultYear,
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

  @override
  void initState() {
    super.initState();
    _period = widget.defaultPeriod;
    _year = widget.defaultYear;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// 목표 저장 처리
  /// 폼 유효성 검사 후 서버에 목표를 저장한다
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final goal = Goal(
      id: '',
      userId: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      period: _period,
      year: _year,
      month: _period == GoalPeriod.monthly ? _month : null,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    final goalId =
        await ref.read(goalNotifierProvider.notifier).createGoal(goal);

    if (!mounted) return;
    if (goalId != null) {
      Navigator.of(context).pop(goalId);
    } else {
      setState(() => _isSubmitting = false);
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
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              decoration: GlassDecoration.modal(),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 다이얼로그 제목
                    Text(
                      '새 목표 추가',
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
                    const SizedBox(height: AppSpacing.xxxl),

                    // 버튼 행 (취소 / 추가)
                    _DialogActionButtons(
                      isSubmitting: _isSubmitting,
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
    );
  }
}

// ─── 다이얼로그 액션 버튼 ─────────────────────────────────────────────────

/// 다이얼로그 하단 버튼 행 (취소 / 추가)
class _DialogActionButtons extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _DialogActionButtons({
    required this.isSubmitting,
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
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgXl),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '추가',
                    style: AppTypography.titleMd.copyWith(
                      // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
