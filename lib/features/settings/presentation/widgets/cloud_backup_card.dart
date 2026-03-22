// F6: Google Drive 백업 카드 위젯
// 설정 화면에서 Google Drive 백업/복원 기능을 제공한다.
// 로그인 상태: 백업하기 + 복원하기 버튼 + 마지막 백업 시각 표시
// 미로그인 상태: 로그인하여 백업 활성화 버튼 표시
// 인증 미지원 플랫폼(Windows, macOS 미설정)에서는 안내 메시지를 표시한다.
// 백업 실행 전 리워드 광고를 표시하고, 보상 확인 후 백업을 진행한다
// SRP: 백업 UI를 settings_screen.dart에서 분리하여 단일 책임을 유지한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/ad_provider.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/auth/auth_service.dart';
import '../../../../core/backup/backup_provider.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

// 복원 후 전체 데이터 갱신을 위한 Single Source of Truth 임포트
import '../../../../core/providers/data_store_providers.dart';

/// Google Drive 백업 카드 (F6)
/// 로컬 퍼스트 아키텍처에서 사용자가 명시적으로 Google Drive 백업을 관리하는 UI
class CloudBackupCard extends ConsumerWidget {
  const CloudBackupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 인증 미지원 플랫폼(Windows, macOS 미설정)에서는 안내 메시지를 표시한다
    if (!AuthService.isAuthSupported) {
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
            _BackupControls(
              isBackingUp: isBackingUp,
              isRestoring: isRestoring,
              backupProgress: backupProgress,
              lastBackupTime: lastBackupTime,
              onBackup: () => _handleBackup(context, ref),
              onRestore: () => _handleRestore(context, ref),
            ),
          ] else ...[
            // 미로그인 상태: 로그인 유도 버튼 표시
            _LoginPromptTile(
              onTap: () => context.push(RoutePaths.login),
            ),
          ],
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
    _showResultSnackBar(context, result);
  }

  // ─── 복원 처리 ────────────────────────────────────────────────────────────
  /// 클라우드에서 데이터를 복원한다 (사용자 확인 후 실행)
  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    if (ref.read(isRestoringProvider)) return;

    // 복원 전 사용자 확인 (기존 로컬 데이터 덮어쓰기 경고)
    final confirmed = await _showRestoreConfirmDialog(context);
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
    _showResultSnackBar(context, result, isRestore: true);
  }

  // ─── 복원 확인 다이얼로그 ────────────────────────────────────────────────
  /// 복원 전 사용자 확인 다이얼로그를 표시한다
  Future<bool?> _showRestoreConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.5),
      // 테마 인식 다이얼로그 배경: 모든 테마에서 텍스트 가독성 보장
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeColors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.huge),
        ),
        title: Text(
          '데이터 복원',
          style: AppTypography.titleLg
              .copyWith(color: ctx.themeColors.textPrimary),
        ),
        content: Text(
          'Google Drive 데이터로 복원하면 현재 로컬 데이터를 덮어씁니다.\n이 작업은 되돌릴 수 없습니다.',
          style: AppTypography.bodyLg.copyWith(
            color: ctx.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              '취소',
              style: AppTypography.titleMd.copyWith(
                color: ctx.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '복원',
              style: AppTypography.titleMd
                  .copyWith(color: ctx.themeColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SnackBar 피드백 ─────────────────────────────────────────────────────
  /// 백업/복원 결과에 따라 SnackBar를 표시한다
  /// [isRestore]가 true이면 복원 성공 메시지를 표시한다
  void _showResultSnackBar(
    BuildContext context,
    BackupResult result, {
    bool isRestore = false,
  }) {
    switch (result.status) {
      case BackupResultStatus.success:
        final message = isRestore ? '복원이 완료되었습니다' : '백업이 완료되었습니다';
        AppSnackBar.showSuccess(context, message);
        break;
      case BackupResultStatus.unauthenticated:
        AppSnackBar.showError(context, '로그인이 필요합니다');
        break;
      case BackupResultStatus.error:
        AppSnackBar.showError(context, result.errorMessage ?? '오류가 발생했습니다');
        break;
    }
  }
}

// ─── 백업 컨트롤 위젯 ────────────────────────────────────────────────────────

/// 로그인 상태에서 표시하는 백업/복원 컨트롤 위젯
class _BackupControls extends StatelessWidget {
  final bool isBackingUp;
  final bool isRestoring;
  final double backupProgress;
  final DateTime? lastBackupTime;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  const _BackupControls({
    required this.isBackingUp,
    required this.isRestoring,
    required this.backupProgress,
    required this.lastBackupTime,
    required this.onBackup,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 마지막 백업 시각 표시
        _LastBackupInfo(lastBackupTime: lastBackupTime),
        const SizedBox(height: AppSpacing.lg),

        // 백업 진행 중 프로그레스 바
        if (isBackingUp) ...[
          LinearProgressIndicator(
            value: backupProgress > 0 ? backupProgress : null,
            backgroundColor: context.themeColors.overlayLight,
            valueColor: AlwaysStoppedAnimation<Color>(context.themeColors.accent),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '백업 중...',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 복원 진행 중 인디케이터
        if (isRestoring) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            '복원 중...',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 버튼 행
        Row(
          children: [
            // 백업하기 버튼
            Expanded(
              child: _BackupActionButton(
                label: '백업하기',
                icon: Icons.cloud_upload_outlined,
                isLoading: isBackingUp,
                onTap: isBackingUp || isRestoring ? null : onBackup,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // 복원하기 버튼
            Expanded(
              child: _BackupActionButton(
                label: '복원하기',
                icon: Icons.cloud_download_outlined,
                isLoading: isRestoring,
                isOutlined: true,
                onTap: isBackingUp || isRestoring ? null : onRestore,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── 마지막 백업 정보 ─────────────────────────────────────────────────────────

/// 마지막 백업 시각을 표시하는 위젯
class _LastBackupInfo extends StatelessWidget {
  final DateTime? lastBackupTime;

  const _LastBackupInfo({required this.lastBackupTime});

  @override
  Widget build(BuildContext context) {
    final timeText = lastBackupTime != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(lastBackupTime!)
        : '아직 백업하지 않았습니다';

    return Row(
      children: [
        Icon(
          // WCAG: 히스토리 아이콘 알파 0.50 이상으로 가독성 보장
          Icons.history_rounded,
          size: AppLayout.iconMd,
          color: context.themeColors.textPrimaryWithAlpha(0.50),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            '마지막 백업: $timeText',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.6),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 백업 액션 버튼 ──────────────────────────────────────────────────────────

/// 백업/복원 액션 버튼
class _BackupActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool isOutlined;
  final VoidCallback? onTap;

  const _BackupActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.isOutlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.mdLg, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isOutlined
              ? ColorTokens.transparent
              : isDisabled
                  ? context.themeColors.accentWithAlpha(0.4)
                  : context.themeColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: isOutlined
              ? Border.all(
                  color: isDisabled
                      ? context.themeColors.textPrimaryWithAlpha(0.2)
                      : context.themeColors.accent,
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: AppLayout.iconMd,
                height: AppLayout.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: AppLayout.spinnerStrokeWidth,
                  // 채워진 버튼: 항상 흰색, 아웃라인 버튼: 테마 악센트
                  color: isOutlined
                      ? context.themeColors.accent
                      : ColorTokens.white,
                ),
              )
            else
              Icon(
                icon,
                size: AppLayout.iconMd,
                // WCAG: 비활성 아이콘 알파 0.45 이상으로 가독성 보장
                color: isOutlined
                    ? isDisabled
                        ? context.themeColors.textPrimaryWithAlpha(0.45)
                        : context.themeColors.accent
                    : ColorTokens.white,
              ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodySm.copyWith(
                // WCAG: 비활성 텍스트 알파 0.45 이상으로 가독성 보장
                color: isOutlined
                    ? isDisabled
                        ? context.themeColors.textPrimaryWithAlpha(0.45)
                        : context.themeColors.accent
                    : ColorTokens.white,
                fontWeight: AppTypography.weightSemiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 로그인 유도 타일 ─────────────────────────────────────────────────────────

/// 미로그인 상태에서 로그인을 유도하는 타일
class _LoginPromptTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LoginPromptTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeColors.accentWithAlpha(0.08),
          borderRadius: BorderRadius.circular(AppRadius.lgXl),
          border: Border.all(
            color: context.themeColors.accentWithAlpha(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: AppLayout.iconXl,
              color: context.themeColors.accentWithAlpha(0.8),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '로그인하여 백업 활성화',
                    style: AppTypography.bodyLg.copyWith(
                      color: context.themeColors.accent,
                      fontWeight: AppTypography.weightSemiBold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '로그인하면 데이터를 Google Drive에 안전하게 보관할 수 있습니다',
                    style: AppTypography.captionMd.copyWith(
                      color: context.themeColors.textPrimaryWithAlpha(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeColors.accentWithAlpha(0.6),
              size: AppLayout.iconLg,
            ),
          ],
        ),
      ),
    );
  }
}
