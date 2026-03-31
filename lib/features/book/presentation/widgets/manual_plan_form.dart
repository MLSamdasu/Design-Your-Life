// F-Book: 수동 분배 폼 — 시작일~목표일 범위의 날짜별 한 칸 입력을 관리한다
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../services/manual_plan_validator.dart';
import '../../services/reading_plan_generator.dart';
import 'manual_plan_row.dart';
import 'manual_plan_summary.dart';

/// 수동 분배 폼 위젯
class ManualPlanForm extends StatefulWidget {
  final DateTime startDate;
  final DateTime targetDate;
  final int totalAmount;
  final String trackingMode; // 'page' or 'chapter'
  final ValueChanged<List<ManualPlanEntry>> onChanged;
  final ValueChanged<bool> onValidChanged;

  const ManualPlanForm({
    super.key, required this.startDate, required this.targetDate,
    required this.totalAmount, required this.trackingMode,
    required this.onChanged, required this.onValidChanged,
  });

  @override
  State<ManualPlanForm> createState() => _ManualPlanFormState();
}

class _ManualPlanFormState extends State<ManualPlanForm> {
  List<DateTime> _dates = [];
  List<TextEditingController> _rangeCtrls = []; // 페이지 모드 "시작,끝"
  List<TextEditingController> _chapterCtrls = []; // 챕터 모드
  List<bool> _restDays = [];
  ManualPlanValidation _validation = const ManualPlanValidation();
  Timer? _debounce;
  bool _autoStartEnabled = true; // 시작값 자동입력 기본 활성
  bool get _isPageMode => widget.trackingMode == 'page';

  @override
  void initState() { super.initState(); _buildRows(); }

  @override
  void didUpdateWidget(ManualPlanForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.targetDate != widget.targetDate ||
        oldWidget.trackingMode != widget.trackingMode) {
      _buildRows();
    }
  }

  @override
  void dispose() { _debounce?.cancel(); _disposeControllers(); super.dispose(); }

  void _buildRows() {
    _disposeControllers();
    final d = widget.targetDate.difference(widget.startDate).inDays + 1;
    _dates = d <= 0
        ? [widget.startDate]
        : List.generate(d, (i) => DateTime(
            widget.startDate.year, widget.startDate.month,
            widget.startDate.day + i));
    final n = _dates.length;
    _rangeCtrls = List.generate(n, (_) => TextEditingController());
    _chapterCtrls = List.generate(n, (_) => TextEditingController());
    _restDays = List.filled(n, false);
    _validation = const ManualPlanValidation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { _notify(); widget.onValidChanged(false); }
    });
  }

  void _disposeControllers() {
    for (final c in _rangeCtrls) { c.dispose(); }
    for (final c in _chapterCtrls) { c.dispose(); }
    _rangeCtrls = [];
    _chapterCtrls = [];
  }

  /// 필드 변경 시 자동입력 + 디바운스 검증
  void _onFieldChanged(int index) {
    if (_autoStartEnabled && _isPageMode) _tryAutoFillNext(index);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _validate(); _notify();
    });
  }

  /// 현재 행의 끝값 → 다음 활성 행에 시작값 자동 채우기
  void _tryAutoFillNext(int index) {
    final endVal = ManualPlanValidator.parseRangeField(
        _rangeCtrls[index].text)?.$2;
    if (endVal == null) return;
    int? nxt; // 다음 활성 행 찾기
    for (var i = index + 1; i < _dates.length; i++) {
      if (!_restDays[i]) { nxt = i; break; }
    }
    if (nxt == null) return;
    final nc = _rangeCtrls[nxt];
    if (nc.text.isEmpty || RegExp(r'^\d+,$').hasMatch(nc.text)) {
      nc.text = '${endVal + 1},';
    }
  }

  /// 자동입력 필드 탭 → 커서를 끝(쉼표 뒤)에 배치
  void _onRangeFieldTap(int i) {
    if (!_autoStartEnabled) return;
    final c = _rangeCtrls[i];
    if (c.text.endsWith(',')) {
      c.selection = TextSelection.collapsed(offset: c.text.length);
    }
  }

  void _validate() {
    final result = _isPageMode
        ? ManualPlanValidator.validatePageModeSingleField(
            rangeTexts: _rangeCtrls.map((c) => c.text).toList(),
            restDays: _restDays, totalPages: widget.totalAmount,
            dates: _dates)
        : ManualPlanValidator.validateChapterMode(
            chapters: _chapterCtrls.map((c) => int.tryParse(c.text)).toList(),
            restDays: _restDays, totalChapters: widget.totalAmount,
            dates: _dates);
    setState(() => _validation = result);
    widget.onValidChanged(result.isValid);
  }

  void _notify() {
    final entries = <ManualPlanEntry>[];
    for (var i = 0; i < _dates.length; i++) {
      if (_isPageMode) {
        final p = ManualPlanValidator.parseRangeField(_rangeCtrls[i].text);
        entries.add(ManualPlanEntry(date: _dates[i],
            startPage: p?.$1 ?? 0, endPage: p?.$2 ?? 0,
            isRestDay: _restDays[i]));
      } else {
        entries.add(ManualPlanEntry(date: _dates[i],
            chapter: int.tryParse(_chapterCtrls[i].text) ?? 0,
            isRestDay: _restDays[i]));
      }
    }
    widget.onChanged(entries);
  }

  void _toggleRestDay(int i, bool v) { setState(() => _restDays[i] = v); _onFieldChanged(i); }

  @override
  Widget build(BuildContext context) {
    final total = _dates.length;
    final rest = _restDays.where((r) => r).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ManualPlanSummaryHeader(totalDays: total, activeDays: total - rest,
          totalAmount: widget.totalAmount, isPageMode: _isPageMode),
      if (_isPageMode) _buildAutoStartCheckbox(context),
      const SizedBox(height: AppSpacing.md),
      if (_validation.summaryErrors.isNotEmpty)
        ManualPlanErrorSummary(errors: _validation.summaryErrors),
      ...List.generate(_dates.length, _buildRow),
    ]);
  }

  /// 시작값 자동입력 체크박스
  Widget _buildAutoStartCheckbox(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => setState(() => _autoStartEnabled = !_autoStartEnabled),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 20, height: 20, child: Checkbox(
            value: _autoStartEnabled,
            onChanged: (v) => setState(() => _autoStartEnabled = v ?? true),
            activeColor: ColorTokens.main,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          const SizedBox(width: AppSpacing.xs),
          Text('시작값 자동입력', style: AppTypography.captionMd.copyWith(
              color: ctx.themeColors.textPrimary)),
        ]),
      ),
    );
  }

  Widget _buildRow(int i) {
    final errs = _validation.errorsForRow(i);
    if (_isPageMode) {
      return ManualPageRow(date: _dates[i], rangeCtrl: _rangeCtrls[i],
          isRestDay: _restDays[i],
          onRestDayChanged: (v) => _toggleRestDay(i, v),
          onChanged: () => _onFieldChanged(i),
          onTap: () => _onRangeFieldTap(i), errors: errs);
    }
    return ManualChapterRow(date: _dates[i], chapterCtrl: _chapterCtrls[i],
        isRestDay: _restDays[i],
        onRestDayChanged: (v) => _toggleRestDay(i, v),
        onChanged: () => _onFieldChanged(i), errors: errs);
  }
}
