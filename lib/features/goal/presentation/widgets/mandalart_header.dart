// F5 위젯: MandalartHeader - 만다라트 상단 헤더 위젯 (SRP 분리)
// mandalart_view.dart에서 추출한다.
// 포함: MandalartHeader, MandalartGoalDropdown, MandalartAddButton
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/goal.dart';
import '../../providers/mandalart_provider.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 만다라트 헤더: 목표 선택 드롭다운 + 새 만다라트 추가 버튼
class MandalartHeader extends ConsumerWidget {
  final List<Goal> goals;
  final String? selectedId;
  final VoidCallback onCreateTap;

  const MandalartHeader({
    super.key,
    required this.goals,
    required this.selectedId,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // 목표 선택 드롭다운
        Expanded(
          child: MandalartGoalDropdown(
            goals: goals,
            selectedId: selectedId,
            onChanged: (id) {
              ref.read(selectedMandalartGoalIdProvider.notifier).state = id;
              // 줌 상태 초기화
              ref.read(zoomedSubGoalIndexProvider.notifier).state = null;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        // 새 만다라트 추가 버튼
        MandalartAddButton(onTap: onCreateTap),
      ],
    );
  }
}

/// 목표 선택 드롭다운 위젯
class MandalartGoalDropdown extends StatelessWidget {
  final List<Goal> goals;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const MandalartGoalDropdown({
    super.key,
    required this.goals,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.12),
        borderRadius: BorderRadius.circular(AppRadius.xlLg),
        border: Border.all(
          color: context.themeColors.textPrimaryWithAlpha(0.2),
          width: AppLayout.borderThin,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          // 테마 인식 드롭다운 배경: 모든 테마에서 가독성 보장
          dropdownColor: context.themeColors.dialogSurface,
          isExpanded: true,
          icon: Icon(
            Icons.expand_more_rounded,
            color: context.themeColors.textPrimaryWithAlpha(0.7),
            size: AppLayout.iconXl,
          ),
          style: AppTypography.bodyMd.copyWith(color: context.themeColors.textPrimary),
          items: goals.map<DropdownMenuItem<String>>((g) {
            return DropdownMenuItem<String>(
              value: g.id,
              child: Text(
                g.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// 새 만다라트 추가 버튼
class MandalartAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const MandalartAddButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        decoration: BoxDecoration(
          color: ColorTokens.main,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.main.withValues(alpha: AppAnimation.buttonShadowAlpha),
              blurRadius: EffectLayout.shadowBlurMd,
              offset: const Offset(0, EffectLayout.shadowOffsetSm),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          // MAIN 컬러 배경(#7C3AED) 위이므로 항상 흰색이 적절하다
          color: ColorTokens.white,
          size: AppLayout.iconNav,
        ),
      ),
    );
  }
}
