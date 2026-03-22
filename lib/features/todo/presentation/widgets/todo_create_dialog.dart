// F3 위젯: TodoCreateDialog - 투두 생성 다이얼로그
// 할 일 제목(필수), 시간 지정 토글(선택), 색상 8가지(선택), 메모(선택), 태그(선택)를 입력받는다.
// SRP 분리: 폼 필드/헤더/색상 → todo_form_fields.dart, 시간 선택 → todo_time_picker.dart
// F16: TagChipSelector를 추가하여 태그 다중 선택을 지원한다.
// F20: prefill 매개변수를 통해 자연어 파싱 결과로 필드를 자동 채울 수 있다.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/nlp/parsed_todo.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/models/todo.dart';
import '../../../../shared/widgets/tag_chip_selector.dart';
import 'todo_form_fields.dart';
import 'todo_time_picker.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// 투두 생성 결과 데이터 클래스
class TodoCreateResult {
  final String title;

  /// 예정 날짜 (P1-16: 다이얼로그에서 선택한 날짜)
  final DateTime? date;

  /// 시작 시간 (시간 지정 시)
  final TimeOfDay? startTime;

  /// 종료 시간 (시간 지정 시, null이면 기본 30분 지속)
  final TimeOfDay? endTime;

  final int colorIndex;
  final String? memo;

  /// 선택된 태그 ID 목록 (F16: 태그 시스템)
  final List<String> tagIds;

  /// 하위 호환: 기존 time 필드 접근을 startTime으로 위임한다
  TimeOfDay? get time => startTime;

  const TodoCreateResult({
    required this.title,
    this.date,
    this.startTime,
    this.endTime,
    required this.colorIndex,
    this.memo,
    this.tagIds = const [],
  });
}

/// 투두 생성/수정 Glass 모달
/// AN-06: Scale(0.9->1) + Fade 250ms easeOutCubic 애니메이션
/// F16: ConsumerStatefulWidget으로 변경하여 TagChipSelector의 Riverpod 접근을 지원한다
/// F20: prefill 매개변수를 통해 자연어 파싱 결과로 필드를 자동 채울 수 있다
/// 수정 모드: existingTodo가 제공되면 기존 투두의 필드를 채워서 수정 모드로 동작한다
class TodoCreateDialog extends ConsumerStatefulWidget {
  /// 자연어 파싱 결과로 필드를 자동 채울 때 사용한다 (F20, 선택)
  final ParsedTodo? prefill;

  /// 수정 모드: 기존 투두 객체 (null이면 생성 모드)
  final Todo? existingTodo;

  /// 초기 날짜 (P1-16: 다이얼로그에서 날짜 선택 지원)
  final DateTime? initialDate;

  const TodoCreateDialog({super.key, this.prefill, this.existingTodo, this.initialDate});

  /// 수정 모드 여부
  bool get isEditMode => existingTodo != null;

  /// 생성 모드: 다이얼로그를 열고 결과를 반환한다
  /// [prefill]: 자연어 파싱 결과로 필드를 자동 채울 때 사용한다 (F20)
  /// [initialDate]: 기본 선택 날짜 (P1-16)
  static Future<TodoCreateResult?> show(
    BuildContext context, {
    ParsedTodo? prefill,
    DateTime? initialDate,
  }) {
    return showGeneralDialog<TodoCreateResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.4),
      transitionDuration: AppAnimation.standard,
      pageBuilder: (_, __, ___) => TodoCreateDialog(prefill: prefill, initialDate: initialDate),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: AppLayout.dialogScaleStart, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  /// 수정 모드: 기존 투두 데이터로 다이얼로그를 열고 결과를 반환한다
  static Future<TodoCreateResult?> showEdit(
    BuildContext context, {
    required Todo existingTodo,
  }) {
    return showGeneralDialog<TodoCreateResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.4),
      transitionDuration: AppAnimation.standard,
      pageBuilder: (_, __, ___) =>
          TodoCreateDialog(existingTodo: existingTodo),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: AppLayout.dialogScaleStart, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  @override
  ConsumerState<TodoCreateDialog> createState() => _TodoCreateDialogState();
}

