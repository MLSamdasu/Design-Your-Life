// F-Book: 수동 분배 폼 — 날짜별 페이지 범위를 직접 입력
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/utils/date_utils.dart';
import '../../services/reading_plan_generator.dart';

/// 수동 분배 폼 위젯
class ManualPlanForm extends StatefulWidget {
  final List<ManualPlanEntry> entries;
  final ValueChanged<List<ManualPlanEntry>> onChanged;
  const ManualPlanForm({super.key, required this.entries, required this.onChanged});
  @override
  State<ManualPlanForm> createState() => _FormState();
}

class _FormState extends State<ManualPlanForm> {
  late List<_R> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.entries.isEmpty
        ? [_R(date: DateTime.now())]
        : widget.entries.map((e) => _R(
            date: e.date,
            s: TextEditingController(text: '${e.startPage}'),
            e: TextEditingController(text: '${e.endPage}'),
          )).toList();
  }

  @override
  void dispose() {
    for (final r in _rows) { r.s.dispose(); r.e.dispose(); }
    super.dispose();
  }

  void _add() {
    setState(() {
      final last = _rows.isNotEmpty
          ? _rows.last.date.add(const Duration(days: 1)) : DateTime.now();
      _rows.add(_R(date: last));
    });
    _notify();
  }

  void _remove(int i) {
    if (_rows.length <= 1) return;
    setState(() { _rows[i].s.dispose(); _rows[i].e.dispose(); _rows.removeAt(i); });
    _notify();
  }

  void _notify() {
    widget.onChanged(_rows.map((r) => ManualPlanEntry(
      date: r.date,
      startPage: int.tryParse(r.s.text) ?? 0,
      endPage: int.tryParse(r.e.text) ?? 0,
    )).toList());
  }

  Future<void> _pickDate(int i) async {
    final d = await showDatePicker(context: context, initialDate: _rows[i].date,
        firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null && mounted) { setState(() => _rows[i].date = d); _notify(); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('날짜별 페이지 범위', style: AppTypography.captionLg
          .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.7))),
      const SizedBox(height: AppSpacing.md),
      ...List.generate(_rows.length, (i) => _Row(
          row: _rows[i], onDate: () => _pickDate(i),
          onRemove: _rows.length > 1 ? () => _remove(i) : null,
          onChanged: _notify)),
      const SizedBox(height: AppSpacing.md),
      _AddBtn(onTap: _add),
    ]);
  }
}

class _R {
  DateTime date;
  final TextEditingController s;
  final TextEditingController e;
  _R({required this.date, TextEditingController? s, TextEditingController? e})
      : s = s ?? TextEditingController(), e = e ?? TextEditingController();
}

class _Row extends StatelessWidget {
  final _R row;
  final VoidCallback onDate;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;
  const _Row({required this.row, required this.onDate, this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(children: [
        GestureDetector(
          onTap: onDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.mdLg),
            decoration: BoxDecoration(
              color: context.themeColors.overlayLight,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: context.themeColors.textPrimaryWithAlpha(0.2)),
            ),
            child: Text(AppDateUtils.toShortDate(row.date),
                style: AppTypography.captionLg.copyWith(color: context.themeColors.textPrimary)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _Num(ctrl: row.s, hint: '시작', onChanged: onChanged)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text('~', style: AppTypography.bodyMd
                .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.55)))),
        Expanded(child: _Num(ctrl: row.e, hint: '끝', onChanged: onChanged)),
        if (onRemove != null)
          GestureDetector(onTap: onRemove, child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Icon(Icons.remove_circle_outline_rounded,
                size: 20, color: ColorTokens.error.withValues(alpha: 0.7)),
          )),
      ]),
    );
  }
}

class _Num extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final VoidCallback onChanged;
  const _Num({required this.ctrl, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl, keyboardType: TextInputType.number,
      style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint, isDense: true,
        hintStyle: AppTypography.captionMd
            .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.35)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.mdLg),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: BorderSide(color: context.themeColors.textPrimaryWithAlpha(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input),
            borderSide: const BorderSide(color: ColorTokens.main)),
        filled: true, fillColor: context.themeColors.overlayLight,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: ColorTokens.main.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_rounded, size: 18, color: ColorTokens.main),
          const SizedBox(width: AppSpacing.sm),
          Text('날짜 추가', style: AppTypography.bodyMd.copyWith(color: ColorTokens.main)),
        ]),
      ),
    );
  }
}
