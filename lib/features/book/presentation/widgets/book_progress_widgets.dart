// F-Book: 진행률 + 완독 배너 위젯
// BookDetailScreen에서 사용하는 진행률 섹션과 완독 축하 배너
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../models/book.dart';

/// 진행률 섹션 (큰 프로그레스 바 + 퍼센트)
class BookProgressSection extends StatelessWidget {
  final double progress;
  final Book book;

  const BookProgressSection({
    super.key,
    required this.progress,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final total = book.trackingMode == 'chapter'
        ? book.totalChapters : book.totalPages;
    final unitLabel = book.trackingMode == 'chapter' ? '챕터' : '페이지';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('$percent%',
              style: AppTypography.headingLg.copyWith(color: ColorTokens.main)),
          const Spacer(),
          Text('${book.currentProgress} / $total $unitLabel',
              style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.55))),
        ]),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: AppSpacing.mdLg,
            backgroundColor: context.themeColors.textPrimaryWithAlpha(0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(ColorTokens.main),
          ),
        ),
      ],
    );
  }
}

/// 완독 축하 배너
class BookCompletionBanner extends StatelessWidget {
  final String bookTitle;
  const BookCompletionBanner({super.key, required this.bookTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: ColorTokens.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: ColorTokens.success.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(Icons.celebration_rounded,
            color: ColorTokens.success, size: AppLayout.iconXl),
        const SizedBox(height: AppSpacing.md),
        Text('$bookTitle 완독!',
            style: AppTypography.titleMd.copyWith(color: ColorTokens.success),
            textAlign: TextAlign.center),
      ]),
    );
  }
}
