// F2 위젯: EventCreateDialog - 일정 생성/수정 다이얼로그
// 제목, EventType(일반/범위/반복/투두), 날짜, 시간, 색상(8가지),
// 위치, 메모를 입력받는다. 범위: rangeTag 선택, 반복: repeatDays 선택 추가 표시
// Glass Modal 스타일 (BackdropFilter + GlassDecoration.modal)
// 이벤트 저장은 EventRepository를 통해 수행한다 (위젯에서 API 직접 접근 금지).
// F16: TagChipSelector를 추가하여 태그 다중 선택을 지원한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/event.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/glass_input_field.dart';
import '../../../../core/constants/app_constants.dart';
// P1-3: Event 모델에 tags 필드가 없으므로 TagChipSelector 제거됨
import '../../providers/event_provider.dart';
import 'event_form_fields.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// 일정 생성/수정 다이얼로그 (showDialog로 표시)
class EventCreateDialog extends ConsumerStatefulWidget {
  /// 편집 모드 시 기존 이벤트 ID
  final String? editEventId;
  /// 편집 모드 시 기존 이벤트 데이터 (폼 초기값으로 사용)
  final Event? editEvent;
  /// 기본 선택 날짜
  final DateTime initialDate;

  const EventCreateDialog({
    super.key,
    this.editEventId,
    this.editEvent,
    required this.initialDate,
  });

  @override
  ConsumerState<EventCreateDialog> createState() => _EventCreateDialogState();
}

