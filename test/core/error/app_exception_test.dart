// AppException 단위 테스트
// 팩토리 생성자별 메시지, 에러 등급, 재시도 가능 여부를 검증한다.
import 'package:design_your_life/core/error/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException - 기본 생성', () {
    test('기본 에러 레벨이 recoverable이다', () {
      const exception = AppException(message: '테스트 에러');
      expect(exception.level, AppErrorLevel.recoverable);
      expect(exception.isRetryable, false);
    });

    test('message와 level이 올바르게 설정된다', () {
      const exception = AppException(
        message: '커스텀 에러',
        level: AppErrorLevel.fatal,
        isRetryable: true,
      );
      expect(exception.message, '커스텀 에러');
      expect(exception.level, AppErrorLevel.fatal);
      expect(exception.isRetryable, true);
    });

    test('cause와 stackTrace를 저장한다', () {
      final cause = Exception('원인');
      final exception = AppException(
        message: '래핑된 에러',
        cause: cause,
      );
      expect(exception.cause, cause);
    });
  });

  group('AppException - 팩토리 생성자', () {
    test('network가 recoverable이고 retryable이다', () {
      final exception = AppException.network();
      expect(exception.level, AppErrorLevel.recoverable);
      expect(exception.isRetryable, true);
      expect(exception.message, contains('서버'));
    });

    test('authExpired가 fatal이다', () {
      final exception = AppException.authExpired();
      expect(exception.level, AppErrorLevel.fatal);
      expect(exception.message, contains('로그인'));
    });

    test('authFailed가 recoverable이고 retryable이다', () {
      final exception = AppException.authFailed();
      expect(exception.level, AppErrorLevel.recoverable);
      expect(exception.isRetryable, true);
    });

    test('syncFailed가 recoverable이다', () {
      final exception = AppException.syncFailed();
      expect(exception.level, AppErrorLevel.recoverable);
      expect(exception.isRetryable, true);
    });

    test('serverError가 fatal이다', () {
      final exception = AppException.serverError();
      expect(exception.level, AppErrorLevel.fatal);
    });

    test('validation이 validation 레벨이고 retryable이 아니다', () {
      final exception = AppException.validation('입력 오류');
      expect(exception.level, AppErrorLevel.validation);
      expect(exception.isRetryable, false);
      expect(exception.message, '입력 오류');
    });

    test('permission이 fatal이고 retryable이 아니다', () {
      final exception = AppException.permission();
      expect(exception.level, AppErrorLevel.fatal);
      expect(exception.isRetryable, false);
      expect(exception.message, contains('권한'));
    });

    test('unknown이 recoverable이다', () {
      final exception = AppException.unknown();
      expect(exception.level, AppErrorLevel.recoverable);
      expect(exception.isRetryable, true);
    });
  });

  group('AppException - toString', () {
    test('level과 message를 포함한다', () {
      const exception = AppException(message: '테스트');
      final str = exception.toString();
      expect(str, contains('recoverable'));
      expect(str, contains('테스트'));
    });
  });

  group('AppErrorLevel', () {
    test('4가지 에러 등급이 존재한다', () {
      expect(AppErrorLevel.values.length, 4);
      expect(AppErrorLevel.values, contains(AppErrorLevel.fatal));
      expect(AppErrorLevel.values, contains(AppErrorLevel.recoverable));
      expect(AppErrorLevel.values, contains(AppErrorLevel.warning));
      expect(AppErrorLevel.values, contains(AppErrorLevel.validation));
    });
  });
}
