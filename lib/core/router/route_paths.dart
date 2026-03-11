// C0.4: 라우트 경로 상수
// 앱 전체에서 사용하는 URL 경로를 중앙 집중 관리한다.
// /splash, /login, /home, /calendar, /todo, /habit, /goal 등을 정의한다.

/// 앱 라우트 경로 상수
/// GoRouter 설정 및 navigate 호출 시 이 클래스만 참조한다
abstract class RoutePaths {
  /// 스플래시 화면 (JWT 세션 복원 + Auth 확인)
  static const String splash = '/';

  /// 로그인 화면 (Google 로그인 버튼)
  static const String login = '/login';

  /// 홈 대시보드 (F1)
  static const String home = '/home';

  /// 캘린더 (F2)
  static const String calendar = '/calendar';

  /// 투두 (F3)
  static const String todo = '/todo';

  /// 습관/루틴 (F4)
  static const String habit = '/habit';

  /// 목표/만다라트 (F5)
  static const String goal = '/goal';

  /// 온보딩 화면 (신규 사용자: 개인정보 동의 + 이름 입력)
  static const String onboarding = '/onboarding';

  /// 포모도로 타이머 (F6)
  /// StatefulShellRoute 바깥 독립 라우트 (하단 탭에 포함되지 않음)
  static const String timer = '/timer';

  /// 업적/배지 화면 (F8)
  /// StatefulShellRoute 바깥 독립 라우트 (홈 대시보드 카드에서 진입)
  static const String achievements = '/achievements';

  /// 404 에러 화면 (존재하지 않는 경로 접근 시)
  static const String notFound = '/404';

  /// 태그 관리 화면 (F16)
  /// 설정 화면에서 진입하는 독립 라우트 (하단 탭 없음)
  static const String tagManagement = '/tag-management';
}

/// 하단 네비게이션 탭 인덱스
/// StatefulShellRoute.indexedStack에서 탭 순서와 일치해야 한다
abstract class TabIndex {
  static const int home = 0;
  static const int calendar = 1;
  static const int todo = 2;
  static const int habit = 3;
  static const int goal = 4;
}
