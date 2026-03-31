// F-Book: 책 수정 다이얼로그 — BottomSheet로 표시되는 책 편집 폼
// 기존 Book 데이터를 pre-fill하며, 저장 시 계획 재생성 옵션을 제공한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import 'book_create_form_fields.dart';

/// 책 수정 다이얼로그 (BottomSheet)
class BookEditDialog extends ConsumerStatefulWidget {
  final Book book;
  const BookEditDialog({super.key, required this.book});
  @override
  ConsumerState<BookEditDialog> createState() => _State();
}

class _State extends ConsumerState<BookEditDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _daysCtrl;
  late TrackingMode _mode;
  late DateTime _startDate;
  DateTime? _targetMonth;
  late bool _hasExam;
  DateTime? _examDate;
  bool _regenerate = false;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titleCtrl = TextEditingController(text: b.title);
    _descCtrl = TextEditingController(text: b.description ?? '');
    _mode = b.trackingMode == 'chapter' ? TrackingMode.chapters : TrackingMode.pages;
    _totalCtrl = TextEditingController(
        text: _mode == TrackingMode.pages ? '${b.totalPages}' : '${b.totalChapters}');
    _daysCtrl = TextEditingController(text: '${b.daysPerChapter}');
    _startDate = b.startDate;
    _targetMonth = _parseMonth(b.targetMonth);
    _hasExam = b.examDate != null;
    _examDate = b.examDate;
  }

  DateTime? _parseMonth(String? s) {
    if (s == null || s.isEmpty) return null;
    final p = s.split('-');
    if (p.length != 2) return null;
    final y = int.tryParse(p[0]), m = int.tryParse(p[1]);
    return (y != null && m != null) ? DateTime(y, m) : null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _totalCtrl.dispose(); _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * AppLayout.dialogMaxHeightRatio),
      decoration: BoxDecoration(
        color: ColorTokens.gray900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _handle(context),
        _header(context),
        const SizedBox(height: AppSpacing.lg),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.dialogPadding, 0, AppSpacing.dialogPadding, bottom + AppSpacing.xxxl),
            child: Column(children: [
              BookCreateFormFields(
                titleController: _titleCtrl, descController: _descCtrl,
                totalController: _totalCtrl, daysPerChapterController: _daysCtrl,
                trackingMode: _mode,
                onTrackingModeChanged: (m) => setState(() => _mode = m),
                startDate: _startDate,
                onStartDateTap: () => _pick(_startDate, (d) => _startDate = d),
                targetMonth: _targetMonth,
                onTargetMonthTap: () => _pick(
                    _targetMonth ?? DateTime.now().add(const Duration(days: 30)),
                    (d) => _targetMonth = DateTime(d.year, d.month)),
                hasExam: _hasExam,
                onHasExamChanged: (v) => setState(() { _hasExam = v; if (!v) _examDate = null; }),
                examDate: _examDate,
                onExamDateTap: () => _pick(
                    _examDate ?? DateTime.now().add(const Duration(days: 14)), (d) => _examDate = d),
              ),
              const SizedBox(height: AppSpacing.xl),
              _RegenerateToggle(value: _regenerate,
                  onChanged: (v) => setState(() => _regenerate = v)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.dialogPadding),
          child: GlassButton(label: '수정 완료', fullWidth: true,
              onTap: _save, leadingIcon: Icons.check_rounded),
        ),
      ]),
    );
  }

  Widget _handle(BuildContext context) => Center(child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.lg),
        width: AppLayout.minTouchTarget, height: AppSpacing.xs,
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.20),
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      ));

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.dialogPadding),
        child: Row(children: [
          Expanded(child: Text('책 수정',
              style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary))),
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: context.themeColors.textPrimaryWithAlpha(0.7)),
            onPressed: () => Navigator.of(context).pop()),
        ]),
      );

  Future<void> _pick(DateTime init, void Function(DateTime) setter) async {
    final d = await showDatePicker(
        context: context, initialDate: init,
        firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null && mounted) setState(() => setter(d));
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) { AppSnackBar.showError(context, '책 제목을 입력해주세요'); return; }
    final total = int.tryParse(_totalCtrl.text.trim());
    if (total == null || total <= 0) {
      AppSnackBar.showError(context,
          _mode == TrackingMode.pages ? '총 페이지 수를 입력해주세요' : '총 챕터 수를 입력해주세요');
      return;
    }
    final tStr = _targetMonth != null
        ? '${_targetMonth!.year}-${_targetMonth!.month.toString().padLeft(2, '0')}' : null;
    final updated = widget.book.copyWith(
      title: title,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      totalPages: _mode == TrackingMode.pages ? total : 0,
      totalChapters: _mode == TrackingMode.chapters ? total : 0,
      trackingMode: _mode == TrackingMode.pages ? 'page' : 'chapter',
      startDate: _startDate, targetMonth: tStr, examDate: _examDate,
      daysPerChapter: int.tryParse(_daysCtrl.text.trim()) ?? 1,
      updatedAt: DateTime.now(),
    );
    if (_regenerate) {
      await ref.read(updateBookAndRegeneratePlansProvider)(widget.book.id, updated);
    } else {
      await ref.read(updateBookProvider)(widget.book.id, updated);
    }
    if (mounted) { Navigator.of(context).pop(); AppSnackBar.showSuccess(context, '"$title" 수정 완료!'); }
  }
}

/// 독서 계획 재생성 토글
class _RegenerateToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _RegenerateToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('독서 계획 재생성',
            style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary)),
        Text('페이지/일정 변경 시 기존 계획을 새로 배분합니다',
            style: AppTypography.captionMd
                .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.55))),
      ])),
      Switch(value: value, onChanged: onChanged,
          activeTrackColor: ColorTokens.main.withValues(alpha: 0.5),
          activeThumbColor: ColorTokens.main),
    ]);
  }
}