class _EventCreateDialogState extends ConsumerState<EventCreateDialog> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _locationController = TextEditingController();
  final _rangeTagController = TextEditingController();

  // EventType은 Event 모델에 정의된 enum을 직접 사용한다
  EventType _eventType = EventType.normal;
  int _selectedColorIndex = 0;
  late DateTime _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  // 반복 요일 (1=월 ~ 7=일)
  final Set<int> _repeatDays = {};

  bool _isSaving = false;
  String? _titleError;
  String? _dateError;
  String? _repeatError;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;

    // 편집 모드: 기존 이벤트 데이터로 폼을 초기화한다
    final event = widget.editEvent;
    if (event != null) {
      _titleController.text = event.title;
      _memoController.text = event.memo ?? '';
      _locationController.text = event.location ?? '';
      _eventType = event.eventType;
      _selectedColorIndex = event.colorIndex;
      _startDate = event.startDate;
      _endDate = event.endDate;
      // 종일 이벤트가 아니면 시작/종료 시간을 설정한다
      if (!event.allDay) {
        _startTime = TimeOfDay(
          hour: event.startDate.hour,
          minute: event.startDate.minute,
        );
        if (event.endDate != null) {
          _endTime = TimeOfDay(
            hour: event.endDate!.hour,
            minute: event.endDate!.minute,
          );
        }
      }
      // 범위 태그 초기화
      if (event.rangeTag != null) {
        _rangeTagController.text = event.rangeTag!.name;
      }
      // 반복 규칙 파싱 (FREQ=WEEKLY;BYDAY=MO,TU 형식)
      if (event.recurrenceRule != null) {
        final byDayMatch = RegExp(r'BYDAY=([A-Z,]+)').firstMatch(event.recurrenceRule!);
        if (byDayMatch != null) {
          final dayNames = {'MO': 1, 'TU': 2, 'WE': 3, 'TH': 4, 'FR': 5, 'SA': 6, 'SU': 7};
          for (final day in byDayMatch.group(1)!.split(',')) {
            final dayNum = dayNames[day];
            if (dayNum != null) _repeatDays.add(dayNum);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _locationController.dispose();
    _rangeTagController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _titleError =
          _titleController.text.trim().isEmpty ? '제목을 입력해주세요' : null;

      // 범위 일정: 종료일이 시작일 이전이면 유효하지 않다
      if (_eventType == EventType.range) {
        if (_endDate == null) {
          _dateError = '종료일을 선택해주세요';
        } else if (_endDate!.isBefore(_startDate)) {
          _dateError = '종료일은 시작일 이후여야 합니다';
        } else {
          _dateError = null;
        }
      } else {
        _dateError = null;
      }

      // 반복 일정: 반복 요일이 최소 1개 선택되어야 한다
      if (_eventType == EventType.recurring && _repeatDays.isEmpty) {
        _repeatError = '반복 요일을 최소 1개 선택해주세요';
      } else {
        _repeatError = null;
      }
    });
    return _titleError == null && _dateError == null && _repeatError == null;
  }

  /// EventRepository를 통해 이벤트를 저장한다
  /// 위젯에서 API에 직접 접근하지 않고 Provider를 통해 서비스 계층에 위임한다
  Future<void> _save() async {
    if (!_validate()) {
      // 유효성 검사 실패 시 첫 번째 오류 메시지를 SnackBar로 표시한다
      final errorMsg = _titleError ?? _dateError ?? _repeatError;
      if (errorMsg != null && mounted) {
        AppSnackBar.showError(context, errorMsg);
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.editEventId != null) {
        // 수정 모드: 기존 이벤트를 업데이트한다
        final updateFn = ref.read(updateEventProvider);
        final now = DateTime.now();
        // 수정 시에는 기존 createdAt을 유지해야 하므로 임시값을 사용한다
        // 실제 createdAt은 서버에서 기존 값이 유지된다 (PUT 요청 사용)
        final event = _buildEvent(
          eventId: widget.editEventId!,
          now: now,
        );
        await updateFn(event);
      } else {
        // 생성 모드: 새 이벤트 ID를 생성하고 저장한다
        final generateId = ref.read(generateEventIdProvider);
        final createFn = ref.read(createEventProvider);
        final now = DateTime.now();
        final eventId = generateId();
        final event = _buildEvent(eventId: eventId, now: now);
        await createFn(event);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      // 일정 저장 실패 시 오류 컬러 토큰을 사용해 SnackBar로 사용자에게 알린다
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(context, '일정 저장에 실패했습니다');
      }
    }
  }

  /// 입력값으로 Event 모델 객체를 생성한다
  /// userId는 EventRepository가 Provider를 통해 처리하므로 여기서는 빈 문자열을 사용한다
  /// (createEventProvider/updateEventProvider 내부에서 currentUserIdProvider를 읽는다)
  Event _buildEvent({required String eventId, required DateTime now}) {
    // startDate에 시간을 합친 DateTime을 생성한다
    // 백엔드는 LocalDateTime 형식으로 시작/종료를 받는다
    DateTime startDateTime = _startDate;
    if (_startTime != null) {
      startDateTime = DateTime(
        _startDate.year, _startDate.month, _startDate.day,
        _startTime!.hour, _startTime!.minute,
      );
    }

    DateTime? endDateTime;
    if (_eventType == EventType.range && _endDate != null) {
      if (_endTime != null) {
        endDateTime = DateTime(
          _endDate!.year, _endDate!.month, _endDate!.day,
          _endTime!.hour, _endTime!.minute,
        );
      } else {
        endDateTime = _endDate;
      }
    } else if (_endTime != null) {
      // 범위 타입이 아닌 경우, 같은 날의 종료 시간으로 설정한다
      endDateTime = DateTime(
        _startDate.year, _startDate.month, _startDate.day,
        _endTime!.hour, _endTime!.minute,
      );
    }

    // 반복 규칙 문자열 생성 (iCalendar RRULE 형식 간소화)
    String? recurrenceRule;
    if (_eventType == EventType.recurring && _repeatDays.isNotEmpty) {
      final sortedDays = _repeatDays.toList()..sort();
      final dayNames = ['', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      final byDay = sortedDays.map((d) => dayNames[d]).join(',');
      recurrenceRule = 'FREQ=WEEKLY;BYDAY=$byDay';
    }

    return Event(
      id: eventId,
      title: _titleController.text.trim(),
      eventType: _eventType,
      startDate: startDateTime,
      endDate: endDateTime,
      allDay: _startTime == null && _endTime == null,
      colorIndex: _selectedColorIndex,
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      memo: _memoController.text.trim().isNotEmpty
          ? _memoController.text.trim()
          : null,
      recurrenceRule: recurrenceRule,
      rangeTag: _eventType == EventType.range &&
              _rangeTagController.text.trim().isNotEmpty
          ? RangeTag.values.firstWhere(
              (t) => t.name == _rangeTagController.text.trim().toLowerCase(),
              orElse: () => RangeTag.other,
            )
          : null,
      createdAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorTokens.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.massive),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: AppLayout.modalBlurSigma, sigmaY: AppLayout.modalBlurSigma),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
            decoration: GlassDecoration.modal(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.xxl),
                  GlassInputField(
                    controller: _titleController,
                    label: '제목',
                    hint: '일정 제목을 입력하세요',
                    maxLength: AppConstants.maxTitleLength,
                    errorText: _titleError,
                    onChanged: (_) {
                      if (_titleError != null) setState(() => _titleError = null);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // 하위 폼 필드들은 SRP 분리된 EventFormFields에 위임
                  EventFormFields(
                    eventType: _eventType,
                    startDate: _startDate,
                    endDate: _endDate,
                    startTime: _startTime,
                    endTime: _endTime,
                    selectedColorIndex: _selectedColorIndex,
                    repeatDays: _repeatDays,
                    rangeTagController: _rangeTagController,
                    locationController: _locationController,
                    memoController: _memoController,
                    onTypeChanged: (t) => setState(() => _eventType = t),
                    onStartDateChanged: (d) => setState(() => _startDate = d),
                    onEndDateChanged: (d) => setState(() => _endDate = d),
                    onStartTimeChanged: (t) => setState(() => _startTime = t),
                    onEndTimeChanged: (t) => setState(() => _endTime = t),
                    onColorChanged: (i) => setState(() => _selectedColorIndex = i),
                    onRepeatDaysChanged: (days) =>
                        setState(() {
                          _repeatDays.clear();
                          _repeatDays.addAll(days);
                        }),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildButtons(),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  /// 다이얼로그 헤더 (제목 + 닫기 버튼)
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.editEventId != null ? '일정 수정' : '일정 추가',
          style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
        ),
        // WCAG 2.1 기준 최소 터치 타겟 44x44px 적용
        GestureDetector(
          onTap: () => Navigator.of(context).pop(false),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: AppLayout.minTouchTarget,
            height: AppLayout.minTouchTarget,
            child: Center(
              child: Container(
                width: AppLayout.iconHuge,
                height: AppLayout.iconHuge,
                decoration: BoxDecoration(
                  color: context.themeColors.textPrimaryWithAlpha(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.80),
                  size: AppLayout.iconMd,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 이벤트 삭제 확인 다이얼로그를 표시한다
  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        title: Text(
          '일정 삭제',
          style: AppTypography.titleMd.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        content: Text(
          '이 일정을 삭제하시겠습니까?',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '취소',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '삭제',
              style: AppTypography.bodyMd.copyWith(
                color: ColorTokens.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final deleteFn = ref.read(deleteEventProvider);
        await deleteFn(widget.editEventId!);
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, '일정 삭제에 실패했습니다');
        }
      }
    }
  }

  /// 저장/취소 버튼 영역
  Widget _buildButtons() {
    return Row(
      children: [
        // 편집 모드에서만 삭제 버튼을 표시한다 (Expanded로 3버튼 균등 분배)
        if (widget.editEventId != null) ...[
          Expanded(
            child: GlassButton(
              label: '삭제',
              variant: GlassButtonVariant.ghost,
              onTap: _isSaving ? null : _deleteEvent,
              leadingIcon: Icons.delete_outline_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
        ],
        Expanded(
          child: GlassButton(
            label: '취소',
            variant: GlassButtonVariant.ghost,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: GlassButton(
            label: _isSaving ? '저장 중...' : '저장',
            variant: GlassButtonVariant.primary,
            onTap: _isSaving ? null : _save,
          ),
        ),
      ],
    );
  }
}
