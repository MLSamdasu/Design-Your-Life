// F6: 설정 화면 상단 헤더
// 타이틀과 닫기 버튼을 표시한다.
// settings_screen.dart에서 SRP 분리하여 200줄 제한을 준수한다.
import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 설정 화면 상단 헤더 (타이틀 + 닫기 버튼)
class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '설정',
          style: AppTypography.headingSm.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        const Spacer(),
        // 모달 닫기 버튼
        // WCAG 2.1 기준 최소 터치 타겟 44x44px 적용
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: AppLayout.minTouchTarget,
            height: AppLayout.minTouchTarget,
            child: Center(
              child: Container(
                width: AppLayout.containerMd,
                height: AppLayout.containerMd,
                decoration: BoxDecoration(
                  color: context.themeColors.overlayMedium,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.80),
                  size: AppLayout.iconLg,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
