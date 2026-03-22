// C0.1/C0.6: 앱 진입점
// 초기화 순서: Hive(AES 암호화) → 세션 복원 → ProviderScope → runApp
// IN: 없음 (시스템 진입점)
// OUT: Flutter 앱 실행
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/ads/ad_provider.dart';
import 'core/auth/auth_provider.dart';
import 'core/cache/hive_initializer.dart';
import 'core/error/error_handler.dart';
import 'core/providers/global_providers.dart';

/// 앱 진입점
/// Hive 초기화 완료 후 ProviderScope를 씌워 runApp을 호출한다.
/// 초기화 중 발생하는 예외는 ErrorHandler.setupGlobalErrorHandlers가 처리한다.
Future<void> main() async {
  // Flutter 바인딩을 먼저 초기화해야 플랫폼 채널을 사용할 수 있다
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[STARTUP] WidgetsFlutterBinding 완료');

  // 전역 Flutter/Dart 에러 핸들러 등록
  // unhandledError가 발생해도 앱이 강제 종료되지 않고 로깅 후 복구를 시도한다
  ErrorHandler.setupGlobalErrorHandlers();
  debugPrint('[STARTUP] ErrorHandler 등록 완료');

  // 한국어 로케일 데이터 초기화 (DateFormat 'ko_KR' 사용 전 필수)
  await initializeDateFormatting('ko_KR');
  debugPrint('[STARTUP] DateFormatting 초기화 완료');

  // C0.6: Hive 초기화 (AES-256 암호화 키 생성/로드 포함)
  // flutter_secure_storage를 통해 암호화 키를 안전하게 보관한다
  debugPrint('[STARTUP] HiveInitializer.init() 시작...');
  await HiveInitializer.init();
  debugPrint('[STARTUP] HiveInitializer.init() 완료');

  // AdMob SDK 초기화는 adInitProvider가 담당한다
  // _AppWithAuthRestore.initState에서 ref.read(adInitProvider.future) 호출 시
  // adServiceProvider의 싱글톤 인스턴스에서 initialize + preloadAds가 실행된다

  debugPrint('[STARTUP] runApp 시작');
  runApp(
    ProviderScope(
      child: const _AppWithAuthRestore(),
    ),
  );
}

/// 앱 시작 시 Google Sign-In 세션 복원을 수행하는 래퍼 위젯
/// ProviderScope 내부에서 ref를 사용하여 세션 복원 후 메인 앱을 표시한다
class _AppWithAuthRestore extends ConsumerStatefulWidget {
  const _AppWithAuthRestore();

  @override
  ConsumerState<_AppWithAuthRestore> createState() =>
      _AppWithAuthRestoreState();
}

class _AppWithAuthRestoreState extends ConsumerState<_AppWithAuthRestore>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // 앱 라이프사이클 변화를 감지하여 자정 갱신 등에 활용한다
    WidgetsBinding.instance.addObserver(this);
    // 앱 시작 시 Google Sign-In 저장 세션으로 인증을 복원한다
    // 로컬 퍼스트 아키텍처: 복원 성공/실패 모두 앱을 정상 시작한다
    // 실패 시 미인증(로컬 모드) 상태로 진입하며 모든 기능을 사용할 수 있다
    Future.microtask(() async {
      debugPrint('[STARTUP] restoreSession 시작...');
      try {
        await ref.read(authStateProvider.notifier).restoreSession();
        debugPrint('[STARTUP] restoreSession 완료');
      } catch (e, stack) {
        // V3-012: 세션 복원 실패를 로깅하되 앱 시작은 막지 않는다
        debugPrint('[STARTUP] restoreSession 실패: $e');
        ErrorHandler.logServiceError('Main:restoreSession', e, stack);
      }

      // AdMob 광고 미리 로드 (인증 복원 후 백그라운드에서 수행)
      debugPrint('[STARTUP] adInit 시작...');
      try {
        await ref.read(adInitProvider.future);
        debugPrint('[STARTUP] adInit 완료');
      } catch (e, stack) {
        // V3-012: 광고 초기화 실패를 로깅하되 앱 시작은 막지 않는다
        debugPrint('[STARTUP] adInit 실패: $e');
        ErrorHandler.logServiceError('Main:adInit', e, stack);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱이 백그라운드에서 복귀할 때 오늘 날짜를 재확인한다
  /// 자정을 넘긴 경우 todayDateProvider를 갱신하여 UI가 새 날짜를 반영하도록 한다
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final current = ref.read(todayDateProvider);
      // 날짜가 변경된 경우에만 갱신하여 불필요한 리빌드를 방지한다
      if (current != today) {
        ref.read(todayDateProvider.notifier).state = today;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const DesignYourLifeApp();
  }
}
