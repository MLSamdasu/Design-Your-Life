// F4 위젯: RoutineCreateDialog - 루틴 생성 다이얼로그
// 이름, 반복 요일(월~일 복수 선택), 시작/종료 시간, 색상을 입력받는다.
// AN-06: showGeneralDialog로 Scale+Fade 애니메이션 250ms 적용
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/color_picker.dart';
import 'routine_form_widgets.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 루틴 생성 결과 데이터 클래스
class RoutineCreateResult {
  final String name;
  final List<int> repeatDays;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int colorIndex;

  const RoutineCreateResult({
    required this.name,
    required this.repeatDays,
    required this.startTime,
    required this.endTime,
    required this.colorIndex,
  });
}

/// 루틴 생성 다이얼로그
/// AN-06: Scale(0.9→1.0) + Fade 250ms easeOutCubic
class RoutineCreateDialog extends StatefulWidget {
  const RoutineCreateDialog({super.key});

  /// 다이얼로그를 표시하고 결과를 반환한다
  static Future<RoutineCreateResult?> show(BuildContext context) {
    return showGeneralDialog<RoutineCreateResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '루틴 생성',
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.5),
      transitionDuration: AppAnimation.standard,
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => const RoutineCreateDialog(),
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
        context: context, initialTime: _start, helpText: '시작 시간 선택');
    if (picked == null) return;
    setState(() {
      _start = picked;
      // 시작 >= 종료인 경우 종료를 1시간 뒤로 자동 조정한다
      final sm = picked.hour * 60 + picked.minute;
      final em = _end.hour * 60 + _end.minute;
      if (sm >= em) {
        _end = TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
        context: context, initialTime: _end, helpText: '종료 시간 선택');
    if (picked != null) setState(() => _end = picked);
  }

  void _submit() {
    if (!_canSubmit) return;
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
    // 화면 높이의 85%를 최대 높이로 제한하여 오버플로우를 방지한다
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.85;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.huge),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.massive),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  decoration: BoxDecoration(
                    color: context.themeColors.textPrimaryWithAlpha(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.massive),
                    border:
                        Border.all(color: context.themeColors.textPrimaryWithAlpha(0.25)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 헤더
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.xxl),
                      // 루틴 이름
                      RoutineFormLabel(label: '루틴 이름'),
                      const SizedBox(height: AppSpacing.md),
                      RoutineNameField(
                        controller: _nameCtrl,
                        hint: '예: 아침 스트레칭',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // 반복 요일
                      RoutineFormLabel(label: '반복 요일'),
                      const SizedBox(height: AppSpacing.md),
                      RoutineDaySelector(
                        selectedDays: _days,
                        onToggle: (d) => setState(() {
                          _days.contains(d) ? _days.remove(d) : _days.add(d);
                        }),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // 시간 선택
                      RoutineFormLabel(label: '시간'),
                      const SizedBox(height: AppSpacing.md),
                      RoutineTimeRow(
                        startTime: _start,
                        endTime: _end,
                        onPickStart: _pickStart,
                        onPickEnd: _pickEnd,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // 색상 선택
                      RoutineFormLabel(label: '색상'),
                      const SizedBox(height: AppSpacing.md),
                      ColorPickerWidget(
                        selectedIndex: _colorIdx,
                        onColorSelected: (i) => setState(() => _colorIdx = i),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      // 완료 버튼
                      RoutineSubmitButton(enabled: _canSubmit, onTap: _submit),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          '새 루틴 만들기',
          style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.close_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.6),
            size: 22,
          ),
        ),
      ],
    );
  }
}
