// F-Book: 수동 분배 섹션 — 공유된 목표일 기반 ManualPlanForm 래퍼 위젯
// 목표일은 상위 폼의 targetDate를 공유한다 (별도 목표일 선택 불필요)
import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../services/reading_plan_generator.dart';
import 'book_create_form_fields.dart';
import 'manual_plan_form.dart';

/// 수동 분배 모드 섹션 위젯
/// 상위 폼의 targetDate를 공유받아 ManualPlanForm에 전달한다
class ManualSectionBuilder extends StatelessWidget {
  final DateTime startDate;
  final DateTime? targetDate;
  final int totalAmount;
  final TrackingMode trackingMode;
  final ValueChanged<List<ManualPlanEntry>> onEntriesChanged;
  final ValueChanged<bool> onValidChanged;

  const ManualSectionBuilder({
    super.key,
    required this.startDate,
    required this.targetDate,
    required this.totalAmount,
    required this.trackingMode,
    required this.onEntriesChanged,
    required this.onValidChanged,
  });

  @override
  Widget build(BuildContext context) {
    final trackingStr =
        trackingMode == TrackingMode.pages ? 'page' : 'chapter';

    // 목표일 + 총 수량이 모두 설정되면 폼 표시
    if (targetDate != null && totalAmount > 0) {
      return ManualPlanForm(
        startDate: startDate,
        targetDate: targetDate!,
        totalAmount: totalAmount,
        trackingMode: trackingStr,
        onChanged: onEntriesChanged,
        onValidChanged: onValidChanged,
      );
    }
    return _buildHint(context);
  }

  /// 아직 입력이 부족할 때 표시되는 힌트 메시지
  Widget _buildHint(BuildContext context) {
    final msg = targetDate == null
        ? '상단에서 목표일을 선택하면 날짜별 입력이 표시됩니다'
        : trackingMode == TrackingMode.pages
            ? '총 페이지 수를 먼저 입력해주세요'
            : '총 챕터 수를 먼저 입력해주세요';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(msg,
          style: AppTypography.captionMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.5))),
    );
  }
}
