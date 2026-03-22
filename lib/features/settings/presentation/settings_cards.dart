// F6: 설정 화면 카드 위젯 모음
// AccountInfoCard, AppSettingsCard, AccountActionsCard를 SRP 분리하여 정의한다.
// settings_screen.dart가 200줄을 넘지 않도록 카드 구현을 별도 파일로 분리한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../shared/widgets/glass_card.dart';
import 'settings_actions.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

// ─── 계정 정보 카드 ─────────────────────────────────────────────────────────

/// 사용자 이름과 이메일을 표시하는 계정 정보 카드
class SettingsAccountInfoCard extends StatelessWidget {
  final AuthState authState;

  const SettingsAccountInfoCard({required this.authState, super.key});

  @override
  Widget build(BuildContext context) {
    final displayName = authState.displayName ?? '사용자';
    final email = authState.email ?? '';

    return GlassCard(
      child: Row(
        children: [
          // 프로필 아이콘 (Google 사진 미사용 시 기본 아이콘 표시)
          Container(
            width: AppLayout.iconEmpty,
            height: AppLayout.iconEmpty,
            // 프로필 아이콘 배경: 배경 테마에 맞는 악센트 색상을 사용한다
            decoration: BoxDecoration(
              color: context.themeColors.accentWithAlpha(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.themeColors.accentWithAlpha(0.5),
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: context.themeColors.textPrimary,
              size: AppLayout.iconXxl,
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          // 이름 + 이메일 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTypography.titleLg.copyWith(color: context.themeColors.textPrimary),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    email,
                    style: AppTypography.bodySm.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 앱 설정 카드 ───────────────────────────────────────────────────────────

/// 다크 모드 토글을 포함하는 앱 설정 카드
class SettingsAppCard extends ConsumerWidget {
  final bool isDark;

  const SettingsAppCard({required this.isDark, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '앱 설정',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 다크 모드 토글 행
          Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: context.themeColors.textPrimary,
                size: AppLayout.iconXl,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  '다크 모드',
                  style: AppTypography.bodyLg.copyWith(color: context.themeColors.textPrimary),
                ),
              ),
              // isDarkModeProvider를 토글하고 Hive에 영속 저장한다
              Switch(
                value: isDark,
                onChanged: (value) {
                  ref.read(isDarkModeProvider.notifier).state = value;
                  ref.read(hiveCacheServiceProvider).saveSetting(AppConstants.settingsKeyDarkMode, value);
                },
                // 배경 테마에 따른 스위치 색상: 어두운 배경에서 진한 보라 대신 밝은 보라를 사용한다
                activeThumbColor: context.themeColors.accent,
                activeTrackColor: context.themeColors.accentWithAlpha(0.3),
                inactiveThumbColor: context.themeColors.textPrimaryWithAlpha(0.7),
                inactiveTrackColor: context.themeColors.textPrimaryWithAlpha(0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 계정 관리 카드 ─────────────────────────────────────────────────────────

/// 로그아웃과 계정 삭제 버튼을 포함하는 계정 관리 카드
/// P1-13: 미인증 사용자에게는 이 카드를 표시하지 않는다
/// 실제 액션 처리는 SettingsActions로 위임한다 (SRP)
class SettingsAccountActionsCard extends ConsumerWidget {
  const SettingsAccountActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // P1-13: 로그인하지 않은 사용자에게는 로그아웃/계정삭제를 표시하지 않는다
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    if (!isAuthenticated) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '계정 관리',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // 로그아웃 타일
          SettingsActionTile(
            icon: Icons.logout_rounded,
            label: '로그아웃',
            onTap: () => SettingsActions.signOut(context),
          ),
          const SizedBox(height: AppSpacing.xs),
          // 계정 삭제 타일 (파괴적 액션: error 색상)
          SettingsActionTile(
            icon: Icons.delete_forever_rounded,
            label: '계정 삭제',
            isDestructive: true,
            onTap: () => SettingsActions.deleteAccount(context),
          ),
        ],
      ),
    );
  }
}
