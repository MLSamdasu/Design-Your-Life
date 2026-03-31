// F-Book: 책 상세 통계 위젯 — 통계 행, 시험 카운트다운, 목표일 표시
// BookDetailScreen에서 분리된 통계/정보 위젯 모음
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glassmorphic_card.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../models/book.dart';

// 진행률 + 완독 배너를 re-export한다
export 'book_progress_widgets.dart';

/// 통계 행 — 총 페이지, 진행률, 남은 일수, 일일 목표
class BookStatsRow extends StatelessWidget {
  final Book book;
  final double progress;
  const BookStatsRow({super.key, required this.book, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final daysRem = book.targetDate?.difference(DateTime.now()).inDays;
    final daily = daysRem != null && daysRem > 0
        ? ((book.totalPages * (1 - progress)) / daysRem).ceil() : null;

    return GlassmorphicCard(
      variant: GlassVariant.subtle,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Flexible(child: _Stat(label: '총 페이지', value: '${book.totalPages}')),
        Flexible(child: _Stat(label: '진행률', value: '$percent%')),
        if (daysRem != null) Flexible(child: _Stat(label: '남은 일수', value: '$daysRem일')),
        if (daily != null) Flexible(child: _Stat(label: '일일 목표', value: '${daily}p')),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: AppTypography.headingSm
          .copyWith(color: context.themeColors.textPrimary)),
      const SizedBox(height: AppSpacing.xxs),
      Text(label, style: AppTypography.captionMd
          .copyWith(color: context.themeColors.textPrimaryWithAlpha(0.55))),
    ]);
  }
}

/// 시험 카운트다운 표시
class BookExamCountdown extends StatelessWidget {
  final DateTime examDate;
  final Book book;
  const BookExamCountdown({super.key, required this.examDate, required this.book});

  @override
  Widget build(BuildContext context) {
    final d = examDate.difference(DateTime.now()).inDays;
    final p = d > 0 ? (book.totalPages / d).ceil() : book.totalPages;
    return GlassmorphicCard(
      variant: GlassVariant.subtle,
      child: Row(children: [
        Icon(Icons.school_rounded, color: ColorTokens.warning, size: AppLayout.iconLg),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: Text('시험까지 $d일 남음, 하루 $p페이지씩',
            style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary))),
      ]),
    );
  }
}

/// 목표일 표시
class BookTargetDateRow extends StatelessWidget {
  final DateTime targetDate;
  const BookTargetDateRow({super.key, required this.targetDate});

  @override
  Widget build(BuildContext context) {
    final formatted = '${targetDate.year}.'
        '${targetDate.month.toString().padLeft(2, '0')}.'
        '${targetDate.day.toString().padLeft(2, '0')}';
    return Row(children: [
      Icon(Icons.flag_rounded, color: ColorTokens.main, size: AppLayout.iconMd),
      const SizedBox(width: AppSpacing.md),
      Flexible(
        child: Text('목표일: $formatted 완독',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.7))),
      ),
    ]);
  }
}
