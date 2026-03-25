// F6: 백업 컨트롤 위젯
// 로그인 상태에서 백업/복원 버튼 + 진행 상황 + 마지막 백업 시각을 표시한다
import 'package:flutter/material.dart';

import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import 'backup_action_button.dart';
import 'last_backup_info.dart';

/// 로그인 상태에서 표시하는 백업/복원 컨트롤 위젯
class BackupControls extends StatelessWidget {
  final bool isBackingUp;
  final bool isRestoring;
  final double backupProgress;
  final DateTime? lastBackupTime;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  const BackupControls({
    super.key,
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
        LastBackupInfo(lastBackupTime: lastBackupTime),
        const SizedBox(height: AppSpacing.lg),

        // 백업 진행 중 프로그레스 바
        if (isBackingUp) ...[
          LinearProgressIndicator(
            value: backupProgress > 0 ? backupProgress : null,
            backgroundColor: context.themeColors.overlayLight,
            valueColor:
                AlwaysStoppedAnimation<Color>(context.themeColors.accent),
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
              child: BackupActionButton(
                label: '백업하기',
                icon: Icons.cloud_upload_outlined,
                isLoading: isBackingUp,
                onTap: isBackingUp || isRestoring ? null : onBackup,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // 복원하기 버튼
            Expanded(
              child: BackupActionButton(
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
