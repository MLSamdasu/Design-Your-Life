// F6-GH: GitHub 백업 카드 위젯
// 설정 화면에서 GitHub 저장소 백업/복원 기능을 제공한다.
// SRP 분리: 토큰 입력(github_token_input), 액션(github_backup_actions),
//           확인 다이얼로그(github_disconnect_dialog, github_restore_dialog)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/github_auth_provider.dart';
import '../../../../core/backup/github_backup_provider.dart';
import '../../../../core/backup/github_backup_scheduler.dart';
import '../../../../core/providers/data_store_providers.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/glass_card.dart';
import 'github_backup_actions.dart';
import 'github_disconnect_dialog.dart';
import 'github_restore_dialog.dart';
import 'github_token_input.dart';

/// GitHub 백업 카드 (F6-GH)
class GitHubBackupCard extends ConsumerWidget {
  const GitHubBackupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isGitHubConnectedProvider);
    final username = ref.watch(gitHubUsernameProvider);
    final isValidating = ref.watch(isGitHubValidatingProvider);
    final isBackingUp = ref.watch(isGitHubBackingUpProvider);
    final isRestoring = ref.watch(isGitHubRestoringProvider);
    final progress = ref.watch(gitHubBackupProgressProvider);
    final lastBackup = ref.watch(lastGitHubBackupTimeProvider);
    final interval = ref.watch(gitHubBackupIntervalProvider);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Row(children: [
            Icon(Icons.code_rounded,
                size: AppLayout.iconLg,
                color: context.themeColors.textPrimaryWithAlpha(0.7)),
            const SizedBox(width: AppSpacing.md),
            Text('GitHub 백업',
                style: AppTypography.titleMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.7),
                )),
          ]),
          const SizedBox(height: AppSpacing.lg),
          // 토큰 입력 / 연결 상태
          GitHubTokenInput(
            isConnected: isConnected,
            username: username,
            isValidating: isValidating,
            onConnect: (token) => _connect(context, ref, token),
            onDisconnect: () => _disconnect(context, ref),
          ),
          // 연결된 경우에만 백업 액션을 표시한다
          if (isConnected) ...[
            const SizedBox(height: AppSpacing.xl),
            GitHubBackupActions(
              interval: _toUiInterval(interval),
              onIntervalChanged: (v) =>
                  ref.read(saveGitHubBackupIntervalProvider)(
                      _fromUiInterval(v)),
              isBackingUp: isBackingUp,
              isRestoring: isRestoring,
              backupProgress: progress,
              lastBackupTime: lastBackup,
              onBackup: () => _backup(context, ref),
              onRestore: () => _restore(context, ref),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _helpText(context),
        ],
      ),
    );
  }

  // ─── 토큰 연결 ─────────────────────────────────────────────────────
  Future<void> _connect(
      BuildContext context, WidgetRef ref, String token) async {
    ref.read(isGitHubValidatingProvider.notifier).state = true;
    final result =
        await ref.read(gitHubAuthServiceProvider).validateAndSaveToken(token);
    ref.read(isGitHubValidatingProvider.notifier).state = false;
    if (!context.mounted) return;
    if (result.isSuccess) {
      ref.read(gitHubAuthVersionProvider.notifier).state++;
      AppSnackBar.showSuccess(context, 'GitHub 연결 완료');
    } else {
      AppSnackBar.showError(
          context, result.errorMessage ?? '토큰 검증에 실패했습니다');
    }
  }

  // ─── 연결 해제 ─────────────────────────────────────────────────────
  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGitHubDisconnectDialog(context);
    if (confirmed != true) return;
    await ref.read(gitHubAuthServiceProvider).clearToken();
    ref.read(gitHubAuthVersionProvider.notifier).state++;
    if (!context.mounted) return;
    AppSnackBar.showInfo(context, 'GitHub 연결이 해제되었습니다');
  }

  // ─── 수동 백업 ─────────────────────────────────────────────────────
  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    if (ref.read(isGitHubBackingUpProvider)) return;
    ref.read(isGitHubBackingUpProvider.notifier).state = true;
    ref.read(gitHubBackupProgressProvider.notifier).state = 0.0;

    final result = await ref.read(gitHubBackupServiceProvider).backupToGitHub(
      onProgress: (p) {
        if (context.mounted) {
          ref.read(gitHubBackupProgressProvider.notifier).state = p;
        }
      },
    );

    ref.read(isGitHubBackingUpProvider.notifier).state = false;
    ref.read(gitHubBackupProgressProvider.notifier).state = 0.0;
    if (result.isSuccess) {
      ref.read(lastGitHubBackupVersionProvider.notifier).state++;
    }
    if (!context.mounted) return;
    result.isSuccess
        ? AppSnackBar.showSuccess(context, 'GitHub 백업이 완료되었습니다')
        : AppSnackBar.showError(
            context, result.errorMessage ?? 'GitHub 백업에 실패했습니다');
  }

  // ─── 복원 ──────────────────────────────────────────────────────────
  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    if (ref.read(isGitHubRestoringProvider)) return;
    final confirmed = await showGitHubRestoreDialog(context);
    if (confirmed != true || !context.mounted) return;

    ref.read(isGitHubRestoringProvider.notifier).state = true;
    final result =
        await ref.read(gitHubBackupServiceProvider).restoreFromGitHub();
    ref.read(isGitHubRestoringProvider.notifier).state = false;

    if (result.isSuccess) {
      bumpAllDataVersions(ref);
      ref.read(lastGitHubBackupVersionProvider.notifier).state++;
    }
    if (!context.mounted) return;
    result.isSuccess
        ? AppSnackBar.showSuccess(context, 'GitHub에서 복원이 완료되었습니다')
        : AppSnackBar.showError(
            context, result.errorMessage ?? 'GitHub 복원에 실패했습니다');
  }

  // ─── 주기 타입 변환 ──────────────────────────────────────────────────
  /// core BackupInterval → UI GitHubBackupInterval 변환
  static GitHubBackupInterval _toUiInterval(BackupInterval v) => switch (v) {
        BackupInterval.oneHour => GitHubBackupInterval.hourly,
        BackupInterval.sixHours => GitHubBackupInterval.sixHours,
        BackupInterval.twelveHours => GitHubBackupInterval.twelveHours,
        BackupInterval.daily => GitHubBackupInterval.daily,
      };

  /// UI GitHubBackupInterval → core BackupInterval 변환
  static BackupInterval _fromUiInterval(GitHubBackupInterval v) => switch (v) {
        GitHubBackupInterval.hourly => BackupInterval.oneHour,
        GitHubBackupInterval.sixHours => BackupInterval.sixHours,
        GitHubBackupInterval.twelveHours => BackupInterval.twelveHours,
        GitHubBackupInterval.daily => BackupInterval.daily,
      };

  // ─── 도움말 텍스트 ──────────────────────────────────────────────────
  Widget _helpText(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline_rounded,
          size: AppLayout.iconSm,
          color: context.themeColors.textPrimaryWithAlpha(0.4)),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          'github.com/settings/tokens에서 토큰을 생성하세요 (repo 권한 필요)',
          style: AppTypography.captionSm.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.4),
          ),
        ),
      ),
    ]);
  }
}
