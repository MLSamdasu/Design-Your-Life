// 데일리 리추얼 인트로 페이지: 설명 콘텐츠 위젯
// 첫 방문 사용자와 재방문 사용자에 따라 다른 안내 문구를 표시한다.

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 인트로 페이지 글래스 카드 내부 설명 콘텐츠
/// [isReturning]에 따라 첫 방문/재방문 사용자용 문구가 분기된다
class RitualIntroContent extends StatelessWidget {
  final bool isReturning;

  const RitualIntroContent({
    super.key,
    required this.isReturning,
  });

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    return isReturning
        ? _buildReturningContent(tc)
        : _buildFirstTimeContent(tc);
  }

  /// 재방문 사용자용 안내 문구
  Widget _buildReturningContent(ResolvedThemeColors tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '목표를 확인하고,\n변경사항이 있다면 수정하세요.',
          style: AppTypography.bodyLg.copyWith(
            color: tc.textPrimaryWithAlpha(0.85),
            height: 1.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '매일 목표를 되새기며 우선순위를 점검하세요.\n'
          '반복적으로 읽는 것만으로도\n'
          '무의식이 목표를 향해 움직입니다.',
          style: AppTypography.bodyMd.copyWith(
            color: tc.textPrimaryWithAlpha(0.65),
            height: 1.8,
          ),
        ),
      ],
    );
  }

  /// 첫 방문 사용자용 안내 문구
  Widget _buildFirstTimeContent(ResolvedThemeColors tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '25개의 목표를 작성하고,\nTOP 5를 선택하세요.',
          style: AppTypography.bodyLg.copyWith(
            color: tc.textPrimaryWithAlpha(0.85),
            height: 1.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '워렌 버핏의 25/5 법칙으로\n'
          '매일 목표를 되새기고,\n'
          '오늘 가장 중요한 3가지에 집중하세요.',
          style: AppTypography.bodyMd.copyWith(
            color: tc.textPrimaryWithAlpha(0.65),
            height: 1.8,
          ),
        ),
      ],
    );
  }
}
