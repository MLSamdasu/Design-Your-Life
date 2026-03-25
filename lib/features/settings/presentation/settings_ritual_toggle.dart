// F6: 데일리 리추얼 활성화 토글
// 매일 앱 시작 시 리추얼 화면 표시 여부를 설정한다.
// settings_cards.dart에서 SRP 분리하여 200줄 제한을 준수한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';

/// 데일리 리추얼 활성화 토글
/// 매일 앱 시작 시 리추얼 화면 표시 여부를 설정한다
class DailyRitualToggle extends ConsumerWidget {
  const DailyRitualToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(dailyRitualEnabledProvider);
    final tc = context.themeColors;

    return Row(
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          color: tc.textPrimary,
          size: AppLayout.iconXl,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '데일리 리추얼',
                style: AppTypography.bodyLg.copyWith(color: tc.textPrimary),
              ),
              Text(
                '매일 앱 시작 시 목표와 할 일을 설정합니다',
                style: AppTypography.bodySm.copyWith(
                  color: tc.textPrimaryWithAlpha(0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: enabled,
          onChanged: (value) {
            ref.read(dailyRitualEnabledProvider.notifier).state = value;
            ref.read(hiveCacheServiceProvider).saveSetting(
                  AppConstants.settingsKeyDailyRitualEnabled,
                  value,
                );
          },
          activeThumbColor: tc.accent,
          activeTrackColor: tc.accentWithAlpha(0.3),
          inactiveThumbColor: tc.textPrimaryWithAlpha(0.7),
          inactiveTrackColor: tc.textPrimaryWithAlpha(0.2),
        ),
      ],
    );
  }
}
