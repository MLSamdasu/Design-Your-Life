// F5 위젯: GoalTemplateSection - 목표 템플릿 제안 섹션 (SRP 분리)
// goal_empty_state.dart에서 추출한다.
// 빈 상태에서 빠른 시작을 위한 템플릿 칩을 제공한다 (v1.1 확장 예정).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/goal_period.dart';
import 'goal_create_dialog.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 인기 목표 템플릿 제안 섹션
class TemplateSection extends ConsumerWidget {
  final GoalPeriod period;
  final int year;

  const TemplateSection({
    super.key,
    required this.period,
    required this.year,
  });

  static const List<_Template> _templates = [
    _Template(label: '토익 900점', icon: '📚'),
    _Template(label: '자격증 취득', icon: '🏆'),
    _Template(label: '다이어트 -5kg', icon: '💪'),
    _Template(label: '영어 회화', icon: '🗣️'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(
          '인기 목표 템플릿',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.5),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _templates.map((t) {
            return _TemplateChip(
              template: t,
              onTap: () => _showDialogWithTitle(context, t.label),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 템플릿 제목을 기본값으로 GoalCreateDialog를 열어 빠른 목표 생성을 유도한다
  Future<void> _showDialogWithTitle(BuildContext context, String title) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.4),
      transitionDuration: AppAnimation.standard,
      pageBuilder: (_, __, ___) => GoalCreateDialog(
        defaultPeriod: period,
        defaultYear: year,
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}

/// 템플릿 데이터 모델
class _Template {
  final String label;
  final String icon;

  const _Template({required this.label, required this.icon});
}

/// 목표 템플릿 칩 위젯
class _TemplateChip extends StatelessWidget {
  final _Template template;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.themeColors.textPrimaryWithAlpha(0.1),
          border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.2),
          ),
          borderRadius: BorderRadius.circular(AppRadius.huge),
        ),
        child: Text(
          '${template.icon} ${template.label}',
          style: AppTypography.captionLg.copyWith(
            color: context.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
      ),
    );
  }
}
