// F6+F17: 데이터 관리 카드
// 태그 관리 타일과 Google Calendar 연동 토글 타일을 포함한다.
// settings_screen.dart에서 SRP 분리하여 200줄 제한을 준수한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../calendar/sync/calendar_sync_provider.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../shared/widgets/glass_card.dart';
import 'google_calendar_sync_tile.dart';

/// 데이터 관리 카드 (태그 관리 + Google Calendar 연동 설정)
/// F17: Google Calendar 연동 토글을 포함하므로 ConsumerWidget으로 구성한다
class SettingsDataCard extends ConsumerWidget {
  const SettingsDataCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncEnabled = ref.watch(googleCalendarSyncEnabledProvider);
    final syncStatus = ref.watch(calendarSyncStatusProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '데이터 관리',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 태그 관리 타일 (기존)
          _DataSettingsTile(
            icon: Icons.label_outline_rounded,
            label: '태그 관리',
            onTap: () => context.push(RoutePaths.tagManagement),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Google Calendar 연동 토글 타일 (F17 신규)
          GoogleCalendarSyncTile(
            enabled: syncEnabled,
            status: syncStatus,
          ),
        ],
      ),
    );
  }
}

/// 데이터 설정 아이템 타일
class _DataSettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DataSettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: context.themeColors.textPrimary,
              size: AppLayout.iconXl,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLg.copyWith(
                  color: context.themeColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeColors.textPrimaryWithAlpha(0.5),
              size: AppLayout.iconLg,
            ),
          ],
        ),
      ),
    );
  }
}
