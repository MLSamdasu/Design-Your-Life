// F17: Google Calendar 연동 토글 타일
// ON 시 Calendar 읽기 스코프를 점진적으로 요청하고, 승인 시 활성화한다.
// OFF 시 설정만 비활성화한다 (스코프 취소는 Google 계정 설정에서 수행).
// settings_data_card.dart에서 SRP 분리하여 200줄 제한을 준수한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/sync/calendar_sync_provider.dart';
import '../../calendar/sync/google_calendar_service.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../shared/widgets/app_snack_bar.dart';

/// Google Calendar 연동 ON/OFF 토글 타일
/// ON 시: Calendar 읽기 스코프를 점진적으로 요청하고 승인 시 활성화한다
/// OFF 시: 설정만 비활성화한다 (스코프 취소는 Google 계정 설정에서 수행)
class GoogleCalendarSyncTile extends ConsumerWidget {
  final bool enabled;
  final CalendarSyncStatus status;

  const GoogleCalendarSyncTile({
    super.key,
    required this.enabled,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Google 'G' 아이콘 뱃지
        Container(
          width: AppLayout.iconXl,
          height: AppLayout.iconXl,
          decoration: BoxDecoration(
            color: ColorTokens.googleBrand.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: Text(
              'G',
              // captionMd: 11px Regular 기반에 볼드 적용 (Google 브랜드 마크)
              style: AppTypography.captionMd.copyWith(
                color: ColorTokens.googleBrand,
                fontWeight: AppTypography.weightBold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // 레이블 + 동기화 상태 텍스트
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Google Calendar 연동',
                style: AppTypography.bodyLg.copyWith(
                  color: context.themeColors.textPrimary,
                ),
              ),
              // 오류 상태 표시
              if (status == CalendarSyncStatus.error)
                Text(
                  '동기화 실패',
                  style: AppTypography.captionMd.copyWith(
                    color: ColorTokens.error,
                  ),
                ),
              // 동기화 진행 중 표시
              if (status == CalendarSyncStatus.syncing)
                Text(
                  '동기화 중...',
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.5),
                  ),
                ),
              // 읽기 전용 안내 부제 (오류/동기화 중이 아닐 때 표시)
              if (status != CalendarSyncStatus.error &&
                  status != CalendarSyncStatus.syncing)
                Text(
                  '구글 캘린더의 일정을 읽어옵니다 (읽기 전용)',
                  style: AppTypography.captionSm.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.45),
                  ),
                ),
            ],
          ),
        ),
        // 연동 ON/OFF 스위치
        // 배경 테마에 맞는 악센트 색상으로 스위치를 표시한다
        Switch(
          value: enabled,
          onChanged: (value) => _handleToggle(context, ref, value),
          activeThumbColor: context.themeColors.accent,
          activeTrackColor: context.themeColors.accentWithAlpha(0.3),
          inactiveThumbColor: context.themeColors.textPrimaryWithAlpha(0.7),
          inactiveTrackColor: context.themeColors.textPrimaryWithAlpha(0.2),
        ),
      ],
    );
  }

  /// 토글 상태 변경 처리
  /// ON: 안내 다이얼로그 → 확인 → Calendar 스코프 요청 → 승인 시 활성화 및 즉시 동기화
  /// OFF: 설정 비활성화 (Hive 저장)
  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    if (value) {
      // 연동 전 안내 다이얼로그를 표시하여 읽기 전용임을 알린다
      final confirmed = await _showSyncConfirmDialog(context);
      if (!confirmed) return;

      // 사용자가 연동을 켤 때 Calendar 읽기 스코프를 요청한다
      final service = ref.read(googleCalendarServiceProvider);
      final granted = await service.requestAccess();

      if (!granted) {
        // 사용자가 권한을 거부한 경우 토글을 변경하지 않고 안내 메시지를 표시한다
        if (context.mounted) {
          AppSnackBar.showWarning(
            context,
            'Google Calendar 접근 권한이 필요합니다',
          );
        }
        return;
      }
    }

    // 설정값을 Provider 상태와 Hive에 모두 저장한다
    ref.read(googleCalendarSyncEnabledProvider.notifier).state = value;
    ref.read(hiveCacheServiceProvider).saveSetting('googleCalendarSync', value);

    // 연동을 켠 경우 즉시 동기화를 트리거한다
    if (value) {
      ref.invalidate(googleCalendarEventsProvider);
    }
  }

  /// 연동 활성화 전 안내 다이얼로그를 표시한다
  /// 읽기 전용 연동임을 사용자에게 명확히 안내한다
  Future<bool> _showSyncConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeColors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          '구글 캘린더 연동',
          style: AppTypography.headingSm.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        content: Text(
          '구글 캘린더의 일정을 읽어와서 앱 내 캘린더에 표시합니다.'
          '\n\n⚠️ 구글 캘린더의 일정을 수정하거나 삭제할 수는 없으며, '
          '읽기 전용으로 연동됩니다.',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              '취소',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '연동하기',
              style: AppTypography.bodyMd.copyWith(
                color: context.themeColors.accent,
                fontWeight: AppTypography.weightSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
