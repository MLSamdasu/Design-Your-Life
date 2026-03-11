// C0.4: NotFoundScreen - 404 에러 화면
// 존재하지 않는 경로 접근 시 Glassmorphism 디자인으로 표시한다.
// SRP: 404 오류 상태만 시각적으로 표현한다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/color_tokens.dart';
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
      // Glassmorphism 배경색 (gradientMid 기반)
      backgroundColor: ColorTokens.gradientMid,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 에러 아이콘
              Icon(
                Icons.link_off_rounded,
                size: 64,
                color: context.themeColors.textPrimaryWithAlpha(0.7),
              ),
              const SizedBox(height: 24),
              // 404 제목
              Text(
                '페이지를 찾을 수 없어요',
                style: AppTypography.headingSm.copyWith(color: context.themeColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // 설명 텍스트
              Text(
                '요청한 페이지가 존재하지 않거나 이동되었어요.',
                style: AppTypography.bodyMd.copyWith(
                  color: context.themeColors.textPrimaryWithAlpha(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // 홈으로 이동 버튼
              ElevatedButton(
                onPressed: () => context.go(RoutePaths.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themeColors.textPrimaryWithAlpha(0.2),
                  foregroundColor: context.themeColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: context.themeColors.textPrimaryWithAlpha(0.3),
                    ),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 18),
                    const SizedBox(width: 8),
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
