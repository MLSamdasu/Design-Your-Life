// C0.3: Google Sign-In 인증 서비스
// google_sign_in 패키지를 직접 사용하여 Google OAuth 로그인, 세션 복원, 로그아웃을 처리한다.
// Google Drive appdata 접근을 위해 Drive scope를 요청한다.
// Windows에서는 google_sign_in 구현이 없으므로 플랫폼 가드로 크래시를 방지한다.
// 입력: 없음 (google_sign_in 패키지 직접 사용)
// 출력: AuthState (userId, displayName, photoUrl, isAuthenticated)
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../cache/hive_initializer.dart';
import '../error/app_exception.dart';

/// 인증 상태를 표현하는 값 객체
/// AuthService의 OUT으로 UI와 Router에 전달된다
class AuthState {
  /// 사용자 ID (null이면 미인증, Google 계정 ID 문자열)
  final String? userId;

  /// 사용자 표시 이름 (null이면 미인증)
  final String? displayName;

  /// Google 계정 이메일 (null이면 미인증)
  final String? email;

  /// 프로필 사진 URL (null 가능)
  final String? photoUrl;

  /// 인증 여부
  bool get isAuthenticated => userId != null;

  const AuthState({
    this.userId,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  /// 비인증 상태 (로그아웃 상태)
  const AuthState.unauthenticated()
      : userId = null,
        displayName = null,
        email = null,
        photoUrl = null;

  /// GoogleSignInAccount 객체로부터 AuthState를 생성한다
  factory AuthState.fromGoogleAccount(GoogleSignInAccount account) {
    return AuthState(
      userId: account.id,
      displayName: account.displayName,
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }

  @override
  String toString() =>
      'AuthState(userId: $userId, isAuthenticated: $isAuthenticated)';
}

/// Google Sign-In 기반 인증 서비스 (C0.3)
/// google_sign_in 패키지로 직접 인증을 처리한다
/// Windows에서는 google_sign_in 구현이 없으므로 모든 메서드가 안전하게 미인증 상태를 반환한다
class AuthService {
  final GoogleSignIn _googleSignIn;

  /// macOS OAuth 클라이언트 ID
  /// Google Cloud Console에서 발급한 macOS용 OAuth 클라이언트 ID를 설정한다
  /// 플레이스홀더 값이면 인증을 비활성화한다
  static const _macOSClientId =
      'YOUR_MACOS_OAUTH_CLIENT_ID.apps.googleusercontent.com';

  /// 인증 지원 플랫폼 여부
  /// Windows: google_sign_in 네이티브 구현이 없어 지원 불가
  /// macOS: OAuth 클라이언트 ID가 플레이스홀더면 비활성화 (signInSilently 무한 대기 방지)
  static bool get isAuthSupported {
    if (Platform.isWindows) return false;
    if (Platform.isMacOS && _macOSClientId.startsWith('YOUR_')) return false;
    return true;
  }

  AuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              // macOS에서는 clientId를 명시적으로 전달해야 한다 (google-services.json 미지원)
              // Android/iOS에서는 google-services.json / GoogleService-Info.plist에서 자동 로드
              clientId: Platform.isMacOS ? _macOSClientId : null,
              scopes: [
                // Google Drive appdata 폴더 접근 권한 (앱 전용 숨김 폴더)
                'https://www.googleapis.com/auth/drive.appdata',
              ],
            );

  /// 현재 인증 상태를 GoogleSignIn 계정에서 즉시 반환한다
  AuthState get currentState {
    final account = _googleSignIn.currentUser;
    if (account == null) return const AuthState.unauthenticated();
    return AuthState.fromGoogleAccount(account);
  }

  /// GoogleSignIn 인스턴스를 반환한다 (Google Drive API 인증 클라이언트 생성에 필요)
  GoogleSignIn get googleSignIn => _googleSignIn;

  // ─── Google OAuth 로그인 ──────────────────────────────────────────────────
  /// Google OAuth 로그인을 수행한다
  /// google_sign_in 패키지가 OAuth 플로우 전체를 처리한다
  /// Windows에서는 google_sign_in 구현이 없으므로 즉시 미인증 상태를 반환한다
  Future<AuthState> signInWithGoogle() async {
    // Windows 플랫폼 가드: google_sign_in 구현 없음
    if (!isAuthSupported) return const AuthState.unauthenticated();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // 사용자가 로그인을 취소한 경우
        throw AppException(
          message: '로그인이 취소되었어요',
          level: AppErrorLevel.validation,
        );
      }
      return AuthState.fromGoogleAccount(account);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException.authFailed(cause: e);
    }
  }

