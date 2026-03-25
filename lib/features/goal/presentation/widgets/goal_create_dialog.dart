// F5 위젯: GoalCreateDialog - 목표 생성/수정 다이얼로그 (Glass 모달 셸)
// SRP 분리: form_fields / action_buttons / checkpoint_input / form_body
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/glassmorphism.dart';
import '../../../../shared/models/goal.dart';
import '../../../../shared/enums/goal_period.dart';
import '../../providers/goal_provider.dart';
import 'goal_create_form_body.dart';
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

  Set<String> _selectedTagIds = {}; // 선택된 태그 ID 집합
  final List<TextEditingController> _checkpointControllers = []; // 체크포인트 컨트롤러
  bool get _isEditMode => widget.existingGoal != null; // 수정 모드 여부

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

  /// 폼 유효성 검사 후 로컬 Hive에 목표를 저장한다
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final errorMsg =
        _isEditMode ? '목표 수정에 실패했습니다' : '목표 추가에 실패했습니다';
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
        constraints:
            const BoxConstraints(maxWidth: AppLayout.dialogMaxWidthLg),
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
                  child: GoalCreateFormBody(
                    formKey: _formKey,
                    isEditMode: _isEditMode,
                    period: _period,
                    onPeriodChanged: (p) => setState(() => _period = p),
                    year: _year,
                    onYearChanged: (y) => setState(() => _year = y),
                    month: _month,
                    onMonthChanged: (m) => setState(() => _month = m),
                    titleController: _titleController,
                    descController: _descController,
                    selectedTagIds: _selectedTagIds,
                    onTagsChanged: (tags) =>
                        setState(() => _selectedTagIds = tags),
                    checkpointControllers: _checkpointControllers,
                    onCheckpointAdd: () => setState(() {
                      _checkpointControllers.add(TextEditingController());
                    }),
                    onCheckpointRemove: (index) => setState(() {
                      _checkpointControllers[index].dispose();
                      _checkpointControllers.removeAt(index);
                    }),
                    isSubmitting: _isSubmitting,
                    onCancel: () => Navigator.of(context).pop(),
                    onSubmit: _submit,
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
