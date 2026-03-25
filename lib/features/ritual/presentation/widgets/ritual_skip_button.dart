// 데일리 리추얼: 건너뛰기 버튼
// 화면 우상단에 항상 표시되며, 탭 시 현재까지 입력된 내용을 저장하고 홈으로 이동한다.
// 반투명 배경으로 콘텐츠 위에 부드럽게 떠 있는 형태이다.

import 'package:flutter/material.dart';

import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 데일리 리추얼 건너뛰기 버튼
/// [onSkip]: 건너뛰기 시 실행할 콜백 (저장 + 홈 이동)
class RitualSkipButton extends StatelessWidget {
  final VoidCallback onSkip;

  const RitualSkipButton({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return GestureDetector(
      onTap: onSkip,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: tc.overlayLight,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: tc.borderLight,
            width: 0.5,
          ),
        ),
        child: Text(
          '건너뛰기',
          style: AppTypography.bodyMd.copyWith(
            color: tc.textPrimaryWithAlpha(0.70),
          ),
        ),
      ),
    );
  }
}
