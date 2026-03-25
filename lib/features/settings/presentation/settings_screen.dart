// F6: 설정 화면
// 다크 모드 토글, 계정 정보, 로그아웃, 계정 삭제 기능을 제공한다.
// F16: 태그 관리 내비게이션 타일 추가
// F17: Google Calendar 연동 토글 추가
// SRP 분리: 카드 위젯 → settings_cards.dart / 액션 처리 → settings_actions.dart
//           데이터 카드 → settings_data_card.dart / 튜토리얼 카드 → settings_tutorial_card.dart
//           헤더 → settings_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import 'settings_cards.dart';
import 'settings_data_card.dart';
import 'settings_header.dart';
import 'settings_nav_card.dart';
import 'settings_theme_card.dart';
import 'settings_tutorial_card.dart';
import 'widgets/cloud_backup_card.dart';
import 'widgets/github_backup_card.dart';

/// 설정 화면 (F6)
/// 계정 정보 / 다크 모드 토글 / 로그아웃 / 계정 삭제를 제공한다
/// DraggableScrollableSheet 내부에서 사용 시 반드시 scrollController를 전달해야
/// 시트의 드래그 제스처와 콘텐츠 스크롤이 정상적으로 연동된다
class SettingsScreen extends ConsumerWidget {
  /// DraggableScrollableSheet에서 전달받은 스크롤 컨트롤러
  /// null이면 SingleChildScrollView가 자체 컨트롤러를 생성한다
  final ScrollController? scrollController;

  const SettingsScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          // DraggableScrollableSheet의 컨트롤러를 연결하여
          // 시트 드래그와 콘텐츠 스크롤 제스처가 올바르게 협력하도록 한다
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.pageVertical,
            AppSpacing.pageHorizontal,
            AppSpacing.bottomScrollPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 헤더 (타이틀 + 닫기 버튼)
              const SettingsHeader(),
              const SizedBox(height: AppSpacing.xxxl),

              // 계정 정보 카드 (이름 + 이메일)
              SettingsAccountInfoCard(authState: authState),
              const SizedBox(height: AppSpacing.xl),

              // 앱 설정 카드 (다크 모드 토글)
              SettingsAppCard(isDark: isDark),
              const SizedBox(height: AppSpacing.xl),

              // 테마 선택 카드 (4가지 프리셋 미리보기 + 선택)
              const SettingsThemeCard(),
              const SizedBox(height: AppSpacing.xl),

              // 네비게이션 바 위치/높낮이 설정 카드
              const SettingsNavCard(),
              const SizedBox(height: AppSpacing.xl),

              // 데이터 관리 카드 (태그 관리 + Google Calendar 연동)
              const SettingsDataCard(),
              const SizedBox(height: AppSpacing.xl),

              // 튜토리얼 보기 카드 (앱 사용법 안내를 다시 볼 수 있다)
              const SettingsTutorialCard(),
              const SizedBox(height: AppSpacing.xl),

              // 클라우드 백업 카드 (로컬 퍼스트: 로그인 시 백업/복원 활성화)
              const CloudBackupCard(),
              const SizedBox(height: AppSpacing.xl),

              // GitHub 백업 카드 (토큰 기반 GitHub 저장소 백업)
              const GitHubBackupCard(),
              const SizedBox(height: AppSpacing.xl),

              // 계정 관리 카드 (로그아웃 / 계정 삭제)
              const SettingsAccountActionsCard(),
            ],
          ),
        ),
      ),
    );
  }
}
