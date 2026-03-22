// 공용 Provider: 앱 튜토리얼 상태 관리
// 첫 로그인(온보딩 완료) 시 5탭 온보딩 가이드를 자동 표시한다.
// 설정에서 수동으로 다시 볼 수 있도록 showTutorialProvider를 제공한다.
// Hive settingsBox의 'hasSeenTutorial' 키로 영속 저장한다.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/global_providers.dart';

/// 튜토리얼 완료 여부 Provider (Hive 영속)
/// false이면 앱 첫 진입 시 온보딩 가이드를 표시한다
final hasSeenTutorialProvider = StateProvider<bool>((ref) {
  final cacheService = ref.watch(hiveCacheServiceProvider);
  return cacheService.readSetting<bool>(
        AppConstants.settingsKeyHasSeenTutorial,
      ) ??
      false;
});

/// 튜토리얼 표시 요청 Provider
/// 설정에서 "튜토리얼 보기"를 누르면 true로 변경되어 오버레이가 표시된다
/// MainShell에서 watch하여 동적으로 튜토리얼을 재표시한다
final showTutorialProvider = StateProvider<bool>((ref) => false);
