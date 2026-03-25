// C0.CalSync: Google Calendar 동기화 Provider Barrel Export
// 하위 호환성을 위해 분리된 파일들을 재수출한다.
// 기존에 이 파일을 import하던 코드가 변경 없이 동작하도록 보장한다.

// GoogleSignIn + GoogleCalendarService 인스턴스 Provider
export 'google_sign_in_provider.dart';

// 동기화 상태 + Google 이벤트 + 수동 동기화 액션 Provider
export 'sync_state_providers.dart';

// 앱 이벤트 + Google 이벤트 병합 Provider (일별/월별)
export 'merged_event_providers.dart';

// 날짜별 이벤트 유무 맵 Provider (MonthlyView dot 표시용)
export 'merged_date_map_provider.dart';
