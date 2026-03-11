// C0.3: 인증 상태 Riverpod Provider
// Google Sign-In 기반 인증 상태를 관리한다.
// onCurrentUserChanged 스트림을 구독하여 실시간 인증 상태를 반영한다.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

// ─── AuthService Provider ─────────────────────────────────────────────────
/// AuthService 싱글톤 Provider
/// 외부 의존성 없이 직접 생성한다
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ─── 인증 상태 StateNotifier ─────────────────────────────────────────────
/// Google Sign-In 기반 인증 상태 Notifier
/// onCurrentUserChanged 스트림을 구독하여 자동으로 인증 상태를 갱신한다
class AuthStateNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final AuthService _authService;
  StreamSubscription<GoogleSignInAccount?>? _authSubscription;

  AuthStateNotifier(this._authService)
      : super(const AsyncLoading()) {
    // Google Sign-In 인증 상태 변경 스트림을 구독한다
    _authSubscription =
        _authService.onCurrentUserChanged.listen(_handleAuthEvent);
  }

  /// Google Sign-In 인증 이벤트를 처리하여 상태를 갱신한다
  void _handleAuthEvent(GoogleSignInAccount? account) {
    if (account != null) {
      // 로그인 또는 계정 변경 시 인증 상태를 갱신한다
      state = AsyncData(AuthState.fromGoogleAccount(account));
    } else {
      // 로그아웃 시 미인증 상태로 전환한다
      state = const AsyncData(AuthState.unauthenticated());
    }
  }

  /// 앱 시작 시 Google Sign-In 저장 세션으로 인증을 복원한다
  /// 세션 복원 실패 시에도 미인증 상태로 앱이 정상 시작되도록 한다
  /// 로컬 퍼스트 아키텍처: 인증 없이도 앱의 모든 기능이 동작한다
  Future<void> restoreSession() async {
    state = const AsyncLoading();
    try {
      final authState = await _authService.restoreSession();
      // 세션 복원 성공 또는 미인증 상태 모두 정상 처리한다
      state = AsyncData(authState);
    } catch (_) {
      // 세션 복원 실패 시 미인증 상태로 앱을 시작한다 (로컬 모드 진입)
      state = const AsyncData(AuthState.unauthenticated());
    }
  }

  /// Google OAuth 로그인을 수행한다
  Future<AuthState> signInWithGoogle() async {
    final authState = await _authService.signInWithGoogle();
    state = AsyncData(authState);
    return authState;
  }

  /// 로그아웃을 수행한다
  Future<void> logout() async {
    await _authService.signOut();
    state = const AsyncData(AuthState.unauthenticated());
  }

  /// 계정 연결을 해제한다
  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
    state = const AsyncData(AuthState.unauthenticated());
  }

  /// 인증 상태를 강제로 미인증으로 설정한다 (에러 발생 시)
  void forceUnauthenticated() {
    state = const AsyncData(AuthState.unauthenticated());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

// ─── 인증 상태 Provider ─────────────────────────────────────────────────
/// 인증 상태 StateNotifier Provider
/// Google Sign-In onCurrentUserChanged 스트림으로 실시간 인증 상태를 관리한다
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AuthState>>((ref) {
  final authService = ref.watch(authServiceProvider);

  return AuthStateNotifier(authService);
});

// ─── 하위 호환 Provider (기존 StreamProvider 대체) ───────────────────────
/// 기존 StreamProvider 인터페이스와 호환되는 Provider
/// UI 코드에서 authStateStreamProvider를 참조하는 부분의 변경을 최소화한다
final authStateStreamProvider = Provider<AsyncValue<AuthState>>((ref) {
  return ref.watch(authStateProvider);
});

// ─── 현재 사용자 ID Provider ─────────────────────────────────────────────
/// 현재 로그인한 사용자의 UID를 반환한다
/// null이면 미인증 상태
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.userId;
});

// ─── 현재 인증 상태 Provider ─────────────────────────────────────────────
/// 현재 AuthState를 반환한다
final currentAuthStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authStateProvider).valueOrNull ??
      const AuthState.unauthenticated();
});

// ─── 로그인 여부 Provider ────────────────────────────────────────────────
/// 사용자가 로그인되어 있는지 여부
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentAuthStateProvider).isAuthenticated;
});
