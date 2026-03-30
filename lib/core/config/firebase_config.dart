// C0.9: Firebase 초기화 및 Remote Config 관리
// Firebase Core, Crashlytics, Remote Config를 초기화하고
// 강제 업데이트/유지보수 모드 등 원격 설정을 제공한다.
// 입력: 없음 (앱 시작 시 main.dart에서 호출)
// 출력: Firebase 서비스 초기화 완료 상태
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Firebase 초기화 및 Remote Config 관리 유틸리티
/// 앱 시작 시 한 번만 호출하며, 플랫폼별 Firebase 미구성 상황을 안전하게 처리한다.
abstract class FirebaseConfig {
  /// Firebase 미초기화 상태에서 Remote Config 등을 호출하지 않도록 보호하는 플래그
  static bool _initialized = false;

  /// Firebase 초기화 여부
  static bool get isInitialized => _initialized;

  /// Firebase Core + Crashlytics + Remote Config를 순서대로 초기화한다.
  /// 플랫폼에 google-services.json / GoogleService-Info.plist가 없으면
  /// 예외를 삼키고 로컬 모드로 진행한다 (로컬 퍼스트 아키텍처).
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('[Firebase] Core 초기화 완료');

      // Crashlytics: Flutter 프레임워크 에러를 자동 수집한다
      await _setupCrashlytics();

      // Remote Config: 기본값 설정 + 서버 값 페치
      await _setupRemoteConfig();
    } catch (e, stack) {
      // Firebase 미구성 플랫폼(macOS 등)에서는 초기화 실패를 허용한다
      debugPrint('[Firebase] 초기화 실패 (로컬 모드 진행): $e');
      debugPrint('[Firebase] Stack: $stack');
      _initialized = false;
    }
  }

  /// Crashlytics 에러 핸들러를 등록한다.
  /// FlutterError.onError와 PlatformDispatcher.onError를 Firebase로 리다이렉트한다.
  static Future<void> _setupCrashlytics() async {
    try {
      // 디버그 모드에서는 Crashlytics 수집을 비활성화하여 노이즈를 줄인다
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);

      // Flutter 위젯 렌더링 에러 → Crashlytics로 전송
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Dart 비동기 에러 → Crashlytics로 전송
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      debugPrint('[Firebase] Crashlytics 설정 완료');
    } catch (e) {
      debugPrint('[Firebase] Crashlytics 설정 실패: $e');
    }
  }

  /// Remote Config 기본값을 설정하고 서버에서 최신 값을 페치한다.
  /// 네트워크 오류 시 기본값으로 동작한다.
  static Future<void> _setupRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // 개발 환경에서는 짧은 페치 간격, 프로덕션에서는 1시간 캐시
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            kDebugMode ? const Duration(minutes: 1) : const Duration(hours: 1),
      ));

      // 기본값: 서버 연결 실패 시 이 값이 사용된다
      await remoteConfig.setDefaults(const {
        'min_supported_version': '1.0.0',
        'ad_enabled': true,
        'maintenance_mode': false,
      });

      // 서버에서 최신 설정 가져오기 (실패해도 기본값 사용)
      await remoteConfig.fetchAndActivate();
      debugPrint('[Firebase] Remote Config 페치 완료');
    } catch (e) {
      debugPrint('[Firebase] Remote Config 페치 실패 (기본값 사용): $e');
    }
  }

  /// 현재 앱 버전이 최소 지원 버전 이상인지 확인한다.
  /// 강제 업데이트가 필요하면 true를 반환한다.
  /// [currentVersion] 현재 앱의 시맨틱 버전 문자열 (예: '1.0.0')
  static bool shouldForceUpdate(String currentVersion) {
    if (!_initialized) return false;

    try {
      final minVersion = FirebaseRemoteConfig.instance
          .getString('min_supported_version');
      return _compareVersions(currentVersion, minVersion) < 0;
    } catch (e) {
      debugPrint('[Firebase] 버전 비교 실패: $e');
      return false;
    }
  }

  /// 광고 활성화 여부를 Remote Config에서 읽는다.
  /// Firebase 미초기화 시 기본값 true를 반환한다.
  static bool get isAdEnabled {
    if (!_initialized) return true;
    try {
      return FirebaseRemoteConfig.instance.getBool('ad_enabled');
    } catch (_) {
      return true;
    }
  }

  /// 유지보수 모드 여부를 Remote Config에서 읽는다.
  /// Firebase 미초기화 시 기본값 false를 반환한다.
  static bool get isMaintenanceMode {
    if (!_initialized) return false;
    try {
      return FirebaseRemoteConfig.instance.getBool('maintenance_mode');
    } catch (_) {
      return false;
    }
  }

  /// 시맨틱 버전 문자열을 비교한다.
  /// a < b이면 음수, a == b이면 0, a > b이면 양수를 반환한다.
  static int _compareVersions(String a, String b) {
    final partsA = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final partsB = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // 버전 자릿수를 맞춘다 (1.0 → 1.0.0)
    while (partsA.length < 3) {
      partsA.add(0);
    }
    while (partsB.length < 3) {
      partsB.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (partsA[i] != partsB[i]) {
        return partsA[i] - partsB[i];
      }
    }
    return 0;
  }
}
