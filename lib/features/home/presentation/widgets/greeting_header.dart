// F1: 홈 대시보드 인사 헤더 위젯
// 시간대별 인사말 ("좋은 아침이에요" / "좋은 오후에요" / "좋은 저녁이에요")
// 사용자 이름 + 오늘 날짜를 표시하고, 우측 상단에 설정 아이콘을 제공한다.
// design-system.md 헤더 스펙: padding 20px 상, 24px 좌우, 8px 하
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';

/// 인사 헤더 위젯 (SRP: 인사 메시지 + 이름 + 날짜만 담당)
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  /// 시간대별 인사말 결정
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '좋은 아침이에요';
    if (hour >= 12 && hour < 18) return '좋은 오후에요';
    return '좋은 저녁이에요';
  }

  /// 오늘 날짜 포맷 (예: "3월 9일 일요일")
  String _getDateLabel() {
    final now = DateTime.now();
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final weekday = weekdays[now.weekday - 1];
    return '${now.month}월 ${now.day}일 $weekday';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final displayName = authState.displayName ?? '사용자';

    return Padding(
      // 헤더 패딩: 상 20px, 좌우 24px, 하 8px
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
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
                  _getGreeting(),
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
                  _getDateLabel(),
                  style: AppTypography.captionMd.copyWith(
                    color: context.themeColors.textPrimaryWithAlpha(0.60),
                  ),
                ),
              ],
            ),
          ),

          // 설정 아이콘 버튼 (우측 상단)
          // 탭 시 SettingsScreen을 모달 시트로 표시한다
          // WCAG 2.1 기준 최소 터치 타겟 44x44px 적용
          GestureDetector(
            onTap: () => _openSettings(context),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.themeColors.overlayMedium,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.themeColors.borderLight,
                    ),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: context.themeColors.textPrimaryWithAlpha(0.80),
                    size: AppLayout.iconLg,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 설정 화면을 모달 바텀 시트로 표시한다
  Future<void> _openSettings(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorTokens.transparent,
      // 화면 높이의 85%를 차지하도록 설정한다
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            decoration: BoxDecoration(
              // 설정 시트 배경: 다크 모드 그라디언트 토큰 기반 반투명 다크 배경
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorTokens.darkGradientStart.withValues(alpha: 0.95),
                  ColorTokens.darkGradientMid.withValues(alpha: 0.95),
                ],
              ),
            ),
            child: const SettingsScreen(),
          ),
        ),
      ),
    );
  }
}
