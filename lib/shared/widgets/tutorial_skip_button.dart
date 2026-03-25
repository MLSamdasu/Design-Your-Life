// 튜토리얼 건너뛰기 버튼 위젯
// 오버레이 상단에 표시되며, 탭 시 튜토리얼을 즉시 종료한다.
// SRP 분리: 건너뛰기 버튼 UI만 담당한다.
import 'package:flutter/material.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/typography_tokens.dart';

/// 튜토리얼 건너뛰기 버튼
/// 상단 우측에 반투명 캡슐 형태로 표시된다
class TutorialSkipButton extends StatelessWidget {
  /// 건너뛰기 탭 시 호출되는 콜백
  final VoidCallback onSkip;

  const TutorialSkipButton({required this.onSkip, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: ColorTokens.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.huge),
              ),
              child: Text(
                '건너뛰기',
                style: AppTypography.bodyMd.copyWith(
                  color: ColorTokens.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
