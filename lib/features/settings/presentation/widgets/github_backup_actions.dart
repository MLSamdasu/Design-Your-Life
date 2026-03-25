// F6-GH: GitHub 백업/복원 액션 위젯
// 자동 백업 주기 드롭다운 + 수동 백업/복원 버튼 + 마지막 백업 시각 표시
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import 'backup_action_button.dart';

/// GitHub 자동 백업 주기 옵션
enum GitHubBackupInterval {
  hourly('1시간', 1),
  sixHours('6시간', 6),
  twelveHours('12시간', 12),
  daily('매일', 24);

  final String label;
  final int hours;
  const GitHubBackupInterval(this.label, this.hours);
}

/// GitHub 백업/복원 액션 섹션
class GitHubBackupActions extends StatelessWidget {
  final GitHubBackupInterval interval;
  final ValueChanged<GitHubBackupInterval> onIntervalChanged;
  final bool isBackingUp;
  final bool isRestoring;
  final double backupProgress;
  final DateTime? lastBackupTime;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  const GitHubBackupActions({
    super.key,
    required this.interval,
    required this.onIntervalChanged,
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
        _intervalSelector(context),
        const SizedBox(height: AppSpacing.lg),
        // 백업 진행 중 프로그레스 바
        if (isBackingUp) _progressBar(context, '백업 중...'),
        // 복원 진행 중 인디케이터
        if (isRestoring) _progressBar(context, '복원 중...'),
        // 수동 백업 + 복원 버튼 행
        Row(children: [
          Expanded(
            child: BackupActionButton(
              label: '수동 백업',
              icon: Icons.backup_rounded,
              isLoading: isBackingUp,
              onTap: isBackingUp || isRestoring ? null : onBackup,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: BackupActionButton(
              label: '복원',
              icon: Icons.restore_rounded,
              isLoading: isRestoring,
              isOutlined: true,
              onTap: isBackingUp || isRestoring ? null : onRestore,
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _lastBackupInfo(context),
      ],
    );
  }

  // ─── 프로그레스 바 (백업/복원 공통) ────────────────────────────────────
  Widget _progressBar(BuildContext context, String label) {
    return Column(children: [
      LinearProgressIndicator(
        value: isBackingUp && backupProgress > 0 ? backupProgress : null,
        backgroundColor: context.themeColors.overlayLight,
        valueColor:
            AlwaysStoppedAnimation<Color>(context.themeColors.accent),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(label,
          style: AppTypography.captionMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.6),
          ),
          textAlign: TextAlign.center),
      const SizedBox(height: AppSpacing.lg),
    ]);
  }

  // ─── 자동 백업 주기 선택 드롭다운 ──────────────────────────────────────
  Widget _intervalSelector(BuildContext context) {
    return Row(children: [
      Icon(Icons.schedule_rounded,
          size: AppLayout.iconMd,
          color: context.themeColors.textPrimaryWithAlpha(0.50)),
      const SizedBox(width: AppSpacing.md),
      Text('자동 백업 주기:',
          style: AppTypography.bodyMd.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          )),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.themeColors.overlayLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: context.themeColors.textPrimaryWithAlpha(0.15),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<GitHubBackupInterval>(
              value: interval,
              isExpanded: true,
              dropdownColor: context.themeColors.dialogSurface,
              style: AppTypography.bodyMd
                  .copyWith(color: context.themeColors.textPrimary),
              icon: Icon(Icons.expand_more_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.5)),
              items: GitHubBackupInterval.values
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onIntervalChanged(v);
              },
            ),
          ),
        ),
      ),
    ]);
  }

  // ─── 마지막 백업 시각 표시 ────────────────────────────────────────────
  Widget _lastBackupInfo(BuildContext context) {
    final text = lastBackupTime != null
        ? DateFormat('yyyy.MM.dd HH:mm').format(lastBackupTime!)
        : '아직 백업하지 않았습니다';
    return Row(children: [
      Icon(Icons.history_rounded,
          size: AppLayout.iconMd,
          color: context.themeColors.textPrimaryWithAlpha(0.50)),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Text('마지막 백업: $text',
            style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.6),
            )),
      ),
    ]);
  }
}
