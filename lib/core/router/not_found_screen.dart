// C0.4: NotFoundScreen - 404 에러 화면
// 존재하지 않는 경로 접근 시 Glassmorphism 디자인으로 표시한다.
// SRP: 404 오류 상태만 시각적으로 표현한다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/color_tokens.dart';
import '../theme/layout_tokens.dart';
import '../theme/radius_tokens.dart';
import '../theme/spacing_tokens.dart';
import '../theme/typography_tokens.dart';
import '../../core/theme/theme_colors.dart';
import 'route_paths.dart';

/// 404 에러 화면
/// GoRouter errorBuilder에서 사용한다
class NotFoundScreen extends StatelessWidget {
  /// GoRouter가 전달하는 에러 정보 (경로, 오류 메시지 등)
  final Exception? error;

  const NotFoundScreen({this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 투명 배경: _AppBackground의 테마 그래디언트가 비치도록 한다
      backgroundColor: ColorTokens.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.huge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 에러 아이콘
              Icon(
                Icons.link_off_rounded,
                size: AppLayout.iconEmptyLg + AppSpacing.md,
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              // 404 제목
              Text(
                '페이지를 찾을 수 없어요',
                style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              // 설명 텍스트
              Text(
                '요청한 페이지가 존재하지 않거나 이동되었어요.',
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.huge),
              // 홈으로 이동 버튼
              ElevatedButton(
                onPressed: () => context.go(RoutePaths.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themeColors.textPrimaryWithAlpha(0.2),
                  foregroundColor: context.themeColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                    vertical: AppSpacing.lgXl,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    side: BorderSide(
                      color: context.themeColors.textPrimaryWithAlpha(0.3),
                    ),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: AppLayout.iconLg),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '홈으로 돌아가기',
                      style: AppTypography.titleMd.copyWith(
                    color: context.themeColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
