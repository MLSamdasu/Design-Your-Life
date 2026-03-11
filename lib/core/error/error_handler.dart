// C0.8: 전역 에러 핸들러
// FlutterError.onError, PlatformDispatcher.instance.onError를 설정하여
// 미처리 예외를 포착하고 로깅한다.
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'app_exception.dart';

/// 전역 에러 핸들러
/// 예외를 AppException으로 변환하는 단일 책임을 가진다
abstract class ErrorHandler {
  /// Flutter 프레임워크 에러 핸들러 설정
  /// main.dart에서 앱 시작 전 한 번만 호출한다
  static void setupGlobalErrorHandlers() {
    // Flutter 위젯 렌더링 에러 처리
    FlutterError.onError = (FlutterErrorDetails details) {
      // 개발 환경에서는 기본 에러 출력 유지
      if (kDebugMode) {
        FlutterError.presentError(details);
        return;
      }
      // 프로덕션: developer.log는 릴리스 빌드에서도 동작한다
      _logError(
        'FlutterError',
        details.exception,
        details.stack,
      );
    };

    // Dart isolate 에러 처리 (비동기 에러)
    PlatformDispatcher.instance.onError = (error, stack) {
      // 프로덕션/디버그 공통: 비동기 미처리 예외를 기록한다
      _logError('PlatformDispatcher', error, stack);
      return true;
    };
  }

  /// 환경에 무관하게 에러를 기록하는 내부 메서드
  /// developer.log는 릴리스 빌드에서도 동작하므로 프로덕션 로깅에 안전하다
  static void _logError(String source, Object error, [StackTrace? stack]) {
    developer.log(
      '[$source] $error',
      name: 'ErrorHandler',
      error: error,
      stackTrace: stack,
      level: 1000, // SEVERE 레벨
    );
  }

  /// 서비스 계층에서 예외를 삼키기 전에 호출하는 공개 로깅 메서드
  /// catch 블록에서 에러를 UI 상태로 변환할 때, 원본 에러를 기록하여
  /// 프로덕션 환경에서도 원인 추적이 가능하도록 한다
  static void logServiceError(String service, Object error, [StackTrace? stack]) {
    _logError(service, error, stack);
  }

  /// 임의 예외를 AppException으로 변환하는 순수 함수
  /// Repository 계층에서 예외를 포착할 때 사용한다
  static AppException convert(Object error, [StackTrace? stackTrace]) {
    // AppException은 그대로 반환 (이미 변환된 예외)
    if (error is AppException) {
      return error;
    }

    // 네트워크 관련 에러 감지 (에러 메시지로 판단)
    final message = error.toString().toLowerCase();
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return AppException.network(cause: error, stackTrace: stackTrace);
    }

    // 알 수 없는 예외
    return AppException.unknown(cause: error, stackTrace: stackTrace);
  }

  /// 에러를 안전하게 실행하고 AppException으로 변환하는 헬퍼
  /// Repository 메서드에서 try-catch 보일러플레이트를 줄이기 위해 사용한다
  static Future<T> runSafely<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      // 변환 전 원본 에러를 기록한다 (AppException은 이미 변환된 것이므로 제외)
      if (error is! AppException) {
        _logError('runSafely', error, stackTrace);
      }
      throw convert(error, stackTrace);
    }
  }
}
