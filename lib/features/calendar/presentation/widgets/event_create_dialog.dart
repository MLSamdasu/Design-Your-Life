// F2 위젯: EventCreateDialog - 일정 생성/수정 다이얼로그
// Glass Modal 스타일. 이벤트 저장은 Provider를 통해 서비스 계층에 위임한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/models/event.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../providers/event_provider.dart';
import 'event_builder.dart';
import 'event_dialog_actions.dart';
import 'event_dialog_body.dart';
import 'event_dialog_header.dart';
import 'event_form_section.dart';

/// 일정 생성/수정 다이얼로그 (showDialog로 표시)
class EventCreateDialog extends ConsumerStatefulWidget {
  final String? editEventId;
  final Event? editEvent;
  final DateTime initialDate;

  const EventCreateDialog({
    super.key,
    this.editEventId,
    this.editEvent,
    required this.initialDate,
  });

  @override
  ConsumerState<EventCreateDialog> createState() =>
      _EventCreateDialogState();
}

class _EventCreateDialogState extends ConsumerState<EventCreateDialog> {
  final _titleCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _rangeTagCtrl = TextEditingController();

  EventType _eventType = EventType.normal;
  int _colorIndex = 0;
  late DateTime _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final Set<int> _repeatDays = {};
  bool _isSaving = false;
  String? _titleError;
  String? _dateError;
  String? _repeatError;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
    _initFromEditEvent();
  }

  /// 편집 모드: 기존 이벤트 데이터로 폼을 초기화한다
  void _initFromEditEvent() {
    final e = widget.editEvent;
    if (e == null) return;
    _titleCtrl.text = e.title;
    _memoCtrl.text = e.memo ?? '';
    _locationCtrl.text = e.location ?? '';
    final init = EventFormInitData.fromEvent(e);
    _eventType = init.eventType;
    _colorIndex = init.colorIndex;
    _startDate = init.startDate;
    _endDate = init.endDate;
    _startTime = init.startTime;
    _endTime = init.endTime;
    if (init.rangeTagName != null) _rangeTagCtrl.text = init.rangeTagName!;
    _repeatDays.addAll(init.repeatDays);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    _locationCtrl.dispose();
    _rangeTagCtrl.dispose();
    super.dispose();
  }

  /// 폼 유효성 검사를 수행하고 에러 상태를 갱신한다
  bool _validate() {
    final r = validateEventForm(
      title: _titleCtrl.text, eventType: _eventType,
      startDate: _startDate, endDate: _endDate, repeatDays: _repeatDays,
    );
    setState(() {
      _titleError = r.titleError;
      _dateError = r.dateError;
      _repeatError = r.repeatError;
    });
    return r.titleError == null && r.dateError == null && r.repeatError == null;
  }

  /// Provider를 통해 이벤트를 저장한다
  Future<void> _save() async {
    if (!_validate()) {
      final msg = _titleError ?? _dateError ?? _repeatError;
      if (msg != null && mounted) AppSnackBar.showError(context, msg);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final event = buildEventFromForm(
        eventId: widget.editEventId ?? ref.read(generateEventIdProvider)(),
        now: DateTime.now(),
        title: _titleCtrl.text, eventType: _eventType,
        startDate: _startDate, endDate: _endDate,
        startTime: _startTime, endTime: _endTime,
        colorIndex: _colorIndex, location: _locationCtrl.text,
        memo: _memoCtrl.text, repeatDays: _repeatDays,
        rangeTagText: _rangeTagCtrl.text,
      );
      if (widget.editEventId != null) {
        await ref.read(updateEventProvider)(event);
      } else {
        await ref.read(createEventProvider)(event);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(context, '일정 저장에 실패했습니다');
      }
    }
  }

  /// 삭제 확인 후 이벤트를 삭제한다
  Future<void> _deleteEvent() async {
    final ok = await showDeleteEventConfirmDialog(context);
    if (!ok || !mounted) return;
    try {
      await ref.read(deleteEventProvider)(widget.editEventId!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, '일정 삭제에 실패했습니다');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editEventId != null;
    return EventDialogBody(
      children: [
        EventDialogHeader(
          isEditMode: isEdit,
          onClose: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(height: AppSpacing.xxl),
        EventFormSection(
          titleController: _titleCtrl,
          titleError: _titleError,
          onTitleChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
          eventType: _eventType,
          startDate: _startDate,
          endDate: _endDate,
          startTime: _startTime,
          endTime: _endTime,
          selectedColorIndex: _colorIndex,
          repeatDays: _repeatDays,
          rangeTagController: _rangeTagCtrl,
          locationController: _locationCtrl,
          memoController: _memoCtrl,
          onTypeChanged: (t) => setState(() => _eventType = t),
          onStartDateChanged: (d) => setState(() => _startDate = d),
          onEndDateChanged: (d) => setState(() => _endDate = d),
          onStartTimeChanged: (t) => setState(() => _startTime = t),
          onEndTimeChanged: (t) => setState(() => _endTime = t),
          onColorChanged: (i) => setState(() => _colorIndex = i),
          onRepeatDaysChanged: (days) => setState(() {
            _repeatDays.clear();
            _repeatDays.addAll(days);
          }),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        EventDialogActions(
          isEditMode: isEdit,
          isSaving: _isSaving,
          onSave: _save,
          onCancel: () => Navigator.of(context).pop(false),
          onDelete: _deleteEvent,
        ),
      ],
    );
  }
}
