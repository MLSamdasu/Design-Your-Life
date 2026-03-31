// F-Book: 책 생성 다이얼로그 — BottomSheet 폼 (자동/수동 분배)
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
import '../../services/reading_plan_generator.dart';
import 'book_create_form_fields.dart';
import 'book_form_widgets.dart';
import 'manual_section_builder.dart';

/// 책 생성 다이얼로그 (BottomSheet)
class BookCreateDialog extends ConsumerStatefulWidget {
  const BookCreateDialog({super.key});
  @override
  ConsumerState<BookCreateDialog> createState() => _State();
}

class _State extends ConsumerState<BookCreateDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '1');
  TrackingMode _mode = TrackingMode.pages;
  DistributionMode _distMode = DistributionMode.auto;
  late DateTime _startDate;
  DateTime? _targetDate;
  bool _hasExam = false;
  DateTime? _examDate;
  List<ManualPlanEntry> _manualEntries = [];
  bool _isManualValid = false;

  @override
  void initState() { super.initState(); _startDate = DateTime.now(); }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _descCtrl, _totalCtrl, _daysCtrl]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height *
            AppLayout.dialogMaxHeightRatio,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.gray900,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomSheet)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _handle(context),
        _header(context, '새 책 등록'),
        const SizedBox(height: AppSpacing.lg),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(AppSpacing.dialogPadding, 0,
                AppSpacing.dialogPadding, bottom + AppSpacing.xxxl),
            child: _buildBody(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.dialogPadding),
          child: GlassButton(
              label: '저장', fullWidth: true,
              onTap: _save, leadingIcon: Icons.check_rounded),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    final total = int.tryParse(_totalCtrl.text.trim()) ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      BookCreateFormFields(
        titleController: _titleCtrl, descController: _descCtrl,
        totalController: _totalCtrl, daysPerChapterController: _daysCtrl,
        trackingMode: _mode,
        onTrackingModeChanged: (m) => setState(() => _mode = m),
        startDate: _startDate,
        onStartDateTap: () => _pick(_startDate, (d) => _startDate = d),
        targetDate: _targetDate,
        onTargetDateTap: () => _pick(
            _targetDate ?? DateTime.now().add(const Duration(days: 30)),
            (d) => _targetDate = d),
        hasExam: _hasExam,
        onHasExamChanged: (v) => setState(() {
          _hasExam = v; if (!v) _examDate = null;
        }),
        examDate: _examDate,
        onExamDateTap: () => _pick(
            _examDate ?? DateTime.now().add(const Duration(days: 14)),
            (d) => _examDate = d),
      ),
      const SizedBox(height: AppSpacing.xl),
      DistributionModeToggle(
          mode: _distMode,
          onChanged: (m) => setState(() => _distMode = m)),
      if (_distMode == DistributionMode.manual) ...[
        const SizedBox(height: AppSpacing.xl),
        ManualSectionBuilder(
          startDate: _startDate,
          targetDate: _targetDate,
          totalAmount: total,
          trackingMode: _mode,
          onEntriesChanged: (e) => _manualEntries = e,
          onValidChanged: (v) => setState(() => _isManualValid = v),
        ),
      ],
    ]);
  }

  Widget _handle(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      width: AppLayout.minTouchTarget, height: AppSpacing.xs,
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.20),
        borderRadius: BorderRadius.circular(AppRadius.sm)),
    ),
  );

  Widget _header(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.dialogPadding),
    child: Row(children: [
      Expanded(child: Text(title,
          style: AppTypography.headingSm
              .copyWith(color: context.themeColors.textPrimary))),
      IconButton(
        icon: Icon(Icons.close_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.7)),
        onPressed: () => Navigator.of(context).pop()),
    ]),
  );

  Future<void> _pick(DateTime init, void Function(DateTime) set) async {
    final d = await showDatePicker(context: context, initialDate: init,
        firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (d != null && mounted) setState(() => set(d));
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      AppSnackBar.showError(context, '책 제목을 입력해주세요'); return;
    }
    final total = int.tryParse(_totalCtrl.text.trim());
    if (total == null || total <= 0) {
      AppSnackBar.showError(context,
          _mode == TrackingMode.pages ? '총 페이지 수를 입력해주세요' : '총 챕터 수를 입력해주세요');
      return;
    }
    if (_targetDate == null) {
      AppSnackBar.showError(context, '목표일을 선택해주세요'); return;
    }
    if (_distMode == DistributionMode.manual && !_isManualValid) {
      AppSnackBar.showError(context, '날짜별 입력에 오류가 있습니다'); return;
    }
    final now = DateTime.now();
    final book = Book(
      id: '', title: title,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      totalPages: _mode == TrackingMode.pages ? total : 0,
      totalChapters: _mode == TrackingMode.chapters ? total : 0,
      trackingMode: _mode == TrackingMode.pages ? 'page' : 'chapter',
      startDate: _startDate,
      targetDate: _targetDate, examDate: _examDate,
      daysPerChapter: int.tryParse(_daysCtrl.text.trim()) ?? 1,
      createdAt: now, updatedAt: now,
    );
    if (_distMode == DistributionMode.manual && _manualEntries.isNotEmpty) {
      await ref.read(createBookWithManualPlansProvider)(book, _manualEntries);
    } else {
      await ref.read(createBookProvider)(book);
    }
    if (mounted) {
      Navigator.of(context).pop();
      AppSnackBar.showSuccess(context, '"$title" 등록 완료!');
    }
  }
}