class _TodoCreateDialogState extends ConsumerState<TodoCreateDialog> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _hasTime = false;
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  TimeOfDay _selectedEndTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  int _selectedColorIndex = 0;

  /// 선택된 날짜 (P1-16: 다이얼로그에서 날짜를 변경할 수 있다)
  late DateTime _selectedDate;

  /// 선택된 태그 ID 집합 (F16: 태그 시스템)
  Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    // P1-16: 초기 날짜를 설정한다 (기본값: 오늘)
    _selectedDate = widget.initialDate ?? DateTime.now();

    // 수정 모드: 기존 투두 데이터로 필드를 채운다
    final existing = widget.existingTodo;
    if (existing != null) {
      _titleController.text = existing.title;
      _memoController.text = existing.memo ?? '';
      _selectedColorIndex = existing.colorIndex;
      _selectedTagIds = existing.tagIds.toSet();
      _selectedDate = existing.date;
      // 시간이 설정된 경우 시간 토글을 활성화한다
      if (existing.startTime != null) {
        _hasTime = true;
        _selectedStartTime = existing.startTime!;
        _selectedEndTime = existing.endTime ??
            TimeOfDay(
              hour: (existing.startTime!.hour + 1) % 24,
              minute: existing.startTime!.minute,
            );
      }
      return;
    }
    // F20: prefill 데이터가 있으면 필드를 자동으로 채운다
    final prefill = widget.prefill;
    if (prefill != null) {
      // 제목 자동 채우기
      _titleController.text = prefill.title;
      // 시간이 파싱된 경우 시간 토글을 활성화하고 파싱된 시간을 설정한다
      if (prefill.hasTime) {
        _hasTime = true;
        _selectedStartTime = prefill.time!;
        // 종료 시간 기본값: 시작 시간 + 1시간
        _selectedEndTime = TimeOfDay(
          hour: (prefill.time!.hour + 1) % 24,
          minute: prefill.time!.minute,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// 시작 시간 피커를 열어 시간을 선택한다
  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
      // 테마 인식 TimePicker: 모든 테마에서 가독성 보장
      builder: _buildPickerTheme,
    );
    if (picked != null) {
      setState(() {
        _selectedStartTime = picked;
        // 종료 시간이 시작 시간보다 이르면 자동 보정한다
        final startMin = picked.hour * 60 + picked.minute;
        final endMin = _selectedEndTime.hour * 60 + _selectedEndTime.minute;
        if (endMin <= startMin) {
          _selectedEndTime = TimeOfDay(
            hour: (picked.hour + 1) % 24,
            minute: picked.minute,
          );
        }
      });
    }
  }

  /// 종료 시간 피커를 열어 시간을 선택한다
  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
      // 테마 인식 TimePicker: 모든 테마에서 가독성 보장
      builder: _buildPickerTheme,
    );
    if (picked != null) {
      setState(() => _selectedEndTime = picked);
    }
  }

  /// 날짜 선택 피커를 열어 날짜를 선택한다 (P1-16)
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(AppLayout.calendarStartYear),
      lastDate: DateTime(AppLayout.calendarEndYear),
      // 테마 인식 DatePicker: 모든 테마에서 가독성 보장
      builder: _buildPickerTheme,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// TimePicker 다이얼로그에 테마 인식 배경색을 적용한다
  /// 어두운 배경 테마(Glassmorphism/Neon)에서도 가독성을 보장한다
  Widget _buildPickerTheme(BuildContext context, Widget? child) {
    final dialogBg = context.themeColors.dialogSurface;
    final isOnDark = context.themeColors.isOnDarkBackground;
    return Theme(
      data: (isOnDark ? ThemeData.dark() : ThemeData.light()).copyWith(
        colorScheme: (isOnDark
                ? const ColorScheme.dark(primary: ColorTokens.main)
                : const ColorScheme.light(primary: ColorTokens.main))
            .copyWith(surface: dialogBg),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
  }

  /// 빠른 지속 시간 버튼으로 종료 시간을 설정한다
  void _setQuickDuration(int minutes) {
    setState(() {
      final startMin = _selectedStartTime.hour * 60 + _selectedStartTime.minute;
      final endMin = startMin + minutes;
      _selectedEndTime = TimeOfDay(
        hour: (endMin ~/ 60) % 24,
        minute: endMin % 60,
      );
    });
  }

  /// 폼 검증 후 결과를 반환한다
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // 시간 유효성 검증: 종료 시간이 시작 시간보다 이르면 경고한다
    if (_hasTime) {
      final startMin =
          _selectedStartTime.hour * 60 + _selectedStartTime.minute;
      final endMin = _selectedEndTime.hour * 60 + _selectedEndTime.minute;
      if (endMin <= startMin) {
        AppSnackBar.showWarning(context, '종료 시간은 시작 시간 이후여야 합니다');
        return;
      }
    }

    Navigator.of(context).pop(
      TodoCreateResult(
        title: _titleController.text.trim(),
        // P1-16: 선택된 날짜를 결과에 포함한다
        date: _selectedDate,
        startTime: _hasTime ? _selectedStartTime : null,
        endTime: _hasTime ? _selectedEndTime : null,
        colorIndex: _selectedColorIndex,
        memo: _memoController.text.trim().isEmpty
            ? null
            : _memoController.text.trim(),
        // 선택된 태그 ID 목록을 결과에 포함한다 (F16)
        tagIds: _selectedTagIds.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: mediaQuery.size.width >= AppLayout.responsiveBreakpointSm
                ? AppLayout.dialogMaxWidthLg
                : AppLayout.dialogMaxWidthSm,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xxl,
              right: AppSpacing.xxl,
              bottom: mediaQuery.viewInsets.bottom + AppSpacing.xxl,
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
                  // 소형 기기에서 키보드 출현 시 내용이 오버플로우되지 않도록
                  // SingleChildScrollView로 감싼다 (EventCreateDialog와 동일한 패턴)
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 헤더 (수정 모드에서는 제목을 변경한다)
                          TodoDialogHeader(
                            title: widget.isEditMode ? '할 일 수정' : '할 일 추가',
                            onClose: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          // 제목 입력 (TodoGlassTextField 공용 위젯)
                          TodoGlassTextField(
                            controller: _titleController,
                            hintText: '할 일을 입력해주세요',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return '제목을 입력해주세요';
                              }
                              if (v.trim().length > 200) {
                                return '200자 이내로 입력해주세요';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // 날짜 선택 (P1-16: 투두 생성/수정 시 날짜를 변경할 수 있다)
                          _TodoDatePickerRow(
                            selectedDate: _selectedDate,
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // 시간 범위 지정 (시작/종료 + 빠른 지속 시간)
                          TodoTimeRangeSection(
                            hasTime: _hasTime,
                            startTime: _selectedStartTime,
                            endTime: _selectedEndTime,
                            onToggled: (v) => setState(() => _hasTime = v),
                            onPickStartTime: _pickStartTime,
                            onPickEndTime: _pickEndTime,
                            onQuickDuration: _setQuickDuration,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // 색상 선택 (TodoColorSection 공용 위젯)
                          TodoColorSection(
                            selectedIndex: _selectedColorIndex,
                            onSelected: (i) =>
                                setState(() => _selectedColorIndex = i),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // 태그 선택 (F16: TagChipSelector)
                          TagChipSelector(
                            selectedTagIds: _selectedTagIds,
                            onChanged: (tagIds) =>
                                setState(() => _selectedTagIds = tagIds),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          // 메모 입력 (선택)
                          TodoGlassTextField(
                            controller: _memoController,
                            hintText: '메모 (선택)',
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          // 저장 버튼 (수정 모드에서는 '수정' 레이블을 표시한다)
                          TodoPrimaryButton(
                            label: widget.isEditMode ? '수정' : '저장',
                            onTap: _submit,
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
      ),
    );
  }
}

/// 날짜 선택 행 위젯 (P1-16)
/// 캘린더 아이콘 + 날짜 표시 + 탭하면 DatePicker 다이얼로그를 연다
class _TodoDatePickerRow extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _TodoDatePickerRow({
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}';
    // 요일 레이블
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[(selectedDate.weekday - 1).clamp(0, 6)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.mdLg),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: context.themeColors.textPrimaryWithAlpha(0.10),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: context.themeColors.textPrimaryWithAlpha(0.20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.7),
                  size: AppLayout.iconMd,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '$formatted ($weekday)',
                  style: AppTypography.bodyLg.copyWith(
                    color: context.themeColors.textPrimary,
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
