// C0.3: 인증 상태 Riverpod Provider
// Google Sign-In 기반 인증 상태를 관리한다.
// onCurrentUserChanged 스트림을 구독하여 실시간 인증 상태를 반영한다.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../error/error_handler.dart';
import '../providers/data_store_providers.dart';
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
  final Ref _ref;
  StreamSubscription<GoogleSignInAccount?>? _authSubscription;

  AuthStateNotifier(this._authService, this._ref)
      : super(const AsyncLoading()) {
    // Google Sign-In 인증 상태 변경 스트림을 구독한다
    // Windows 등 미지원 플랫폼에서는 빈 스트림이 반환되므로 안전하지만,
    // 예상치 못한 플랫폼 예외에 대비해 try-catch로 이중 보호한다
    try {
      _authSubscription =
          _authService.onCurrentUserChanged.listen(_handleAuthEvent);
    } catch (_) {
      // 스트림 구독 실패 시 미인증 상태로 안전하게 초기화한다
      state = const AsyncData(AuthState.unauthenticated());
    }
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
  /// 예외 발생 시 미인증 상태를 유지하고 호출자에게 예외를 전파한다
  Future<AuthState> signInWithGoogle() async {
    try {
      final authState = await _authService.signInWithGoogle();
      state = AsyncData(authState);
      return authState;
    } catch (e, stack) {
      // 로그인 실패 시 미인증 상태를 유지하여 일관된 상태를 보장한다
      state = const AsyncData(AuthState.unauthenticated());
      ErrorHandler.logServiceError('AuthStateNotifier:signInWithGoogle', e, stack);
      rethrow;
    }
  }

  /// 로그아웃을 수행한다
  /// 상태를 먼저 미인증으로 전환하여 UI 일관성을 보장한 뒤 signOut을 시도한다
  Future<void> logout() async {
    // 상태를 먼저 미인증으로 전환하여 UI가 즉시 반영되도록 한다
    state = const AsyncData(AuthState.unauthenticated());
    try {
      await _authService.signOut();
    } catch (e, stack) {
      // signOut 실패 시에도 미인증 상태를 유지한다 (이미 전환 완료)
      ErrorHandler.logServiceError('AuthStateNotifier:logout', e, stack);
    }
  }

  /// 계정 연결을 해제한다
  /// Hive clearAll → init 사이에 Provider 리빌드가 Hive 박스에 접근하면
  /// HiveError가 발생하므로, 먼저 인증 상태를 미인증으로 전환하여
  /// 라우터가 데이터 화면을 언마운트하게 한 뒤 삭제를 수행한다
  Future<void> deleteAccount() async {
    // 1) 인증 상태를 먼저 미인증으로 전환하여 데이터 화면을 언마운트한다
    state = const AsyncData(AuthState.unauthenticated());

    // 2) 상태 전환 후 다음 마이크로태스크에서 위젯 트리가 리빌드되도록 한 틱 대기
    await Future<void>.delayed(Duration.zero);

    // 3) 데이터 화면이 제거된 상태에서 안전하게 계정 삭제 + Hive 초기화를 수행한다
    try {
      await _authService.deleteAccount();
      // 4) clearAll → init 후 빈 박스가 열렸지만 Provider의 버전 카운터가 그대로이므로
      //    모든 버전을 강제 갱신하여 Provider가 빈 데이터를 다시 읽도록 한다
      bumpAllDataVersions(_ref);
    } catch (e, stack) {
      // 삭제 실패를 로깅하고 호출자가 에러를 처리할 수 있도록 전파한다
      ErrorHandler.logServiceError('AuthStateNotifier:deleteAccount', e, stack);
      rethrow;
    }
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

  return AuthStateNotifier(authService, ref);
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
