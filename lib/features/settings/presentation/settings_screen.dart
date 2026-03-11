// F6: 설정 화면
// 다크 모드 토글, 계정 정보, 로그아웃, 계정 삭제 기능을 제공한다.
// F16: 태그 관리 내비게이션 타일 추가
// F17: Google Calendar 연동 토글 추가
// SRP 분리: 카드 위젯 → settings_cards.dart / 액션 처리 → settings_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/calendar_sync/calendar_sync_provider.dart';
import '../../../core/calendar_sync/google_calendar_service.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../shared/widgets/glass_card.dart';
import 'settings_cards.dart';
import 'settings_theme_card.dart';
import 'widgets/cloud_backup_card.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 설정 화면 (F6)
/// 계정 정보 / 다크 모드 토글 / 로그아웃 / 계정 삭제를 제공한다
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 헤더 (타이틀 + 닫기 버튼)
              _SettingsHeader(),
              const SizedBox(height: AppSpacing.xxxl),

              // 계정 정보 카드 (이름 + 이메일)
              SettingsAccountInfoCard(authState: authState),
              const SizedBox(height: AppSpacing.xl),

              // 앱 설정 카드 (다크 모드 토글)
              SettingsAppCard(isDark: isDark),
              const SizedBox(height: AppSpacing.xl),

              // 테마 선택 카드 (4가지 프리셋 미리보기 + 선택)
              const SettingsThemeCard(),
              const SizedBox(height: AppSpacing.xl),

              // 데이터 관리 카드 (태그 관리)
              _SettingsDataCard(),
              const SizedBox(height: AppSpacing.xl),

              // 클라우드 백업 카드 (로컬 퍼스트: 로그인 시 백업/복원 활성화)
              const CloudBackupCard(),
              const SizedBox(height: AppSpacing.xl),

              // 계정 관리 카드 (로그아웃 / 계정 삭제)
              const SettingsAccountActionsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 데이터 관리 카드 ────────────────────────────────────────────────────────

/// 데이터 관리 카드 (태그 관리 + Google Calendar 연동 설정)
/// F17: Google Calendar 연동 토글을 포함하므로 ConsumerWidget으로 변경한다
class _SettingsDataCard extends ConsumerWidget {
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
          _GoogleCalendarSyncTile(
            enabled: syncEnabled,
            status: syncStatus,
          ),
        ],
      ),
    );
  }
}

// ─── Google Calendar 연동 타일 (F17) ────────────────────────────────────────

/// Google Calendar 연동 ON/OFF 토글 타일
/// ON 시: Calendar 읽기 스코프를 점진적으로 요청하고 승인 시 활성화한다
/// OFF 시: 설정만 비활성화한다 (스코프 취소는 Google 계정 설정에서 수행)
class _GoogleCalendarSyncTile extends ConsumerWidget {
  final bool enabled;
  final CalendarSyncStatus status;

  const _GoogleCalendarSyncTile({
    required this.enabled,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Google 'G' 아이콘 뱃지
        Container(
          width: 20,
          height: 20,
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
                fontWeight: FontWeight.w700,
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
                style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
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
  /// ON: Calendar 스코프 요청 → 승인 시 활성화 및 즉시 동기화
  /// OFF: 설정 비활성화 (Hive 저장)
  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    if (value) {
      // 사용자가 연동을 켤 때 Calendar 읽기 스코프를 요청한다
      final service = ref.read(googleCalendarServiceProvider);
      final granted = await service.requestAccess();

      if (!granted) {
        // 사용자가 권한을 거부한 경우 토글을 변경하지 않고 안내 메시지를 표시한다
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Calendar 접근 권한이 필요합니다'),
            ),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: context.themeColors.textPrimary, size: AppLayout.iconXl),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
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

// ─── 상단 헤더 ──────────────────────────────────────────────────────────────

/// 설정 화면 상단 헤더 (타이틀 + 닫기 버튼)
class _SettingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '설정',
          style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary),
        ),
        const Spacer(),
        // 모달 닫기 버튼
        // WCAG 2.1 기준 최소 터치 타겟 44x44px 적용
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 32,
                height: 32,
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
