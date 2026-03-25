// C0: 백업 결과 값 객체
// 백업/복원 작업의 결과 상태를 나타내는 열거형과 값 객체를 정의한다.
// BackupService, BackupProvider, UI 등에서 공통으로 사용한다.

/// 백업 결과 상태
enum BackupResultStatus {
  /// 백업 성공
  success,

  /// 인증되지 않은 상태 (로그인 필요)
  unauthenticated,

  /// 백업 중 오류 발생
  error,
}

/// 백업 작업 결과 값 객체
class BackupResult {
  /// 백업 결과 상태
  final BackupResultStatus status;

  /// 오류 메시지 (status가 error일 때만 non-null)
  final String? errorMessage;

  /// 백업 완료 시각 (status가 success일 때만 non-null)
  final DateTime? completedAt;

  const BackupResult({
    required this.status,
    this.errorMessage,
    this.completedAt,
  });

  /// 성공 결과 팩토리
  factory BackupResult.success() {
    return BackupResult(
      status: BackupResultStatus.success,
      completedAt: DateTime.now(),
    );
  }

  /// 미인증 결과 팩토리
  factory BackupResult.unauthenticated() {
    return const BackupResult(status: BackupResultStatus.unauthenticated);
  }

  /// 오류 결과 팩토리
  factory BackupResult.failure(String message) {
    return BackupResult(
      status: BackupResultStatus.error,
      errorMessage: message,
    );
  }

  /// 성공 여부
  bool get isSuccess => status == BackupResultStatus.success;
}
