// 공용 위젯: GlobalActionBar - 전역 액션 버튼 바
// 업적 아이콘 버튼 + 설정 아이콘 버튼을 수평 배치한다.
// MainShell에서 모든 탭에 공통으로 표시되는 플로팅 액션 바이다.
// 설정 탭 시 SettingsScreen 모달, 업적 탭 시 AchievementScreen으로 이동한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_paths.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// 전역 액션 버튼 바 (업적 + 설정)
/// MainShell의 Stack 상단 우측에 플로팅되어 모든 탭에서 접근 가능하다
class GlobalActionBar extends ConsumerWidget {
  const GlobalActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 업적 아이콘 버튼
        _ActionIconButton(
          icon: Icons.emoji_events_rounded,
          semanticLabel: '업적 화면',
          onTap: () => context.push(RoutePaths.achievements),
        ),
        const SizedBox(width: AppSpacing.md),
        // 설정 아이콘 버튼
        _ActionIconButton(
          icon: Icons.settings_rounded,
          semanticLabel: '설정',
          onTap: () => _openSettings(context),
        ),
      ],
    );
  }

  /// 설정 화면을 모달 바텀 시트로 표시한다
  Future<void> _openSettings(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorTokens.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: AppLayout.settingsSheetInitialSize,
        minChildSize: AppLayout.settingsSheetMinSize,
        maxChildSize: AppLayout.settingsSheetMaxSize,
        expand: false,
        builder: (_, controller) => ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.massive),
          ),
          child: Container(
            // 설정 시트 배경: 테마 인식 다이얼로그 서피스 색상 사용
            color: context.themeColors.dialogSurface,
            child: SettingsScreen(scrollController: controller),
          ),
        ),
      ),
    );
  }
}

/// 개별 액션 아이콘 버튼 (원형 배경 + 테두리)
/// WCAG 2.1 기준 최소 터치 타겟 44x44px 보장
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: AppLayout.minTouchTarget,
          height: AppLayout.minTouchTarget,
          child: Center(
            child: Container(
              width: AppLayout.containerLg,
              height: AppLayout.containerLg,
              decoration: BoxDecoration(
                color: context.themeColors.overlayMedium,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.themeColors.borderLight,
                ),
              ),
              child: Icon(
                icon,
                color: context.themeColors.textPrimaryWithAlpha(0.80),
                size: AppLayout.iconLg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
