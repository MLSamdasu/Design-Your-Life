// F1: 리추얼 요약 카드 — Top 5 목표 + 진행률 컬럼
// 리추얼 TOP 5 목표 텍스트와 Goal 연동 진행률을 표시한다.
import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 리추얼 요약 카드 좌측 컬럼: Top 5 목표 + 진행률
class RitualTop5Column extends StatelessWidget {
  /// Top 5 목표 텍스트 목록 (최대 5개)
  final List<String> top5Texts;

  /// 목표 텍스트 → 진행률 (0.0~1.0) 매핑, null이면 Goal 미연결
  final Map<String, double?> progressMap;

  const RitualTop5Column({
    super.key,
    required this.top5Texts,
    required this.progressMap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    // 유효한 목표만 필터링 (빈 문자열 제외)
    final validGoals =
        top5Texts.where((t) => t.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 제목
        Text(
          'TOP 5 목표',
          style: AppTypography.captionLg.copyWith(
            color: tc.textPrimaryWithAlpha(0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // 목표 리스트
        if (validGoals.isEmpty)
          _buildEmptyState(tc)
        else
          ...validGoals.asMap().entries.map(
                (entry) => _buildGoalRow(
                  tc,
                  index: entry.key + 1,
                  title: entry.value.trim(),
                  progress: progressMap[entry.value.trim()],
                ),
              ),
        // 전체 달성률 표시
        if (validGoals.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildOverallProgress(tc),
        ],
      ],
    );
  }

  /// 빈 상태 (Top 5 미설정)
  Widget _buildEmptyState(ResolvedThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        'Top 5 목표를 설정해주세요',
        style: AppTypography.bodySm.copyWith(
          color: tc.textPrimaryWithAlpha(0.40),
        ),
      ),
    );
  }

  /// 개별 목표 행 (번호 + 제목 + 진행률)
  Widget _buildGoalRow(
    ResolvedThemeColors tc, {
    required int index,
    required String title,
    required double? progress,
  }) {
    // 진행률 텍스트 결정
    final progressText = progress == null
        ? '—'
        : '${(progress * 100).round()}%';
    // 진행률 색상 결정
    final progressColor = progress == null
        ? tc.textPrimaryWithAlpha(0.35)
        : progress >= 1.0
            ? const Color(0xFF22C55E)
            : tc.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          // 번호
          SizedBox(
            width: 18,
            child: Text(
              '$index.',
              style: AppTypography.bodySm.copyWith(
                color: tc.textPrimaryWithAlpha(0.50),
              ),
            ),
          ),
          // 목표 제목
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySm.copyWith(
                color: tc.textPrimaryWithAlpha(0.80),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 진행률
          Text(
            progressText,
            style: AppTypography.captionLg.copyWith(
              color: progressColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 전체 달성률 평균 표시
  Widget _buildOverallProgress(ResolvedThemeColors tc) {
    // 매칭된 목표만 평균 계산 (null 제외)
    final matched = progressMap.values
        .where((v) => v != null)
        .cast<double>()
        .toList();
    final avg = matched.isEmpty
        ? 0.0
        : matched.reduce((a, b) => a + b) / matched.length;

    return Row(
      children: [
        Text(
          '전체 달성률: ',
          style: AppTypography.captionLg.copyWith(
            color: tc.textPrimaryWithAlpha(0.55),
          ),
        ),
        Text(
          '${(avg * 100).round()}%',
          style: AppTypography.captionLg.copyWith(
            color: tc.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
