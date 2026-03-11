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
import '../../../../shared/widgets/tag_chip_selector.dart';
import 'todo_form_fields.dart';
import 'todo_time_picker.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 투두 생성 결과 데이터 클래스
class TodoCreateResult {
  final String title;

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
    this.startTime,
    this.endTime,
    required this.colorIndex,
    this.memo,
    this.tagIds = const [],
  });
}

/// 투두 생성 Glass 모달
/// AN-06: Scale(0.9->1) + Fade 250ms easeOutCubic 애니메이션
/// F16: ConsumerStatefulWidget으로 변경하여 TagChipSelector의 Riverpod 접근을 지원한다
/// F20: prefill 매개변수를 통해 자연어 파싱 결과로 필드를 자동 채울 수 있다
class TodoCreateDialog extends ConsumerStatefulWidget {
  /// 자연어 파싱 결과로 필드를 자동 채울 때 사용한다 (F20, 선택)
  final ParsedTodo? prefill;

  const TodoCreateDialog({super.key, this.prefill});

  /// 다이얼로그를 열고 결과를 반환한다
  /// [prefill]: 자연어 파싱 결과로 필드를 자동 채울 때 사용한다 (F20)
  static Future<TodoCreateResult?> show(
    BuildContext context, {
    ParsedTodo? prefill,
  }) {
    return showGeneralDialog<TodoCreateResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.4),
      transitionDuration: AppAnimation.standard,
      pageBuilder: (_, __, ___) => TodoCreateDialog(prefill: prefill),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
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

  /// 선택된 태그 ID 집합 (F16: 태그 시스템)
  Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedEndTime = picked);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('종료 시간은 시작 시간 이후여야 합니다')),
        );
        return;
      }
    }

    Navigator.of(context).pop(
      TodoCreateResult(
        title: _titleController.text.trim(),
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
            maxWidth: mediaQuery.size.width >= 600 ? 480 : 360,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xxl,
              right: AppSpacing.xxl,
              bottom: mediaQuery.viewInsets.bottom + 20,
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
                          // 헤더 (TodoDialogHeader 공용 위젯)
                          TodoDialogHeader(
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
                          // 저장 버튼 (TodoPrimaryButton 공용 위젯)
                          TodoPrimaryButton(label: '저장', onTap: _submit),
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
