// F9: 시험 경고 배너 — 독서 일정이 시험일을 초과할 때 표시
// 오렌지/레드 배너로 경고 메시지를 전달한다.
import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 시험 경고 배너 위젯
/// 독서 계획이 시험일까지 완독이 어려울 때 표시된다
class ExamWarningBanner extends StatelessWidget {
  /// 경고 메시지 텍스트
  final String message;

  const ExamWarningBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ColorTokens.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: ColorTokens.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 경고 아이콘
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Icon(
              Icons.warning_amber_rounded,
              color: ColorTokens.warning,
              size: AppLayout.iconLg,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // 경고 메시지
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMd.copyWith(
                color: ColorTokens.warningDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
