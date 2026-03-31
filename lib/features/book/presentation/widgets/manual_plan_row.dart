// F-Book: 수동 분배 행 위젯 — 날짜별 한 칸 입력 행을 렌더링한다
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/utils/date_utils.dart';

/// 페이지 모드 행: 날짜 + 한 칸 범위 입력(시작,끝) + 쉬는날 토글
class ManualPageRow extends StatelessWidget {
  final DateTime date;
  final TextEditingController rangeCtrl;
  final bool isRestDay;
  final ValueChanged<bool> onRestDayChanged;
  final VoidCallback onChanged;
  final VoidCallback? onTap;
  final List<String> errors;

  const ManualPageRow({
    super.key, required this.date, required this.rangeCtrl,
    required this.isRestDay, required this.onRestDayChanged,
    required this.onChanged, this.onTap, this.errors = const [],
  });

  @override
  Widget build(BuildContext context) {
    return _RowShell(
        date: date, isRestDay: isRestDay,
        onRestDayChanged: onRestDayChanged, errors: errors,
        child: !isRestDay
            ? _buildField(context, rangeCtrl, '시작,끝',
                TextInputType.text, onChanged, onTap,
                formatters: [FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9,/]'))])
            : null);
  }
}

/// 챕터 모드 행: 날짜 + 챕터번호 + 쉬는날 토글
class ManualChapterRow extends StatelessWidget {
  final DateTime date;
  final TextEditingController chapterCtrl;
  final bool isRestDay;
  final ValueChanged<bool> onRestDayChanged;
  final VoidCallback onChanged;
  final List<String> errors;

  const ManualChapterRow({
    super.key, required this.date, required this.chapterCtrl,
    required this.isRestDay, required this.onRestDayChanged,
    required this.onChanged, this.errors = const [],
  });

  @override
  Widget build(BuildContext context) {
    return _RowShell(
        date: date, isRestDay: isRestDay,
        onRestDayChanged: onRestDayChanged, errors: errors,
        child: !isRestDay
            ? _buildField(context, chapterCtrl, '챕터',
                TextInputType.number, onChanged, null)
            : null);
  }
}

// ─── 공용 내부 위젯/함수 ────────────────────────────────────────────

/// 입력 필드 공통 빌더 — 페이지/챕터 모드 공유
Widget _buildField(BuildContext ctx, TextEditingController ctrl, String hint,
    TextInputType keyType, VoidCallback onChanged, VoidCallback? onTap,
    {List<TextInputFormatter>? formatters}) {
  final dim = ctx.themeColors.textPrimaryWithAlpha(0.2);
  return TextField(
    controller: ctrl, keyboardType: keyType,
    inputFormatters: formatters,
    style: AppTypography.bodyMd.copyWith(color: ctx.themeColors.textPrimary),
    textAlign: TextAlign.center,
    decoration: InputDecoration(
      hintText: hint, isDense: true,
      hintStyle: AppTypography.captionMd.copyWith(
          color: ctx.themeColors.textPrimaryWithAlpha(0.35)),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: dim)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: dim)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: ColorTokens.main)),
      filled: true, fillColor: ctx.themeColors.overlayLight,
    ),
    onTap: onTap,
    onChanged: (_) => onChanged(),
  );
}

/// 행 공통 껍데기: 날짜라벨 + 쉬는날 토글 + 내용 + 에러
class _RowShell extends StatelessWidget {
  final DateTime date;
  final bool isRestDay;
  final ValueChanged<bool> onRestDayChanged;
  final List<String> errors;
  final Widget? child;

  const _RowShell({
    required this.date, required this.isRestDay,
    required this.onRestDayChanged, required this.errors, this.child,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.themeColors.textPrimary;
    final dim = context.themeColors.textPrimaryWithAlpha(0.5);
    final weekday = AppDateUtils.toWeekdayShort(date);
    final label = '${date.month}/${date.day} ($weekday)';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 72, child: Text(label,
              style: AppTypography.captionLg.copyWith(
                  color: isRestDay ? dim : text))),
          GestureDetector(
            onTap: () => onRestDayChanged(!isRestDay),
            child: Icon(
              isRestDay ? Icons.hotel_rounded : Icons.menu_book_rounded,
              size: 18,
              color: isRestDay
                  ? ColorTokens.main.withValues(alpha: 0.6)
                  : dim.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: child ?? Text('쉬는 날',
              style: AppTypography.captionMd.copyWith(
                  color: dim, fontStyle: FontStyle.italic))),
        ]),
        for (final err in errors)
          Padding(
            padding: const EdgeInsets.only(left: 72, top: AppSpacing.xs),
            child: Text(err, style: AppTypography.captionSm.copyWith(
                color: ColorTokens.error)),
          ),
      ]),
    );
  }
}
