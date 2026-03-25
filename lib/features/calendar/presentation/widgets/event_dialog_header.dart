// F2 위젯: EventDialogHeader - 다이얼로그 헤더 (제목 + 닫기 버튼)
// SRP 분리: EventCreateDialog에서 헤더 렌더링만 담당한다
import 'package:flutter/material.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// 일정 다이얼로그 헤더 위젯 (제목 텍스트 + 닫기 버튼)
class EventDialogHeader extends StatelessWidget {
  /// 편집 모드 여부 (true이면 '일정 수정', false이면 '일정 추가' 표시)
  final bool isEditMode;

  /// 닫기 버튼 탭 시 호출되는 콜백
  final VoidCallback onClose;

  const EventDialogHeader({
    super.key,
    required this.isEditMode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isEditMode ? '일정 수정' : '일정 추가',
          style: AppTypography.titleLg.copyWith(
            color: context.themeColors.textPrimary,
          ),
        ),
        // WCAG 2.1 기준 최소 터치 타겟 44x44px 적용
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: AppLayout.minTouchTarget,
            height: AppLayout.minTouchTarget,
            child: Center(
              child: Container(
                width: AppLayout.iconHuge,
                height: AppLayout.iconHuge,
                decoration: BoxDecoration(
                  color: context.themeColors.textPrimaryWithAlpha(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: context.themeColors.textPrimaryWithAlpha(0.80),
                  size: AppLayout.iconMd,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
