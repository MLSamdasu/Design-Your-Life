// F2: 캘린더 뷰 전환 탭 위젯
// 월간/주간/일간 탭 전환 - glass pill 스타일의 세그먼트 컨트롤
// StateProvider를 통해 탭 전환 상태를 관리한다
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/enums/view_type.dart';
import '../../providers/calendar_provider.dart';
import '../../../../core/theme/animation_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';

/// 캘린더 뷰 전환 탭 세그먼트
class CalendarViewSwitcher extends ConsumerWidget {
  const CalendarViewSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(calendarViewTypeProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.themeColors.textPrimaryWithAlpha(0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl), // radius-lg
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ViewType.values.map((type) {
          final isActive = type == currentView;
          final label = _labelFor(type);

          return GestureDetector(
            onTap: () {
              ref.read(calendarViewTypeProvider.notifier).state = type;
            },
            child: AnimatedContainer(
              // AN-09와 연동: 탭 전환 시 pill 하이라이트 전환
              duration: AppAnimation.normal,
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lgXl, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isActive
                    ? context.themeColors.textPrimaryWithAlpha(0.25)
                    : ColorTokens.transparent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                label,
                style: AppTypography.captionLg.copyWith(
                  color: isActive
                      ? context.themeColors.textPrimary
                      : context.themeColors.textPrimaryWithAlpha(0.55),
                  fontWeight: isActive ? AppTypography.weightBold : AppTypography.weightRegular,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ViewType별 한글 라벨
  String _labelFor(ViewType type) {
    switch (type) {
      case ViewType.monthly:
        return '월간';
      case ViewType.weekly:
        return '주간';
      case ViewType.daily:
        return '일간';
    }
  }
}
