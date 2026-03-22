// F1: 홈 대시보드 인사 헤더 위젯
// 시간대별 인사말 ("좋은 아침이에요" / "좋은 오후에요" / "좋은 저녁이에요")
// 사용자 이름 + 오늘 날짜를 표시하고, 우측에 업적/설정 아이콘을 배치한다.
// design-system.md 헤더 스펙: padding 20px 상, 24px 좌우, 8px 하
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/global_action_bar.dart';

/// 인사 헤더 위젯 (인사 메시지 + 이름 + 날짜 + 업적/설정 아이콘)
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  /// 시간대별 인사말 결정
  /// [now]를 외부에서 전달받아 build() 내에서 한 번만 캡처한 시각을 사용한다
  String _getGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return '좋은 아침이에요';
    if (hour >= 12 && hour < 18) return '좋은 오후에요';
    return '좋은 저녁이에요';
  }

  /// 오늘 날짜 포맷 (예: "3월 9일 일요일")
  /// [now]를 외부에서 전달받아 _getGreeting()과 동일한 시각 기준을 보장한다
  String _getDateLabel(DateTime now) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekday = weekdays[now.weekday - 1];
    return '${now.month}월 ${now.day}일 $weekday';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final displayName = authState.displayName ?? '사용자';
    // DateTime.now()를 한 번만 캡처하여 인사말과 날짜 표시의 일관성을 보장한다
    final now = DateTime.now();

    return Padding(
      // 헤더 패딩: 상 20px, 좌우 24px, 하 8px
      padding: const EdgeInsets.fromLTRB(AppSpacing.xxxl, AppSpacing.xxl, AppSpacing.xxxl, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 인사말 + 이름 + 날짜 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 시간대별 인사말 (body-lg: 14px, Regular, opacity 0.7)
                Text(
                  _getGreeting(now),
                  style: AppTypography.bodyLg.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.70),
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // 사용자 이름 (heading-lg: 26px, Bold)
                // 긴 이름이 오버플로우되지 않도록 말줄임 처리한다
                Text(
                  '안녕하세요, $displayName님!',
                  style: AppTypography.headingLg.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.sm),

                // 오늘 날짜 (caption-md: 11px, opacity 0.6)
                Text(
                  _getDateLabel(now),
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.60),
                  ),
                ),
              ],
            ),
          ),

          // 업적 + 설정 아이콘 버튼 (우측 상단)
          const GlobalActionBar(),
        ],
      ),
    );
  }
}
