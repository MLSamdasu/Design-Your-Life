// 공통 헬퍼: 이벤트 폼 라벨 스타일
// SRP 분리: 여러 폼 섹션 위젯에서 재사용하는 라벨 빌더
import 'package:flutter/material.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 폼 필드 라벨 공통 스타일 (여러 폼 섹션에서 재사용)
Widget eventFormLabel(BuildContext context, String text) => Text(
      text,
      style: AppTypography.captionLg.copyWith(
        color: context.themeColors.textPrimaryWithAlpha(0.70),
      ),
    );
