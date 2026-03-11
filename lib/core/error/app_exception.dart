// C0.8: 커스텀 예외 클래스
// DioException, 네트워크 오류 등 다양한 예외를 앱 내부 타입으로 변환한다.
// 에러 등급: Fatal / Recoverable / Warning / Validation으로 분류한다.

/// 에러 등급 열거형
/// 등급별로 사용자 피드백 방식이 달라진다
enum AppErrorLevel {
  /// 앱 사용 불가 (인증 실패, 서버 접속 불가) → 풀스크린 오버레이
  fatal,

  /// 특정 기능 실패 (저장 실패, 일시 단절) → SnackBar 알림 + 자동 재시도
  recoverable,

  /// 계속 사용 가능한 이상 상태 (캐시 불일치) → 무음 또는 미세 표시
  warning,

  /// 사용자 입력 오류 (유효성 검사 실패) → 인라인 에러 메시지
  validation,
}

/// 앱 전용 예외 클래스
/// 모든 에러를 이 클래스로 변환하여 일관된 처리를 보장한다
class AppException implements Exception {
  /// 사용자에게 표시할 메시지 (한국어, 구체적 안내 포함)
  final String message;

  /// 에러 등급 (UI 처리 방식 결정)
  final AppErrorLevel level;

  /// 원본 예외 (디버깅용, 사용자에게 노출하지 않는다)
  final Object? cause;

  /// 스택 트레이스 (디버깅용)
  final StackTrace? stackTrace;

  /// 재시도 가능 여부 (UI에서 재시도 버튼 표시 여부)
  final bool isRetryable;

  const AppException({
    required this.message,
    this.level = AppErrorLevel.recoverable,
    this.cause,
    this.stackTrace,
    this.isRetryable = false,
  });

  // ─── 팩토리 생성자 ────────────────────────────────────────────────────────

  /// 네트워크 연결 오류 (서버 미응답 또는 네트워크 단절)
  factory AppException.network({Object? cause, StackTrace? stackTrace}) {
    return AppException(
      message: '서버에 연결할 수 없어요. 백엔드가 실행 중인지 확인해주세요.',
      level: AppErrorLevel.recoverable,
      cause: cause,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  /// 인증 만료 (토큰 갱신 실패)
  factory AppException.authExpired({Object? cause, StackTrace? stackTrace}) {
    return AppException(
      message: '로그인이 만료되었어요',
      level: AppErrorLevel.fatal,
      cause: cause,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  /// Google 로그인 실패
  factory AppException.authFailed({Object? cause, StackTrace? stackTrace}) {
    return AppException(
      message: '로그인에 실패했어요. 다시 시도해주세요.',
      level: AppErrorLevel.recoverable,
      cause: cause,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  /// 데이터 동기화 실패
  factory AppException.syncFailed({Object? cause, StackTrace? stackTrace}) {
    return AppException(
      message: '동기화하지 못했어요',
      level: AppErrorLevel.recoverable,
      cause: cause,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  /// 서버 오류
  factory AppException.serverError({Object? cause, StackTrace? stackTrace}) {
    return AppException(
      message: '서비스에 문제가 발생했어요',
      level: AppErrorLevel.fatal,
      cause: cause,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  /// 사용자 입력 유효성 검사 오류
  factory AppException.validation(String message) {
    return AppException(
      message: message,
      level: AppErrorLevel.validation,
      isRetryable: false,
    );
  }

  /// 접근 권한 없음 (403 Forbidden)
  factory AppException.permission({Object? cause, StackTrace? stackTrace}) {
    return AppException(
      message: '접근 권한이 없어요',
      level: AppErrorLevel.fatal,
      cause: cause,
      stackTrace: stackTrace,
      isRetryable: false,
    );
  }

  /// 알 수 없는 예외 (예상치 못한 오류)
  factory AppException.unknown({Object? cause, StackTrace? stackTrace}) {
    return AppException(
      message: '예상치 못한 오류가 발생했어요',
      level: AppErrorLevel.recoverable,
      cause: cause,
      stackTrace: stackTrace,
      isRetryable: true,
    );
  }

  @override
  String toString() =>
      'AppException(level: $level, message: "$message", cause: $cause)';
}
