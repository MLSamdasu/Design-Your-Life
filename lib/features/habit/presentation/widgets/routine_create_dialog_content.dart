// F4 위젯: RoutineCreateDialog - 루틴 생성 다이얼로그
// 이름, 반복 요일(월~일 복수 선택), 시작/종료 시간, 색상을 입력받는다.
// AN-06: showGeneralDialog로 Scale+Fade 애니메이션 250ms 적용
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../shared/widgets/color_picker.dart';
import 'routine_form_widgets.dart';
import 'routine_create_result.dart';
import 'routine_dialog_helpers.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 루틴 생성/수정 다이얼로그
/// AN-06: Scale(0.9→1.0) + Fade 250ms easeOutCubic
class RoutineCreateDialog extends StatefulWidget {
  /// 수정 모드 시 기존 루틴 데이터 (폼 초기값으로 사용)
  final RoutineCreateResult? initialData;

  const RoutineCreateDialog({super.key, this.initialData});

  /// 다이얼로그를 표시하고 결과를 반환한다
  static Future<RoutineCreateResult?> show(
    BuildContext context, {
    RoutineCreateResult? initialData,
  }) {
    return showGeneralDialog<RoutineCreateResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: initialData != null ? '루틴 수정' : '루틴 생성',
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.5),
      transitionDuration: AppAnimation.standard,
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: AppLayout.dialogScaleStart, end: 1.0)
                .animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) =>
          RoutineCreateDialog(initialData: initialData),
    );
  }

  @override
  State<RoutineCreateDialog> createState() => _RoutineCreateDialogState();
}

class _RoutineCreateDialogState extends State<RoutineCreateDialog> {
  final _nameCtrl = TextEditingController();
  final Set<int> _days = {};
  TimeOfDay _start = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 8, minute: 0);
  int _colorIdx = 0;

  /// 중복 제출 방지 플래그
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 수정 모드: 기존 데이터로 폼을 초기화한다
    final data = widget.initialData;
    if (data != null) {
      _nameCtrl.text = data.name;
      _days.addAll(data.repeatDays);
      _start = data.startTime;
      _end = data.endTime;
      _colorIdx = data.colorIndex;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// 이름 입력 + 요일 1개 이상 선택 시 완료 버튼 활성화
  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty && _days.isNotEmpty;

  Future<void> _pickStart() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _start,
      helpText: '시작 시간 선택',
      builder: buildRoutinePickerTheme,
    );
    if (picked == null) return;
    setState(() {
      _start = picked;
      // 시작 >= 종료인 경우 종료를 1시간 뒤로 자동 조정한다
      final sm = picked.hour * AppLayout.minutesPerHour + picked.minute;
      final em = _end.hour * AppLayout.minutesPerHour + _end.minute;
      if (sm >= em) {
        _end = TimeOfDay(
          hour: (picked.hour + 1) % AppLayout.hoursInDay,
          minute: picked.minute,
        );
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _end,
      helpText: '종료 시간 선택',
      builder: buildRoutinePickerTheme,
    );
    if (picked != null) setState(() => _end = picked);
  }

  void _submit() {
    if (!_canSubmit || _isSaving) return;
    setState(() => _isSaving = true);
    Navigator.of(context).pop(RoutineCreateResult(
      name: _nameCtrl.text.trim(),
      repeatDays: _days.toList()..sort(),
      startTime: _start,
      endTime: _end,
      colorIndex: _colorIdx,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphicDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoutineDialogHeader(isEditMode: widget.initialData != null),
          const SizedBox(height: AppSpacing.xxl),
          RoutineFormLabel(label: '루틴 이름'),
          const SizedBox(height: AppSpacing.md),
          RoutineNameField(
            controller: _nameCtrl,
            hint: '예: 아침 스트레칭',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xl),
          RoutineFormLabel(label: '반복 요일'),
          const SizedBox(height: AppSpacing.md),
          RoutineDaySelector(
            selectedDays: _days,
            onToggle: (d) => setState(() {
              _days.contains(d) ? _days.remove(d) : _days.add(d);
            }),
          ),
          const SizedBox(height: AppSpacing.xl),
          RoutineFormLabel(label: '시간'),
          const SizedBox(height: AppSpacing.md),
          RoutineTimeRow(
            startTime: _start,
            endTime: _end,
            onPickStart: _pickStart,
            onPickEnd: _pickEnd,
          ),
          const SizedBox(height: AppSpacing.xl),
          RoutineFormLabel(label: '색상'),
          const SizedBox(height: AppSpacing.md),
          ColorPickerWidget(
            selectedIndex: _colorIdx,
            onColorSelected: (i) => setState(() => _colorIdx = i),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          RoutineSubmitButton(enabled: _canSubmit, onTap: _submit),
        ],
      ),
    );
  }
}
