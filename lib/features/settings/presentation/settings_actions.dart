// F6: 설정 화면 액션 헬퍼
// 로그아웃, 계정 삭제 등 설정 화면의 비즈니스 액션을 처리한다.
// SRP: 액션 로직을 settings_screen.dart에서 분리하여 단일 책임을 유지한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/layout_tokens.dart';

/// 설정 화면의 계정 관련 액션을 처리하는 유틸리티 클래스
/// 로그아웃 및 계정 삭제 다이얼로그와 실제 처리를 담당한다
abstract class SettingsActions {
  /// 로그아웃을 수행한다
  /// 확인 없이 즉시 로그아웃하고 오류 발생 시 SnackBar로 알린다
  static Future<void> signOut(BuildContext context) async {
    // 로그아웃은 별도 확인 없이 즉시 실행한다
    try {
      // ConsumerWidget의 ref 없이 직접 authServiceProvider에 접근할 수 없으므로
      // 화면 레벨의 ref를 받거나 별도 ProviderContainer를 사용해야 한다.
      // 여기서는 BuildContext를 통해 상위 ProviderScope에 접근한다.
      final container = ProviderScope.containerOf(context);
      final authService = container.read(authServiceProvider);
      await authService.signOut();
      // 로그아웃 성공: GoRouter의 authStateChanges 스트림이 자동으로 로그인 화면으로 이동한다
    } catch (e) {
      // 로그아웃 실패 시 사용자에게 알린다
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('로그아웃에 실패했습니다'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    }
  }

  /// 계정 삭제 확인 다이얼로그를 표시하고 확인 시 삭제를 수행한다
  /// 모든 서버 데이터와 사용자 계정을 삭제한다
  static Future<void> deleteAccount(BuildContext context) async {
    // async gap 이전에 container 참조를 캡처한다
    final container = ProviderScope.containerOf(context);
    // 계정 삭제 전 사용자에게 재확인을 요청한다 (되돌릴 수 없는 작업이므로)
    final confirmed = await _showDeleteConfirmDialog(context);
    if (confirmed != true) return;

    try {
      final authService = container.read(authServiceProvider);
      await authService.deleteAccount();
      // 삭제 성공: GoRouter가 자동으로 로그인 화면으로 이동한다
    } catch (e) {
      // 계정 삭제 실패 시 사용자에게 알린다
      if (!context.mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('계정 삭제에 실패했습니다. 다시 로그인 후 시도해 주세요.'),
            backgroundColor: ColorTokens.error,
          ),
        );
      }
    }
  }

  /// 계정 삭제 재확인 다이얼로그를 표시한다
  /// 사용자가 "삭제"를 선택하면 true, "취소"를 선택하면 null을 반환한다
  static Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.5),
      // 테마 인식 다이얼로그 배경: 모든 테마에서 텍스트 가독성 보장
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeColors.dialogSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.huge),
        ),
        title: Text(
          '계정 삭제',
          style: AppTypography.titleLg.copyWith(color: ctx.themeColors.textPrimary),
        ),
        content: Text(
          '계정을 삭제하면 모든 데이터(투두, 습관, 목표, 일정)가 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
          style: AppTypography.bodyLg.copyWith(
            color: ctx.themeColors.textPrimaryWithAlpha(0.7),
          ),
        ),
        actions: [
          // 취소 버튼
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(
              '취소',
              style: AppTypography.titleMd.copyWith(
                color: ctx.themeColors.textPrimaryWithAlpha(0.7),
              ),
            ),
          ),
          // 삭제 확인 버튼 (error 컬러로 위험 표시)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '삭제',
              style: AppTypography.titleMd.copyWith(
                color: ColorTokens.errorLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 설정 아이템 타일 ────────────────────────────────────────────────────────

/// 설정 화면의 단일 액션 타일 위젯
/// 아이콘 + 레이블 + 탭 콜백으로 구성되며 파괴적 액션 여부에 따라 색상이 달라진다
class SettingsActionTile extends StatelessWidget {
  /// 타일 아이콘
  final IconData icon;

  /// 타일 레이블
  final String label;

  /// 탭 콜백
  final VoidCallback onTap;

  /// 파괴적 액션 여부 (계정 삭제 등, true이면 error 색상 적용)
  final bool isDestructive;

  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // 파괴적 액션은 error 색상, 일반 액션은 흰색을 사용한다
    final color = isDestructive
        ? ColorTokens.errorLight
        : context.themeColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: color, size: AppLayout.iconXl),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLg.copyWith(color: color),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.5),
              size: AppLayout.iconLg,
            ),
          ],
        ),
      ),
    );
  }
}
