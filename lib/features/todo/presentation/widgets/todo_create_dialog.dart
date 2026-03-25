// F3 위젯: TodoCreateDialog - 투두 생성/수정 다이얼로그
// SRP 분리: 결과/날짜 행/피커 테마/폼 본문/다이얼로그 실행을 각각 별도 파일로 분리
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/nlp/parsed_todo.dart';
import '../../../../shared/models/todo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import 'todo_create_result.dart';
import 'todo_create_dialog_body.dart';
import 'todo_dialog_launcher.dart';
import 'todo_picker_theme.dart';
import '../../../../core/theme/layout_tokens.dart';

export 'todo_create_result.dart';

/// 투두 생성/수정 Glass 모달
/// 수정 모드: existingTodo가 제공되면 기존 투두의 필드를 채워서 수정 모드로 동작한다
class TodoCreateDialog extends ConsumerStatefulWidget {
  final ParsedTodo? prefill;
  final Todo? existingTodo;
  final DateTime? initialDate;

  const TodoCreateDialog({
    super.key, this.prefill, this.existingTodo, this.initialDate,
  });

  bool get isEditMode => existingTodo != null;

  /// 생성 모드 다이얼로그를 열고 결과를 반환한다
  static Future<TodoCreateResult?> show(
    BuildContext context, {ParsedTodo? prefill, DateTime? initialDate,
  }) => TodoDialogLauncher.show(context,
      prefill: prefill, initialDate: initialDate);

  /// 수정 모드 다이얼로그를 열고 결과를 반환한다
  static Future<TodoCreateResult?> showEdit(
    BuildContext context, {required Todo existingTodo,
  }) => TodoDialogLauncher.showEdit(context, existingTodo: existingTodo);

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
  late DateTime _selectedDate;
  Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _initFields();
  }

  /// 수정 모드 또는 prefill 데이터로 필드를 초기화한다
  void _initFields() {
    final existing = widget.existingTodo;
    if (existing != null) {
      _titleController.text = existing.title;
      _memoController.text = existing.memo ?? '';
      _selectedColorIndex = existing.colorIndex;
      _selectedTagIds = existing.tagIds.toSet();
      _selectedDate = existing.date;
      if (existing.startTime != null) {
        _hasTime = true;
        _selectedStartTime = existing.startTime!;
        _selectedEndTime = existing.endTime ?? TimeOfDay(
          hour: (existing.startTime!.hour + 1) % 24,
          minute: existing.startTime!.minute,
        );
      }
      return;
    }
    final p = widget.prefill;
    if (p != null) {
      _titleController.text = p.title;
      if (p.hasTime) {
        _hasTime = true;
        _selectedStartTime = p.time!;
        _selectedEndTime = TimeOfDay(
          hour: (p.time!.hour + 1) % 24, minute: p.time!.minute,
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

  /// 시작 시간 피커
  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: _selectedStartTime,
      builder: buildTodoPickerTheme,
    );
    if (picked == null) return;
    setState(() {
      _selectedStartTime = picked;
      final sMin = picked.hour * 60 + picked.minute;
      final eMin = _selectedEndTime.hour * 60 + _selectedEndTime.minute;
      if (eMin <= sMin) {
        _selectedEndTime = TimeOfDay(
          hour: (picked.hour + 1) % 24, minute: picked.minute,
        );
      }
    });
  }

  /// 종료 시간 피커
  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: _selectedEndTime,
      builder: buildTodoPickerTheme,
    );
    if (picked != null) setState(() => _selectedEndTime = picked);
  }

  /// 날짜 선택 피커 (P1-16)
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _selectedDate,
      firstDate: DateTime(TimelineLayout.calendarStartYear),
      lastDate: DateTime(TimelineLayout.calendarEndYear),
      builder: buildTodoPickerTheme,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// 빠른 지속 시간 버튼으로 종료 시간을 설정한다
  void _setQuickDuration(int minutes) {
    setState(() {
      final sMin = _selectedStartTime.hour * 60 + _selectedStartTime.minute;
      final eMin = sMin + minutes;
      _selectedEndTime = TimeOfDay(hour: (eMin ~/ 60) % 24, minute: eMin % 60);
    });
  }

  /// 폼 검증 후 결과를 반환한다
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_hasTime) {
      final sMin = _selectedStartTime.hour * 60 + _selectedStartTime.minute;
      final eMin = _selectedEndTime.hour * 60 + _selectedEndTime.minute;
      if (eMin <= sMin) {
        AppSnackBar.showWarning(context, '종료 시간은 시작 시간 이후여야 합니다');
        return;
      }
    }
    Navigator.of(context).pop(TodoCreateResult(
      title: _titleController.text.trim(),
      date: _selectedDate,
      startTime: _hasTime ? _selectedStartTime : null,
      endTime: _hasTime ? _selectedEndTime : null,
      colorIndex: _selectedColorIndex,
      memo: _memoController.text.trim().isEmpty
          ? null : _memoController.text.trim(),
      tagIds: _selectedTagIds.toList(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return TodoCreateDialogBody(
      headerTitle: widget.isEditMode ? '할 일 수정' : '할 일 추가',
      onClose: () => Navigator.of(context).pop(),
      titleController: _titleController,
      memoController: _memoController,
      formKey: _formKey,
      selectedDate: _selectedDate,
      onPickDate: _pickDate,
      hasTime: _hasTime,
      startTime: _selectedStartTime,
      endTime: _selectedEndTime,
      onTimeToggled: (v) => setState(() => _hasTime = v),
      onPickStartTime: _pickStartTime,
      onPickEndTime: _pickEndTime,
      onQuickDuration: _setQuickDuration,
      selectedColorIndex: _selectedColorIndex,
      onColorSelected: (i) => setState(() => _selectedColorIndex = i),
      selectedTagIds: _selectedTagIds,
      onTagsChanged: (ids) => setState(() => _selectedTagIds = ids),
      submitLabel: widget.isEditMode ? '수정' : '저장',
      onSubmit: _submit,
    );
  }
}
