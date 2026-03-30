// C0.10: Firebase Analytics 이벤트 로깅 헬퍼
// FirebaseAnalytics.instance 호출을 래핑하여
// 플랫폼 가드와 에러 처리를 한 곳에서 관리한다.
// 입력: 이벤트 이름, 파라미터 (선택)
// 출력: Firebase Analytics에 이벤트 전송
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_config.dart';

/// Firebase Analytics 이벤트 로깅 서비스
/// 모든 호출에 플랫폼 가드를 적용하여 Firebase 미구성 플랫폼에서도 안전하다.
abstract class AnalyticsService {
  /// 커스텀 이벤트를 로깅한다.
  /// [name] 이벤트 이름 (예: 'todo_created', 'habit_completed')
  /// [params] 이벤트에 첨부할 키-값 파라미터 (선택)
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? params,
  }) async {
    if (!FirebaseConfig.isInitialized) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: params,
      );
    } catch (e) {
      debugPrint('[Analytics] 이벤트 로깅 실패 ($name): $e');
    }
  }

  /// 화면 조회 이벤트를 로깅한다.
  /// GoRouter 네비게이션 시 호출하면 사용자 이동 경로를 분석할 수 있다.
  /// [screenName] 화면 이름 (예: 'home', 'calendar', 'todo')
  static Future<void> logScreenView(String screenName) async {
    if (!FirebaseConfig.isInitialized) return;
    try {
      await FirebaseAnalytics.instance.logScreenView(
        screenName: screenName,
      );
    } catch (e) {
      debugPrint('[Analytics] 화면 로깅 실패 ($screenName): $e');
    }
  }

  /// 사용자 ID를 설정한다.
  /// Google Sign-In 성공 후 호출하여 사용자별 분석을 활성화한다.
  /// null을 전달하면 사용자 ID를 초기화한다 (로그아웃 시).
  static Future<void> setUserId(String? userId) async {
    if (!FirebaseConfig.isInitialized) return;
    try {
      await FirebaseAnalytics.instance.setUserId(id: userId);
    } catch (e) {
      debugPrint('[Analytics] 사용자 ID 설정 실패: $e');
    }
  }

  /// 사용자 프로퍼티를 설정한다.
  /// 세그먼트 분석에 활용한다 (예: 테마, 구독 상태 등).
  /// [name] 프로퍼티 이름
  /// [value] 프로퍼티 값 (null이면 해당 프로퍼티를 제거한다)
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!FirebaseConfig.isInitialized) return;
    try {
      await FirebaseAnalytics.instance.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      debugPrint('[Analytics] 사용자 프로퍼티 설정 실패 ($name): $e');
    }
  }

  /// FirebaseAnalytics NavigatorObserver를 반환한다.
  /// GoRouter에 추가하면 자동으로 화면 전환 이벤트를 수집한다.
  /// Firebase 미초기화 시 null을 반환한다.
  static FirebaseAnalyticsObserver? get navigatorObserver {
    if (!FirebaseConfig.isInitialized) return null;
    try {
      return FirebaseAnalyticsObserver(
        analytics: FirebaseAnalytics.instance,
      );
    } catch (e) {
      debugPrint('[Analytics] NavigatorObserver 생성 실패: $e');
      return null;
    }
  }
}
