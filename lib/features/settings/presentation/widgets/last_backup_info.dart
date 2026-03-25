// F6: 마지막 백업 시각 정보 위젯
// 마지막으로 Google Drive 백업이 완료된 시각을 표시한다
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 마지막 백업 시각을 표시하는 위젯
class LastBackupInfo extends StatelessWidget {
  final DateTime? lastBackupTime;

  const LastBackupInfo({super.key, required this.lastBackupTime});

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