  // ─── 세션 복원 ────────────────────────────────────────────────────────────
  /// 앱 시작 시 Google Sign-In 저장 세션으로 인증 상태를 복원한다
  /// signInSilently()는 이전에 로그인한 계정을 자동으로 복원한다
  /// Windows에서는 google_sign_in 구현이 없으므로 즉시 미인증 상태를 반환한다
  Future<AuthState> restoreSession() async {
    // Windows 플랫폼 가드: google_sign_in 구현 없음
    if (!isAuthSupported) {
      if (kDebugMode) debugPrint('[Auth] restoreSession: 인증 미지원 플랫폼 → 미인증');
      return const AuthState.unauthenticated();
    }

    try {
      if (kDebugMode) debugPrint('[Auth] signInSilently 시작...');
      final account = await _googleSignIn.signInSilently();
      // 이메일 등 개인정보(PII)를 릴리스 빌드에서 로깅하지 않도록 kDebugMode 가드를 적용한다
      if (kDebugMode) {
        debugPrint('[Auth] signInSilently 완료: ${account?.email ?? "null"}');
      }
      if (account == null) return const AuthState.unauthenticated();
      return AuthState.fromGoogleAccount(account);
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] signInSilently 실패: $e');
      return const AuthState.unauthenticated();
    }
  }

  // ─── 로그아웃 ─────────────────────────────────────────────────────────────
  /// 로그아웃을 수행한다
  /// 로컬 데이터는 유지하고 Google 세션만 해제한다
  /// Windows에서는 google_sign_in 구현이 없으므로 즉시 반환한다
  Future<void> signOut() async {
    if (!isAuthSupported) return;
    await _googleSignIn.signOut();
  }

  // ─── 계정 연결 해제 ────────────────────────────────────────────────────────
  /// Google 계정 연결을 완전히 해제한다 (disconnect)
  /// 앱 접근 권한을 취소하고 로그아웃 처리한다
  /// Windows에서는 google_sign_in 구현이 없으므로 즉시 반환한다
  Future<void> deleteAccount() async {
    if (!isAuthSupported) return;

    if (currentState.userId == null) {
      throw AppException.authExpired();
    }
    // Google 계정 연결 해제 (앱 접근 권한 취소)
    await _googleSignIn.disconnect();
    // 개인정보 보호: 계정 삭제 시 로컬 Hive 데이터를 모두 삭제한다
    // GDPR/PIPA 삭제권 준수
    await HiveInitializer.clearAll();
    // clearAll 후 빈 박스를 다시 열어 앱 크래시를 방지한다
    // (Provider들이 Hive 박스에 접근 시도할 때 HiveError 발생 방지)
    await HiveInitializer.init();
  }

  // ─── 인증 상태 변경 스트림 ────────────────────────────────────────────────
  /// Google Sign-In 인증 상태 변경 이벤트 스트림
  /// AuthStateNotifier에서 실시간 인증 상태를 감시하는 데 사용한다
  /// Windows에서는 빈 스트림을 반환하여 구독 시 크래시를 방지한다
  Stream<GoogleSignInAccount?> get onCurrentUserChanged {
    // Windows에서는 google_sign_in 구현이 없으므로 빈 스트림을 반환한다
    if (!isAuthSupported) return const Stream.empty();
    return _googleSignIn.onCurrentUserChanged;
  }
}
