// 투두 화면 상단 헤더 위젯
// 년/월 피커 + 주간 날짜 슬라이더를 표시한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../shared/widgets/date_slider.dart';
import '../../../../shared/widgets/global_action_bar.dart';
import '../../providers/todo_provider.dart';

/// 투두 화면 상단 헤더
/// 년/월 피커 + 주간 날짜 슬라이더
class TodoHeader extends ConsumerWidget {
  final DateTime selectedDate;

  const TodoHeader({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, AppSpacing.pageVertical, AppSpacing.pageHorizontal, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 년/월 표시 + 피커 버튼 + 업적/설정 아이콘
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMonthPicker(context, ref),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${selectedDate.year}년 ${selectedDate.month}월',
                        style: AppTypography.headingSm.copyWith(
                          color: context.themeColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.themeColors.textPrimaryWithAlpha(0.7),
                        size: AppLayout.iconXl,
                      ),
                    ],
                  ),
                ),
              ),
              // 업적 + 설정 아이콘 버튼
              const GlobalActionBar(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // 주간 날짜 슬라이더
          DateSlider(
            selectedDate: selectedDate,
            onDateSelected: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
          ),
        ],
      ),
    );
  }

  /// 년/월 선택 다이얼로그 표시
  Future<void> _showMonthPicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(selectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(TimelineLayout.calendarStartYear),
      lastDate: DateTime(TimelineLayout.calendarEndYear),
      // 테마 인식 DatePicker: modalDecoration 배경색으로 모든 테마에서 가독성 보장
      builder: (context, child) {
        final dialogBg = context.themeColors.dialogSurface;
        final isOnDark = context.themeColors.isOnDarkBackground;
        return Theme(
          data: (isOnDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: (isOnDark
                    ? const ColorScheme.dark(primary: ColorTokens.main)
                    : const ColorScheme.light(primary: ColorTokens.main))
                .copyWith(surface: dialogBg),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }
}
