// F6: Google Drive 백업 카드 위젯
// 설정 화면에서 Google Drive 백업/복원 기능을 제공한다.
// 로그인 상태: 백업하기 + 복원하기 버튼 + 마지막 백업 시각 표시
// 미로그인 상태: 로그인하여 백업 활성화 버튼 표시
// 인증 미지원 플랫폼(Windows, macOS 미설정)에서는 안내 메시지를 표시한다.
// 백업 실행 전 리워드 광고를 표시하고, 보상 확인 후 백업을 진행한다
// SRP 분리: 하위 위젯들을 개별 파일로 분리하여 단일 책임을 유지한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/ad_provider.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/backup/backup_provider.dart';
import '../../../../core/providers/data_store_providers.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import 'backup_controls.dart';
import 'backup_result_snack_bar.dart';
import 'login_prompt_tile.dart';
import 'restore_confirm_dialog.dart';

/// Google Drive 백업 카드 (F6)
/// 로컬 퍼스트 아키텍처에서 사용자가 명시적으로 Google Drive 백업을 관리하는 UI
class CloudBackupCard extends ConsumerWidget {
  const CloudBackupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 인증 미지원 플랫폼(Windows, macOS 미설정)에서는 안내 메시지를 표시한다
    if (!AuthService.isAuthSupported) {
      return _buildUnsupportedPlatformCard(context);
    }

    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final isBackingUp = ref.watch(isBackingUpProvider);
    final isRestoring = ref.watch(isRestoringProvider);
    final backupProgress = ref.watch(backupProgressProvider);
    final lastBackupTime = ref.watch(lastBackupTimeProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Text(
            'Google Drive 백업',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (isAuthenticated) ...[
            // 로그인 상태: 백업/복원 컨트롤 표시
            BackupControls(
              isBackingUp: isBackingUp,
              isRestoring: isRestoring,
              backupProgress: backupProgress,
              lastBackupTime: lastBackupTime,
              onBackup: () => _handleBackup(context, ref),
              onRestore: () => _handleRestore(context, ref),
            ),
          ] else ...[
            // 미로그인 상태: 로그인 유도 버튼 표시
            LoginPromptTile(
              onTap: () => context.push(RoutePaths.login),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 인증 미지원 플랫폼 카드 ──────────────────────────────────────────────
  /// 인증을 지원하지 않는 플랫폼에서 안내 메시지를 표시한다
  Widget _buildUnsupportedPlatformCard(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Google Drive 백업',
            style: AppTypography.titleMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: AppLayout.iconLg,
                color: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '이 플랫폼에서는 Google Drive 백업이 지원되지 않습니다',
                  style: AppTypography.bodyLg.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 백업 처리 ────────────────────────────────────────────────────────────
  /// 리워드 광고를 표시한 후 전체 데이터 백업을 실행한다
  /// 광고가 로드되지 않았으면 광고 없이 바로 백업을 진행한다
  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    // 이미 진행 중이면 중복 실행을 방지한다
    if (ref.read(isBackingUpProvider)) return;

    ref.read(isBackingUpProvider.notifier).state = true;
    ref.read(backupProgressProvider.notifier).state = 0.0;

    // 리워드 광고 표시 후 백업을 실행한다
    final backupWithAd = ref.read(showBackupAdProvider);
    final result = await backupWithAd(
      onProgress: (progress) {
        // 진행률 상태를 업데이트한다 (위젯이 소멸된 경우 무시)
        if (context.mounted) {
          ref.read(backupProgressProvider.notifier).state = progress;
        }
      },
    );

    ref.read(isBackingUpProvider.notifier).state = false;
    ref.read(backupProgressProvider.notifier).state = 0.0;

    // P1-11: 백업 성공 후 버전 카운터를 증가시켜 마지막 백업 시각 UI를 갱신한다
    if (result.isSuccess) {
      ref.read(lastBackupVersionProvider.notifier).state++;
    }

    if (!context.mounted) return;

    // 결과에 따라 피드백 메시지를 표시한다
    showBackupResultSnackBar(context, result);
  }

  // ─── 복원 처리 ────────────────────────────────────────────────────────────
  /// 클라우드에서 데이터를 복원한다 (사용자 확인 후 실행)
  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    if (ref.read(isRestoringProvider)) return;

    // 복원 전 사용자 확인 (기존 로컬 데이터 덮어쓰기 경고)
    final confirmed = await showRestoreConfirmDialog(context);
    if (confirmed != true) return;
    if (!context.mounted) return;

    ref.read(isRestoringProvider.notifier).state = true;

    final backupService = ref.read(backupServiceProvider);
    final result = await backupService.restoreFromCloud(
      onProgress: (progress) {
        // 복원 진행률은 별도로 표시하지 않는다 (isRestoring으로 충분)
      },
    );

    ref.read(isRestoringProvider.notifier).state = false;

    // 복원 성공 후 모든 버전 카운터를 증가시켜 전체 파생 Provider를 재평가한다
    if (result.isSuccess) {
      bumpAllDataVersions(ref);
      ref.read(lastBackupVersionProvider.notifier).state++;
    }

    if (!context.mounted) return;
    showBackupResultSnackBar(context, result, isRestore: true);
  }
}
