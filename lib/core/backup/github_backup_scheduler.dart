// C0: GitHub 자동 백업 스케줄러
// Timer.periodic을 사용하여 설정된 주기마다 GitHub 백업을 자동 실행한다.
// 동시 실행 방지 플래그로 중복 백업을 차단한다.

import 'dart:async';
import 'dart:developer' as developer;

/// GitHub 자동 백업 주기 열거형
enum BackupInterval {
  /// 1시간마다
  oneHour(Duration(hours: 1), '1시간'),

  /// 6시간마다
  sixHours(Duration(hours: 6), '6시간'),

  /// 12시간마다
  twelveHours(Duration(hours: 12), '12시간'),

  /// 매일 (24시간)
  daily(Duration(hours: 24), '매일');

  /// 주기 Duration
  final Duration duration;

  /// UI에 표시할 한국어 라벨
  final String label;

  const BackupInterval(this.duration, this.label);

  /// 문자열 이름으로부터 enum을 검색한다 (Hive 저장/복원용)
  static BackupInterval fromName(String? name) {
    if (name == null) return BackupInterval.daily;
    return BackupInterval.values.firstWhere(
      (e) => e.name == name,
      orElse: () => BackupInterval.daily,
    );
  }
}

/// GitHub 자동 백업 스케줄러
/// Timer.periodic으로 주기적 백업을 실행하고
/// _isRunning 플래그로 동시 실행을 방지한다
class GitHubBackupScheduler {
  Timer? _timer;
  bool _isRunning = false;

  /// 현재 스케줄러 활성 여부
  bool get isActive => _timer?.isActive ?? false;

  /// 주기적 백업을 시작한다
  /// [interval]: 백업 주기
  /// [backupFn]: 실제 백업 수행 함수
  void start(BackupInterval interval, Future<void> Function() backupFn) {
    stop();
    developer.log(
      '[GitHubBackupScheduler] 스케줄러 시작: ${interval.label}',
      name: 'backup',
    );
    _timer = Timer.periodic(interval.duration, (_) => _execute(backupFn));
  }

  /// 스케줄러를 중지한다
  void stop() {
    _timer?.cancel();
    _timer = null;
    developer.log('[GitHubBackupScheduler] 스케줄러 중지', name: 'backup');
  }

  /// 앱 시작 시 마지막 백업 시각을 확인하여 밀린 백업을 즉시 실행한다
  /// [lastBackupTime]: 마지막 백업 시각 (null이면 즉시 실행)
  /// [interval]: 설정된 백업 주기
  /// [backupFn]: 실제 백업 수행 함수
  Future<void> checkAndRunOverdue({
    DateTime? lastBackupTime,
    required BackupInterval interval,
    required Future<void> Function() backupFn,
  }) async {
    if (lastBackupTime == null) {
      // 한 번도 백업하지 않았으면 즉시 실행
      await _execute(backupFn);
      return;
    }
    final elapsed = DateTime.now().difference(lastBackupTime);
    if (elapsed >= interval.duration) {
      developer.log(
        '[GitHubBackupScheduler] 밀린 백업 실행 (경과: ${elapsed.inMinutes}분)',
        name: 'backup',
      );
      await _execute(backupFn);
    }
  }

  /// 백업을 실행한다 (동시 실행 방지)
  Future<void> _execute(Future<void> Function() backupFn) async {
    if (_isRunning) {
      developer.log(
        '[GitHubBackupScheduler] 이전 백업 진행 중 — 스킵',
        name: 'backup',
      );
      return;
    }
    _isRunning = true;
    try {
      await backupFn();
    } catch (e, st) {
      developer.log(
        '[GitHubBackupScheduler] 자동 백업 실패: $e',
        name: 'backup',
        error: e,
        stackTrace: st,
      );
    } finally {
      _isRunning = false;
    }
  }
}
