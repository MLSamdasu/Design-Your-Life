// 공용 위젯: SectionTitle (섹션 제목)
// 글래스 스타일 섹션 구분 제목과 선택적 "더보기" 액션을 제공한다.
// design-system.md 타이포그래피 heading-sm(18px, Bold) 스펙을 따른다.
import 'package:flutter/material.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/typography_tokens.dart';

/// 섹션 제목 위젯
/// 홈 대시보드, 캘린더 등 각 섹션 상단에 배치하는 공용 타이틀
class SectionTitle extends StatelessWidget {
  /// 섹션 제목 텍스트
  final String title;

  /// "더보기" 또는 추가 액션 텍스트 (null이면 표시 안 함)
  final String? actionLabel;

  /// 액션 탭 콜백
  final VoidCallback? onActionTap;

  /// 오른쪽 추가 위젯 (선택)
  final Widget? trailing;

  const SectionTitle({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // design-system.md: 섹션 제목 패딩 (이전 섹션과 16px 간격)
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 섹션 제목 (heading-sm: 18px, Bold)
          Expanded(
            child: Text(
              title,
              style: AppTypography.headingSm.copyWith(
                color: context.themeColors.textPrimary,
              ),
            ),
          ),

          // 오른쪽 커스텀 위젯 (선택)
          if (trailing != null) trailing!,

          // "더보기" 액션 텍스트 (선택)
          if (actionLabel != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: AppTypography.captionLg.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.60),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
