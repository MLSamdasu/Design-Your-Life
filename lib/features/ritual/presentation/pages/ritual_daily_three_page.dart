// 데일리 리추얼 Page 9: 오늘의 3가지 입력 페이지
// 오늘 반드시 완수할 3가지 할 일을 입력한다.
// 각 필드에 아이콘을 붙여 시각적으로 구분한다.

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../widgets/daily_three_field.dart';
import '../widgets/ritual_glass_container.dart';

/// 오늘의 3가지 입력 페이지 (Page 9)
/// [controllers]: 3개의 TextEditingController
/// [onChanged]: 텍스트 변경 콜백 (index, text)
class RitualDailyThreePage extends StatelessWidget {
  final List<TextEditingController> controllers;
  final void Function(int index, String text)? onChanged;

  const RitualDailyThreePage({
    super.key,
    required this.controllers,
    this.onChanged,
  });

  /// 각 필드에 표시할 아이콘 (1번: 별, 2번: 불꽃, 3번: 타겟)
  static const _icons = [
    Icons.star_rounded,
    Icons.local_fire_department_rounded,
    Icons.gps_fixed_rounded,
  ];

  /// 각 필드의 힌트 텍스트
  static const _hints = [
    '가장 중요한 할 일',
    '두 번째로 중요한 할 일',
    '세 번째로 중요한 할 일',
  ];

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    // 부모(DailyRitualScreen)에서 SafeArea + 상하 패딩을 이미 적용한다
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildHeader(tc),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: RitualGlassContainer(
              child: _buildFields(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  /// 페이지 헤더
  Widget _buildHeader(ResolvedThemeColors tc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "오늘의 3가지",
          style: AppTypography.headingLg.copyWith(
            color: tc.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '오늘 반드시 완수할 할 일을 적어주세요',
          style: AppTypography.bodySm.copyWith(
            color: tc.textPrimaryWithAlpha(0.55),
          ),
        ),
      ],
    );
  }

  /// 3개의 할 일 입력 필드
  Widget _buildFields() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: i < 2 ? AppSpacing.xl : 0,
          ),
          child: DailyThreeField(
            icon: _icons[i],
            hint: _hints[i],
            controller: controllers[i],
            onChanged: (text) => onChanged?.call(i, text),
          ),
        );
      }),
    );
  }
}
