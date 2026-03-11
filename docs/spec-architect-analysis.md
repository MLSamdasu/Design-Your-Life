# Design Your Life - 기술 아키텍처 분석서

**작성자**: spec-architect
**작성일**: 2026-03-09
**대상**: Flutter 3.29 (Web + Android) 생산성 앱

---

## 1. 전체 아키텍처 개요도

```
                       ┌──────────────────────────────────────────────┐
                       │              Flutter Application             │
                       │              (Single Codebase)               │
                       ├──────────────────────────────────────────────┤
                       │                                              │
                       │   ┌──────────────────────────────────────┐   │
                       │   │          Presentation Layer           │   │
                       │   │   GoRouter + 5 Tab Screens + Widgets │   │
                       │   └──────────────┬───────────────────────┘   │
                       │                  │ watches / reads            │
                       │   ┌──────────────▼───────────────────────┐   │
                       │   │         State Layer (Riverpod)        │   │
                       │   │  Providers / Notifiers / StateModels  │   │
                       │   └──────────────┬───────────────────────┘   │
                       │                  │ calls                     │
                       │   ┌──────────────▼───────────────────────┐   │
                       │   │         Domain / Service Layer        │   │
                       │   │   Repositories + Use Cases (Atomic)   │   │
                       │   └──────┬───────────────┬───────────────┘   │
                       │          │               │                   │
                       │   ┌──────▼──────┐ ┌──────▼──────┐           │
                       │   │  Firestore  │ │  Hive Local │           │
                       │   │  Gateway    │ │  Cache      │           │
                       │   └──────┬──────┘ └──────┬──────┘           │
                       │          │               │                   │
                       └──────────┼───────────────┼───────────────────┘
                                  │               │
                       ┌──────────▼──────┐        │ (로컬 디스크)
                       │  Firebase Cloud  │        │
                       │  ┌─────────────┐ │        │
                       │  │  Firestore   │ │        │
                       │  │  Auth        │ │        │
                       │  │  Hosting     │ │        │
                       │  └─────────────┘ │        │
                       └──────────────────┘        │
                                                   │
                                            ┌──────▼──────┐
                                            │  Hive Boxes  │
                                            │  (IndexedDB  │
                                            │   / File)    │
                                            └─────────────┘
```

**계층 흐름 원칙**: UI -> State -> Service -> Data (단방향). 하위에서 상위 참조 금지.

---

## 2. 프로젝트 폴더 구조

Feature-based 폴더 구조를 채택한다. SRP 원칙에 따라 core(C0 공통), shared(공유 타입), features(F1~F5 기능)를 물리적으로 분리한다.

```
lib/
├── main.dart                          # 앱 진입점 (Firebase init -> runApp)
├── app.dart                           # MaterialApp.router 설정
│
├── core/                              # C0: 공통 인프라 모듈
│   ├── firebase/
│   │   ├── firebase_initializer.dart  # C0.1 Firebase 초기화
│   │   └── firestore_gateway.dart     # C0.2 Firestore CRUD 래퍼
│   ├── auth/
│   │   ├── auth_service.dart          # C0.3 Firebase Auth 서비스
│   │   └── auth_provider.dart         # C0.3 인증 상태 Riverpod provider
│   ├── router/
│   │   ├── app_router.dart            # C0.4 GoRouter 설정
│   │   └── route_paths.dart           # C0.4 라우트 경로 상수
│   ├── theme/
│   │   ├── app_theme.dart             # C0.5 라이트/다크 ThemeData
│   │   ├── color_tokens.dart          # C0.5 디자인 토큰 (컬러)
│   │   ├── typography_tokens.dart     # C0.5 디자인 토큰 (타이포그래피)
│   │   └── glassmorphism.dart         # C0.5 글래스모피즘 데코레이션 유틸
│   ├── cache/
│   │   ├── hive_initializer.dart      # C0.6 Hive 초기화 + Box 등록
│   │   └── hive_cache_service.dart    # C0.6 캐시 읽기/쓰기 범용
│   ├── constants/
│   │   ├── app_constants.dart         # C0.7 앱 전역 상수
│   │   └── firestore_paths.dart       # C0.7 Firestore 컬렉션 경로 상수
│   ├── error/
│   │   ├── app_exception.dart         # C0.8 커스텀 예외 클래스
│   │   └── error_handler.dart         # C0.8 전역 에러 핸들링
│   └── utils/
│       ├── date_utils.dart            # C0.9 날짜 포맷/변환 유틸
│       └── color_utils.dart           # C0.9 색상 변환 유틸
│
├── shared/                            # 공유 모델 및 위젯
│   ├── models/                        # 데이터 모델 (Firestore <-> Dart)
│   │   ├── user_profile.dart
│   │   ├── event.dart
│   │   ├── todo.dart
│   │   ├── habit.dart
│   │   ├── habit_log.dart
│   │   ├── routine.dart
│   │   ├── goal.dart
│   │   ├── sub_goal.dart
│   │   ├── task.dart
│   │   └── mandalart.dart
│   ├── enums/
│   │   ├── event_type.dart            # EventType (일반/범위/반복/할일)
│   │   ├── repeat_cycle.dart          # RepeatCycle (매일/매주/매월)
│   │   ├── goal_period.dart           # GoalPeriod (년간/월간)
│   │   ├── view_type.dart             # ViewType (월간/주간/일간)
│   │   └── day_of_week.dart           # DayOfWeek (월~일)
│   ├── widgets/                       # 공용 위젯
│   │   ├── glassmorphic_card.dart     # 글래스모피즘 카드
│   │   ├── donut_chart.dart           # 도넛 차트 공용 위젯
│   │   ├── color_picker.dart          # 8색 컬러 피커
│   │   ├── empty_state.dart           # 빈 상태 UI
│   │   ├── loading_indicator.dart     # 로딩 인디케이터
│   │   ├── bottom_nav_bar.dart        # 플로팅 캡슐 하단 네비게이션
│   │   └── date_slider.dart           # 주간 날짜 슬라이더
│   └── extensions/
│       ├── datetime_ext.dart          # DateTime 확장 메서드
│       └── string_ext.dart            # String 확장 메서드
│
├── features/                          # F1~F5: 기능 모듈
│   ├── home/                          # F1: 홈 대시보드
│   │   ├── presentation/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   │       ├── greeting_card.dart
│   │   │       ├── today_todo_summary.dart
│   │   │       ├── today_habit_summary.dart
│   │   │       ├── dday_card_list.dart
│   │   │       └── weekly_summary.dart
│   │   ├── providers/
│   │   │   └── home_provider.dart
│   │   └── services/
│   │       └── home_aggregator.dart   # 각 Feature 데이터 집계
│   │
│   ├── calendar/                      # F2: 캘린더
│   │   ├── presentation/
│   │   │   ├── calendar_screen.dart
│   │   │   └── widgets/
│   │   │       ├── monthly_view.dart
│   │   │       ├── weekly_view.dart
│   │   │       ├── daily_view.dart
│   │   │       ├── event_dot.dart
│   │   │       ├── time_indicator.dart
│   │   │       └── event_create_dialog.dart
│   │   ├── providers/
│   │   │   ├── calendar_provider.dart
│   │   │   └── event_provider.dart
│   │   └── services/
│   │       ├── event_repository.dart
│   │       └── event_mapper.dart
│   │
│   ├── todo/                          # F3: 투두
│   │   ├── presentation/
│   │   │   ├── todo_screen.dart
│   │   │   └── widgets/
│   │   │       ├── daily_schedule_view.dart
│   │   │       ├── todo_list_view.dart
│   │   │       ├── todo_item_tile.dart
│   │   │       ├── todo_create_dialog.dart
│   │   │       └── todo_stats_card.dart
│   │   ├── providers/
│   │   │   └── todo_provider.dart
│   │   └── services/
│   │       ├── todo_repository.dart
│   │       └── todo_filter.dart
│   │
│   ├── habit/                         # F4: 습관 + 루틴
│   │   ├── presentation/
│   │   │   ├── habit_screen.dart      # 서브탭 컨테이너
│   │   │   └── widgets/
│   │   │       ├── habit_tracker_view.dart
│   │   │       ├── habit_card.dart
│   │   │       ├── habit_calendar.dart
│   │   │       ├── streak_badge.dart
│   │   │       ├── routine_list_view.dart
│   │   │       ├── routine_card.dart
│   │   │       └── routine_create_dialog.dart
│   │   ├── providers/
│   │   │   ├── habit_provider.dart
│   │   │   └── routine_provider.dart
│   │   └── services/
│   │       ├── habit_repository.dart
│   │       ├── habit_log_repository.dart
│   │       ├── routine_repository.dart
│   │       ├── streak_calculator.dart
│   │       └── time_lock_validator.dart
│   │
│   └── goal/                          # F5: 목표 + 만다라트
│       ├── presentation/
│       │   ├── goal_screen.dart       # 서브탭 컨테이너
│       │   └── widgets/
│       │       ├── goal_list_view.dart
│       │       ├── goal_card.dart
│       │       ├── goal_create_dialog.dart
│       │       ├── goal_stats_header.dart
│       │       ├── mandalart_view.dart
│       │       ├── mandalart_grid.dart
│       │       └── mandalart_wizard.dart
│       ├── providers/
│       │   ├── goal_provider.dart
│       │   └── mandalart_provider.dart
│       └── services/
│           ├── goal_repository.dart
│           ├── sub_goal_repository.dart
│           ├── task_repository.dart
│           ├── progress_calculator.dart
│           └── mandalart_mapper.dart
│
└── generated/                         # 자동 생성 파일 (freezed, json_serializable 등)
```

**핵심 원칙**:
- core/ 안의 파일은 features/ 를 절대 import하지 않는다.
- features/ 간 직접 import 금지. Feature 간 데이터 교환은 shared/models/를 통해 Riverpod provider가 중개한다.
- shared/는 core/만 의존할 수 있고, features/를 참조하지 않는다.
- 의존 방향: features/ -> shared/ -> core/ (단방향).

---

## 3. 모듈 계층 설계 (C0 + F1~F5)

### 3.1 C0: 공통 인프라 모듈

```
C0.1 FirebaseInitializer
  IN (메인): 없음 (앱 시작 시 자동 실행)
  IN (보조): firebase_options.dart (FlutterFire CLI 생성)
  OUT: FirebaseApp (초기화 완료된 Firebase 인스턴스)

C0.2 FirestoreGateway
  IN (메인): FirebaseApp (C0.1의 OUT)
  IN (보조): collection_path: String, document_id: String
  OUT: FirestoreGateway (CRUD 메서드를 가진 래퍼 인스턴스)
  설명: Firestore 직접 접근을 캡슐화한다. 모든 Feature는 이 게이트웨이를 통해서만 Firestore에 접근한다.

C0.3 AuthService
  IN (메인): FirebaseApp (C0.1의 OUT)
  OUT: AuthState (userId, displayName, photoUrl, isAuthenticated)
  설명: Google 로그인/로그아웃/상태감시를 담당한다.

C0.4 AppRouter
  IN (메인): AuthState (C0.3의 OUT)
  IN (보조): route_paths 상수
  OUT: GoRouter (인증 상태 기반 라우트 가드 포함)

C0.5 ThemeManager
  IN (메인): 없음 (시스템 설정 + 사용자 선택)
  OUT: ThemeData (라이트/다크 테마)
  설명: 컬러 토큰, 타이포그래피 토큰, 글래스모피즘 데코레이션을 포함한다.

C0.6 HiveCacheManager
  IN (메인): 없음 (앱 시작 시 초기화)
  OUT: HiveCacheService (Box 읽기/쓰기 메서드)
  설명: 오프라인 캐싱을 위한 Hive Box 관리. Web에서는 IndexedDB, Android에서는 파일 시스템을 사용한다.

C0.7 AppConstants
  IN: 없음 (정적 상수)
  OUT: 상수 값들 (Firestore 경로, 컬러 팔레트 인덱스, 날짜 포맷 등)

C0.8 ErrorHandler
  IN (메인): Exception 또는 Error
  OUT: AppException (구조화된 에러 정보)
  설명: 전역 에러를 포착하여 사용자 친화적 메시지로 변환한다.

C0.9 DateTimeUtils
  IN (메인): DateTime
  OUT: 포맷된 문자열 또는 변환된 DateTime
  설명: 날짜 포맷, 주차 계산, D-day 계산 등 순수 함수 집합.
```

### 3.2 F1: 홈 대시보드

```
F1 메인 파이프라인:
[F1.1 TodayTodoAggregator] → [F1.2 TodayHabitAggregator] → [F1.3 DdayCollector] → [F1.4 WeeklySummarizer] → [F1.5 HomeOrchestrator]
                                                                                                                   ↑ C0.2 (Firestore)
                                                                                                                   ↑ C0.9 (DateUtils)

F1.1 TodayTodoAggregator
  IN (메인): userId: String (C0.3 AuthState에서 추출)
  IN (보조): today: DateTime (C0.9), firestoreGateway: FirestoreGateway (C0.2)
  OUT: TodoSummary (totalCount, completedCount, completionRate, previewItems)

F1.2 TodayHabitAggregator
  IN (메인): userId: String
  IN (보조): today: DateTime, firestoreGateway: FirestoreGateway
  OUT: HabitSummary (totalCount, completedCount, achievementRate, previewCards)

F1.3 DdayCollector
  IN (메인): userId: String
  IN (보조): today: DateTime, firestoreGateway: FirestoreGateway
  OUT: List<DdayItem> (eventName, daysRemaining, urgencyLevel)

F1.4 WeeklySummarizer
  IN (메인): TodoSummary + HabitSummary (F1.1 + F1.2의 OUT)
  IN (보조): weekRange: DateRange (C0.9)
  OUT: WeeklySummary (todoWeekRate, habitWeekRate, trend)

F1.5 HomeOrchestrator
  IN (메인): F1.1~F1.4의 OUT 전부
  OUT: HomeViewState (모든 대시보드 데이터를 담은 단일 상태 객체)
  설명: 직접 로직 수행 금지. F1.1~F1.4를 호출하고 결과를 HomeViewState로 조합만 한다.
```

### 3.3 F2: 캘린더

```
F2 메인 파이프라인:
[F2.1 EventFetcher] → [F2.2 RoutineOverlayer] → [F2.3 EventMapper] → [F2.4 CalendarOrchestrator]
                                                                         ↑ C0.2 (Firestore)

F2.1 EventFetcher
  IN (메인): userId: String, dateRange: DateRange
  IN (보조): firestoreGateway: FirestoreGateway (C0.2)
  OUT: List<Event> (지정 기간 내 이벤트 목록)

F2.2 RoutineOverlayer
  IN (메인): List<Event> (F2.1의 OUT)
  IN (보조): List<Routine> (F4 데이터, provider를 통해 전달)
  OUT: List<CalendarEntry> (이벤트 + 활성 루틴이 합쳐진 목록)
  설명: 활성화된 루틴을 해당 요일의 타임라인 항목으로 변환하여 이벤트와 합친다.

F2.3 EventMapper
  IN (메인): List<CalendarEntry> (F2.2의 OUT)
  IN (보조): ViewType (월간/주간/일간)
  OUT: CalendarViewData (뷰 타입에 맞게 매핑된 데이터)

F2.4 CalendarOrchestrator
  IN (메인): CalendarViewData (F2.3의 OUT)
  OUT: CalendarViewState (화면 렌더링용 최종 상태)
```

### 3.4 F3: 투두

```
F3 메인 파이프라인:
[F3.1 TodoFetcher] → [F3.2 TodoFilter] → [F3.3 TodoStatsCalculator] → [F3.4 TodoOrchestrator]
                                                                          ↑ C0.2 (Firestore)

F3.1 TodoFetcher
  IN (메인): userId: String, targetDate: DateTime
  IN (보조): firestoreGateway: FirestoreGateway (C0.2)
  OUT: List<Todo> (해당 날짜의 투두 목록)

F3.2 TodoFilter
  IN (메인): List<Todo> (F3.1의 OUT)
  IN (보조): filterType: TodoFilterType (전체/완료/미완료)
  OUT: List<Todo> (필터링된 투두 목록)

F3.3 TodoStatsCalculator
  IN (메인): List<Todo> (F3.1의 OUT, 필터 적용 전 원본)
  OUT: TodoStats (totalCount, completedCount, completionRate, 유형별 카운트)

F3.4 TodoOrchestrator
  IN (메인): F3.1~F3.3의 OUT
  OUT: TodoViewState
```

### 3.5 F4: 습관 + 루틴

```
F4 메인 파이프라인 (습관):
[F4.1 HabitFetcher] → [F4.2 HabitLogFetcher] → [F4.3 StreakCalculator] → [F4.4 TimeLockValidator] → [F4.5 HabitOrchestrator]
                                                                                                       ↑ C0.2 (Firestore)

F4 메인 파이프라인 (루틴):
[F4.6 RoutineFetcher] → [F4.7 RoutineScheduler] → [F4.8 RoutineOrchestrator]

F4.1 HabitFetcher
  IN (메인): userId: String
  IN (보조): firestoreGateway: FirestoreGateway (C0.2)
  OUT: List<Habit> (사용자의 습관 정의 목록)

F4.2 HabitLogFetcher
  IN (메인): userId: String, targetDate: DateTime
  IN (보조): firestoreGateway: FirestoreGateway (C0.2)
  OUT: List<HabitLog> (해당 날짜의 습관 체크 기록)

F4.3 StreakCalculator
  IN (메인): habitId: String, allLogs: List<HabitLog>
  IN (보조): today: DateTime (C0.9)
  OUT: StreakResult (currentStreak: int, longestStreak: int)
  설명: 순수 함수. 연속 달성일수를 계산한다.

F4.4 TimeLockValidator
  IN (메인): targetDate: DateTime
  IN (보조): now: DateTime
  OUT: TimeLockResult (isEditable: bool, reason: String)
  설명: 자정 기준 시간 잠금 검증. 과거일 수정 불가 정책 적용.

F4.5 HabitOrchestrator
  IN (메인): F4.1~F4.4의 OUT
  OUT: HabitViewState

F4.6 RoutineFetcher
  IN (메인): userId: String
  IN (보조): firestoreGateway: FirestoreGateway (C0.2)
  OUT: List<Routine> (루틴 목록)

F4.7 RoutineScheduler
  IN (메인): List<Routine> (F4.6의 OUT)
  IN (보조): targetWeek: DateRange
  OUT: Map<DayOfWeek, List<ScheduledRoutine>> (요일별 루틴 배치)

F4.8 RoutineOrchestrator
  IN (메인): F4.6~F4.7의 OUT
  OUT: RoutineViewState
```

### 3.6 F5: 목표 + 만다라트

```
F5 메인 파이프라인:
[F5.1 GoalFetcher] → [F5.2 SubGoalFetcher] → [F5.3 TaskFetcher] → [F5.4 ProgressCalculator] → [F5.5 MandalartMapper] → [F5.6 GoalOrchestrator]
                                                                                                                           ↑ C0.2 (Firestore)

F5.1 GoalFetcher
  IN (메인): userId: String, period: GoalPeriod
  IN (보조): firestoreGateway: FirestoreGateway (C0.2)
  OUT: List<Goal> (년간 또는 월간 목표 목록)

F5.2 SubGoalFetcher
  IN (메인): goalId: String
  IN (보조): firestoreGateway: FirestoreGateway (C0.2)
  OUT: List<SubGoal> (해당 목표의 하위 목표)

F5.3 TaskFetcher
  IN (메인): subGoalId: String
  IN (보조): firestoreGateway: FirestoreGateway (C0.2)
  OUT: List<Task> (해당 하위 목표의 실천 할일)

F5.4 ProgressCalculator
  IN (메인): List<Goal> + List<SubGoal> + List<Task>
  OUT: GoalProgress (achievementRate, avgProgress, totalGoalCount, 목표별 진행률)
  설명: 순수 함수. 하위 할일 완료율을 상위로 자동 집계한다.

F5.5 MandalartMapper
  IN (메인): Goal (핵심 목표 1개) + List<SubGoal> (8개) + List<List<Task>> (각 8개)
  OUT: MandalartGrid (9x9 셀 데이터)
  설명: 순수 함수. 목표 계층 데이터를 9x9 만다라트 그리드 구조로 매핑한다.

F5.6 GoalOrchestrator
  IN (메인): F5.1~F5.5의 OUT
  OUT: GoalViewState
```

---

## 4. 공유 타입 정의 (shared/models/)

모든 모델은 `freezed` + `json_serializable`로 불변 객체를 생성한다. Firestore 직렬화를 위해 `fromJson`/`toJson` 팩토리를 포함한다.

### 4.1 UserProfile

```dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,
    @Default(false) bool isDarkMode,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
```

### 4.2 Event (캘린더 일정)

```dart
@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    required String userId,
    required String title,
    required EventType type,        // 일반, 범위, 반복, 할일
    required DateTime startDate,
    DateTime? endDate,              // 범위 일정용
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    required int colorIndex,        // 0~7 (8가지 색상)
    String? location,
    String? memo,
    RepeatCycle? repeatCycle,       // 반복 일정용
    List<int>? repeatDays,          // 반복 요일 (1=월 ~ 7=일)
    String? rangeTag,               // 범위 일정 태그 (여행/시험/휴가/프로젝트/기타)
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) =>
      _$EventFromJson(json);
}
```

### 4.3 Todo

```dart
@freezed
class Todo with _$Todo {
  const factory Todo({
    required String id,
    required String userId,
    required String title,
    required DateTime date,
    TimeOfDay? time,
    @Default(false) bool isCompleted,
    required int colorIndex,
    String? memo,
    String? linkedGoalId,           // 목표 연동 (선택)
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) =>
      _$TodoFromJson(json);
}
```

### 4.4 Habit

```dart
@freezed
class Habit with _$Habit {
  const factory Habit({
    required String id,
    required String userId,
    required String name,
    String? icon,                   // 이모지 아이콘
    required int colorIndex,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _Habit;

  factory Habit.fromJson(Map<String, dynamic> json) =>
      _$HabitFromJson(json);
}
```

### 4.5 HabitLog

```dart
@freezed
class HabitLog with _$HabitLog {
  const factory HabitLog({
    required String id,
    required String habitId,
    required String userId,
    required DateTime date,         // 날짜만 (시간 제외, yyyy-MM-dd 기준)
    @Default(false) bool isCompleted,
    required DateTime checkedAt,    // 실제 체크한 시각
  }) = _HabitLog;

  factory HabitLog.fromJson(Map<String, dynamic> json) =>
      _$HabitLogFromJson(json);
}
```

### 4.6 Routine

```dart
@freezed
class Routine with _$Routine {
  const factory Routine({
    required String id,
    required String userId,
    required String name,
    required List<int> repeatDays,  // 반복 요일 (1=월 ~ 7=일)
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int colorIndex,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Routine;

  factory Routine.fromJson(Map<String, dynamic> json) =>
      _$RoutineFromJson(json);
}
```

### 4.7 Goal

```dart
@freezed
class Goal with _$Goal {
  const factory Goal({
    required String id,
    required String userId,
    required String title,
    String? description,
    required GoalPeriod period,     // 년간 / 월간
    required int year,
    int? month,                     // 월간 목표일 때만
    @Default(false) bool isCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) =>
      _$GoalFromJson(json);
}
```

### 4.8 SubGoal

```dart
@freezed
class SubGoal with _$SubGoal {
  const factory SubGoal({
    required String id,
    required String goalId,
    required String title,
    @Default(false) bool isCompleted,
    required int orderIndex,        // 만다라트 위치 (0~7)
    required DateTime createdAt,
  }) = _SubGoal;

  factory SubGoal.fromJson(Map<String, dynamic> json) =>
      _$SubGoalFromJson(json);
}
```

### 4.9 Task (실천 할일)

```dart
@freezed
class GoalTask with _$GoalTask {
  const factory GoalTask({
    required String id,
    required String subGoalId,
    required String title,
    @Default(false) bool isCompleted,
    required int orderIndex,        // 만다라트 위치 (0~7)
    required DateTime createdAt,
  }) = _GoalTask;

  factory GoalTask.fromJson(Map<String, dynamic> json) =>
      _$GoalTaskFromJson(json);
}
```

### 4.10 MandalartGrid (뷰 전용, Firestore 저장 불필요)

```dart
@freezed
class MandalartGrid with _$MandalartGrid {
  const factory MandalartGrid({
    required String coreGoalTitle,
    required List<MandalartCell> cells,  // 81개 (9x9)
  }) = _MandalartGrid;
}

@freezed
class MandalartCell with _$MandalartCell {
  const factory MandalartCell({
    required int row,
    required int col,
    required String text,
    required MandalartCellType type,     // core, subGoal, task, empty
    @Default(false) bool isCompleted,
  }) = _MandalartCell;
}
```

### 4.11 Enum 정의

```dart
enum EventType { normal, range, recurring, todo }

enum RepeatCycle { daily, weekly, monthly }

enum GoalPeriod { yearly, monthly }

enum ViewType { monthly, weekly, daily }

enum DayOfWeek { mon, tue, wed, thu, fri, sat, sun }

enum MandalartCellType { core, subGoal, task, empty }

enum UrgencyLevel { critical, warning, normal }
// critical: D-3 이하, warning: D-7 이하, normal: D-8 이상
```

---

## 5. Firestore 스키마 설계

### 5.1 컬렉션 구조

```
firestore-root/
└── users/                              # 컬렉션
    └── {userId}/                       # 문서 (UserProfile 필드)
        ├── events/                     # 서브컬렉션
        │   └── {eventId}/             # 문서 (Event 필드)
        ├── todos/                      # 서브컬렉션
        │   └── {todoId}/             # 문서 (Todo 필드)
        ├── habits/                     # 서브컬렉션
        │   └── {habitId}/            # 문서 (Habit 필드)
        ├── habitLogs/                  # 서브컬렉션
        │   └── {logId}/              # 문서 (HabitLog 필드)
        ├── routines/                   # 서브컬렉션
        │   └── {routineId}/          # 문서 (Routine 필드)
        └── goals/                      # 서브컬렉션
            └── {goalId}/              # 문서 (Goal 필드)
                ├── subGoals/          # 서브컬렉션
                │   └── {subGoalId}/  # 문서 (SubGoal 필드)
                └── tasks/             # 서브컬렉션 (subGoal 아래가 아닌 goal 아래에 플랫하게 배치)
                    └── {taskId}/     # 문서 (GoalTask 필드 + subGoalId 참조)
```

**tasks를 goal 아래에 플랫하게 배치하는 이유**: Firestore는 깊은 중첩 서브컬렉션일수록 쿼리가 복잡해진다. tasks를 goal 아래에 두고 `subGoalId` 필드로 필터링하면 특정 goal의 전체 tasks를 한 번에 가져올 수 있어 진행률 계산이 효율적이다. 서브컬렉션 3단 중첩(goals -> subGoals -> tasks)은 Firestore 컬렉션 그룹 쿼리 없이는 전체 조회가 불가능하다.

### 5.2 필수 복합 인덱스

```
1. events 인덱스:
   - userId(ASC) + startDate(ASC)           # 날짜 범위 쿼리
   - userId(ASC) + type(ASC) + startDate(ASC) # 유형별 필터링

2. todos 인덱스:
   - userId(ASC) + date(ASC)                # 날짜별 투두 조회
   - userId(ASC) + date(ASC) + isCompleted(ASC) # 완료 상태 필터링

3. habitLogs 인덱스:
   - userId(ASC) + habitId(ASC) + date(DESC) # 습관별 로그 조회 (스트릭 계산용)
   - userId(ASC) + date(ASC)                 # 날짜별 전체 로그

4. goals 인덱스:
   - userId(ASC) + period(ASC) + year(ASC)  # 기간별 목표 조회

5. tasks 인덱스 (goals 하위):
   - subGoalId(ASC) + orderIndex(ASC)        # 서브목표별 할일 정렬
```

### 5.3 Firestore 보안 규칙 핵심 원칙

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 인증된 사용자만 자신의 데이터에 접근 가능
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

- 모든 데이터는 `users/{userId}` 하위에 존재하므로 사용자 격리가 자연스럽게 적용된다.
- 추가 세분화(필드 검증, 크기 제한)는 spec-security와 협의하여 보안 규칙에 추가한다.

---

## 6. 상태 관리 아키텍처 (Riverpod)

### 6.1 Provider 계층 구조

```
                    ┌──────────────────────────────────┐
                    │     Global Providers (core/)      │
                    │  firebaseAppProvider              │
                    │  firestoreProvider                │
                    │  authStateProvider                │
                    │  currentUserProvider              │
                    │  themeProvider                    │
                    │  hiveCacheProvider                │
                    └──────────────┬───────────────────┘
                                   │ (DI 기반 주입)
                    ┌──────────────▼───────────────────┐
                    │   Repository Providers (per feature) │
                    │  eventRepositoryProvider          │
                    │  todoRepositoryProvider           │
                    │  habitRepositoryProvider          │
                    │  routineRepositoryProvider        │
                    │  goalRepositoryProvider           │
                    └──────────────┬───────────────────┘
                                   │
                    ┌──────────────▼───────────────────┐
                    │  Feature State Providers          │
                    │  homeViewStateProvider            │
                    │  calendarViewStateProvider        │
                    │  todoViewStateProvider            │
                    │  habitViewStateProvider           │
                    │  routineViewStateProvider         │
                    │  goalViewStateProvider            │
                    │  mandalartViewStateProvider       │
                    └──────────────────────────────────┘
```

### 6.2 Provider 타입 설계 원칙

| 용도 | Provider 타입 | 사용 시점 |
|---|---|---|
| Firebase/Auth 등 인프라 싱글톤 | `Provider<T>` | 앱 생명주기 동안 유지 |
| Firestore 실시간 스트림 | `StreamProvider<T>` | 데이터 실시간 동기화 |
| 사용자 인터랙션 상태 (선택된 날짜, 뷰 타입 등) | `StateProvider<T>` | 단순 상태 |
| 복합 비즈니스 로직 상태 | `AsyncNotifierProvider<T>` | CRUD + 비동기 로직 |
| 파생 데이터 (통계, 필터 결과) | `Provider<T>` (watch 조합) | 다른 provider 조합 |

### 6.3 핵심 Provider 명세

```dart
// --- C0 Global Providers ---

// Firebase 인스턴스 (앱 시작 시 override)
final firebaseAppProvider = Provider<FirebaseApp>((ref) => throw UnimplementedError());

// Firestore 인스턴스
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instanceFor(app: ref.watch(firebaseAppProvider));
});

// 인증 상태 스트림
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 현재 사용자 ID (null이면 미인증)
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

// --- Feature Providers (예: Todo) ---

// 선택된 날짜
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 투두 실시간 스트림
final todoStreamProvider = StreamProvider.family<List<Todo>, DateTime>((ref, date) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref.watch(todoRepositoryProvider).watchByDate(userId, date);
});

// 투두 통계 (파생 데이터)
final todoStatsProvider = Provider<TodoStats>((ref) {
  final todosAsync = ref.watch(todoStreamProvider(ref.watch(selectedDateProvider)));
  return todosAsync.when(
    data: (todos) => TodoStatsCalculator.calculate(todos),
    loading: () => TodoStats.empty(),
    error: (_, __) => TodoStats.empty(),
  );
});
```

### 6.4 Feature 간 데이터 공유 전략

Feature 간 직접 import를 금지하므로, 데이터 공유는 다음 두 가지 방법으로만 한다.

1. **Shared Provider 패턴**: shared/models/에 정의된 공통 모델을 통해 Riverpod provider가 중개한다. 예를 들어, F2(캘린더)가 F4(루틴)의 활성 루틴 데이터가 필요할 때, `activeRoutineStreamProvider`를 core 레벨에 두고 양쪽에서 watch한다.

2. **Orchestrator 패턴**: F1(홈 대시보드)처럼 여러 Feature의 데이터를 집계해야 하는 경우, HomeOrchestrator가 각 Feature의 Repository Provider를 watch하여 데이터를 수집한다. 이때 Repository는 shared/models/의 타입만 반환하므로 Feature 코드를 직접 참조하지 않는다.

---

## 7. 라우팅 설계 (GoRouter)

### 7.1 라우트 구조

```dart
// 라우트 경로 상수
abstract class RoutePaths {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const calendar = '/calendar';
  static const todo = '/todo';
  static const habit = '/habit';
  static const goal = '/goal';
}
```

### 7.2 GoRouter 설정

```
GoRouter 구조:
├── /splash              # 스플래시 (Firebase init + Auth 확인)
├── /login               # 로그인 (Google 로그인 버튼)
└── ShellRoute           # 하단 네비게이션 + 앱 바
    ├── /home            # F1: 홈 대시보드
    ├── /calendar        # F2: 캘린더 (뷰 전환은 내부 상태)
    ├── /todo            # F3: 투두 (서브탭 전환은 내부 상태)
    ├── /habit           # F4: 습관/루틴 (서브탭 전환은 내부 상태)
    └── /goal            # F5: 목표/만다라트 (서브탭 전환은 내부 상태)
```

### 7.3 네비게이션 설계 원칙

- **ShellRoute 사용**: 5개 탭은 ShellRoute의 자식으로 구성한다. ShellRoute의 builder에서 `Scaffold` + `BottomNavigationBar`(플로팅 캡슐)를 배치하고, body에 자식 라우트의 화면을 렌더링한다.
- **탭 전환 시 상태 보존**: GoRouter의 `StatefulShellRoute.indexedStack`을 사용하여 탭 전환 시 이전 탭의 상태(스크롤 위치, 선택된 날짜 등)를 보존한다.
- **서브탭은 라우트가 아닌 상태**: 캘린더의 월간/주간/일간, 투두의 하루일정표/할일목록, 습관의 트래커/루틴, 목표의 리스트/만다라트는 URL 경로를 바꾸지 않고 내부 StateProvider로 전환한다. 딥링크가 필요하지 않은 서브탭이므로 라우트 복잡도를 줄인다.
- **리다이렉트 가드**: `authStateProvider`를 감시하여 미인증 상태에서 /login으로, 인증 상태에서 /login 접근 시 /home으로 리다이렉트한다.

### 7.4 GoRouter 코드 골격

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == RoutePaths.login;
      final isSplash = state.matchedLocation == RoutePaths.splash;

      if (isSplash) return null; // 스플래시에서는 리다이렉트 안 함
      if (!isLoggedIn && !isLoginRoute) return RoutePaths.login;
      if (isLoggedIn && isLoginRoute) return RoutePaths.home;
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: RoutePaths.home, ...)]),
          StatefulShellBranch(routes: [GoRoute(path: RoutePaths.calendar, ...)]),
          StatefulShellBranch(routes: [GoRoute(path: RoutePaths.todo, ...)]),
          StatefulShellBranch(routes: [GoRoute(path: RoutePaths.habit, ...)]),
          StatefulShellBranch(routes: [GoRoute(path: RoutePaths.goal, ...)]),
        ],
      ),
    ],
  );
});
```

---

## 8. 메인 파이프라인 (앱 초기화 흐름)

```
[앱 시작]
    │
    ▼
[C0.1 Firebase 초기화]
    │ Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
    ▼
[C0.6 Hive 초기화]
    │ Hive.initFlutter() + Box 오픈
    ▼
[C0.3 Auth 상태 확인]
    │ FirebaseAuth.instance.authStateChanges() 구독
    ├── 미인증 → /login (Google 로그인)
    └── 인증됨 → 다음 단계
         │
         ▼
    [C0.2 Firestore 연결 + 오프라인 캐시 활성화]
         │ FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true)
         ▼
    [ProviderScope Override]
         │ firebaseAppProvider, firestoreProvider 등을 override
         ▼
    [GoRouter 초기화 → /home 진입]
         │
         ▼
    [F1 HomeOrchestrator 실행]
         │ 오늘의 투두/습관/D-day/주간요약 병렬 fetch
         ▼
    [대시보드 렌더링 완료]
```

**main.dart 골격:**

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // C0.1: Firebase 초기화
  final firebaseApp = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // C0.6: Hive 초기화
  await HiveInitializer.init();

  // C0.2: Firestore 오프라인 캐시 활성화
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(
    ProviderScope(
      overrides: [
        firebaseAppProvider.overrideWithValue(firebaseApp),
      ],
      child: const DesignYourLifeApp(),
    ),
  );
}
```

---

## 9. 플랫폼별 고려사항

### 9.1 Web vs Android 차이점

| 항목 | Flutter Web | Flutter Android |
|---|---|---|
| 렌더링 | CanvasKit (WASM) | Skia (네이티브) |
| Hive 저장소 | IndexedDB | 파일 시스템 |
| Firebase Auth | 브라우저 팝업/리다이렉트 | Google Play Services |
| Firestore 캐시 | IndexedDB (기본 활성) | SQLite (기본 활성) |
| 배포 | Firebase Hosting | Google Play Store |
| 반응형 | 필수 (데스크톱 브라우저 대응) | 모바일 고정 레이아웃 |
| URL 공유 | 딥링크 필요 | 딥링크 선택 |
| 키보드 | 물리 키보드 단축키 고려 | 소프트 키보드 대응 |

### 9.2 반응형 레이아웃 전략

```dart
// 브레이크포인트 정의
abstract class Breakpoints {
  static const double mobile = 600;    // < 600: 모바일 (Android 기본)
  static const double tablet = 900;    // 600~900: 태블릿
  static const double desktop = 1200;  // > 1200: 데스크톱 (Web 기본)
}
```

- **모바일 (< 600px)**: 하단 네비게이션, 세로 스크롤, 풀 너비 카드. Android와 동일한 레이아웃.
- **태블릿 (600~900px)**: 하단 네비게이션 유지, 카드 2열 그리드, 캘린더 더 넓게.
- **데스크톱 (> 1200px)**: 사이드 네비게이션으로 전환 검토 가능. 또는 하단 네비게이션 유지하되 콘텐츠 영역 maxWidth 제한 (960px). 캘린더/만다라트는 넓은 화면 활용.

### 9.3 Web 전용 고려사항

- **초기 로딩 최적화**: CanvasKit WASM 파일이 약 2~3MB이므로 스플래시/로딩 화면 필수.
- **SEO**: Flutter Web은 SEO가 불가능하므로 랜딩 페이지가 필요하면 별도 HTML 페이지를 둔다.
- **브라우저 뒤로가기**: GoRouter가 브라우저 히스토리와 자동 연동되므로 추가 처리 불필요.
- **PWA 지원**: `manifest.json` + `service-worker.js` 설정으로 PWA 설치 가능하게 한다.

### 9.4 Android 전용 고려사항

- **Google Play 정책**: 앱 아이콘, 스플래시 스크린, 권한 선언 등.
- **백그라운드 동작**: 습관 알림을 위한 `flutter_local_notifications` + `workmanager` 패키지 검토.
- **앱 크기**: `--split-per-abi` 빌드로 APK 크기 최적화.

---

## 10. 로컬 캐시 전략 (Hive)

### 10.1 Hive Box 설계

```
Hive Boxes:
├── userProfileBox         # 사용자 프로필 캐시
├── eventsBox              # 이벤트 캐시 (key: "events_{yyyy-MM}")
├── todosBox               # 투두 캐시 (key: "todos_{yyyy-MM-dd}")
├── habitsBox              # 습관 정의 캐시
├── habitLogsBox           # 습관 로그 캐시 (key: "logs_{yyyy-MM}")
├── routinesBox            # 루틴 캐시
├── goalsBox               # 목표 캐시
├── settingsBox            # 앱 설정 (테마 모드, 언어 등)
└── syncMetaBox            # 동기화 메타데이터 (마지막 동기화 시각)
```

### 10.2 캐시 전략

**Write-Through + Read-from-Cache 패턴**을 채택한다.

```
[데이터 쓰기 흐름]
UI 액션 → Repository → Firestore 쓰기 → 성공 시 Hive 캐시 업데이트
                                       → 실패 시 (오프라인) Hive에 pending 마크 → 온라인 복구 시 동기화

[데이터 읽기 흐름]
UI 요청 → Repository → Hive 캐시 확인
                       ├── 캐시 있음 → 즉시 반환 + 백그라운드 Firestore 동기화
                       └── 캐시 없음 → Firestore 조회 → 캐시 저장 → 반환
```

### 10.3 캐시 무효화 정책

- **Firestore 실시간 리스너**: `snapshots()` 스트림을 사용하므로 서버 변경 시 자동 캐시 갱신.
- **Hive는 보조 캐시**: Firestore의 내장 오프라인 캐시(IndexedDB/SQLite)가 1차 캐시이고, Hive는 앱 시작 시 빠른 초기 렌더링을 위한 2차 캐시로 사용한다.
- **동기화 충돌**: 단일 사용자 앱이므로 다중 기기 동시 편집 시나리오는 "마지막 쓰기 승리(Last Write Wins)" 정책을 적용한다. `updatedAt` 타임스탬프 비교.

### 10.4 Firestore 내장 캐시와의 역할 분담

Firestore SDK 자체가 오프라인 캐시를 제공하는데 Hive를 추가로 사용하는 이유는 다음과 같다.

1. **앱 시작 속도**: Firestore 캐시는 SDK 초기화 후에만 접근 가능하지만, Hive는 Firebase 초기화 전에도 읽을 수 있어 스플래시 → 대시보드 전환이 빠르다.
2. **사용자 설정 저장**: 테마 모드, 마지막 선택 탭 등 Firebase에 저장할 필요 없는 로컬 설정.
3. **집계 데이터 캐싱**: 주간 요약, 스트릭 등 계산 비용이 높은 파생 데이터를 캐싱한다.

**트레이드오프**: Hive 추가로 인해 캐시 일관성 관리 부담이 생기지만, 사용자 경험(빠른 초기 로딩)이 더 중요하다고 판단한다. 단, Hive를 "진실의 원천(source of truth)"으로 사용하지 않고 Firestore를 항상 정본으로 삼는다.

---

## 11. 의존성 매트릭스

```
         C0  shared  F1   F2   F3   F4   F5
C0        -    X     X    X    X    X    X     (어느 Feature도 참조하지 않음)
shared   OK    -     X    X    X    X    X     (core만 참조)
F1       OK   OK     -    X    X    X    X     (provider를 통해 F2~F5 데이터 집계)
F2       OK   OK     X    -    X   OK*   X     (* 루틴 오버레이: provider 경유)
F3       OK   OK     X    X    -    X    X
F4       OK   OK     X    X    X    -    X
F5       OK   OK     X    X    X    X    -

OK = 참조함, X = 참조 금지, OK* = provider를 통한 간접 참조
```

**순환 의존 없음 확인**: 모든 화살표가 core/shared 방향(상위)으로만 향한다. F2 -> F4 간접 참조는 shared/models/Routine 타입과 core 레벨 routineStreamProvider를 통하므로 Feature 코드 직접 import가 아니다.

---

## 12. 기술적 트레이드오프 및 의사결정 기록

### 12.1 Firestore vs Supabase (PostgreSQL)

- **선택: Firestore**
- 근거: 실시간 동기화 내장, 오프라인 캐시 내장, Firebase Auth/Hosting과 자연스러운 통합, 개인용 앱의 쿼리 패턴(단일 사용자 문서 CRUD)에 적합.
- 트레이드오프: 복잡한 JOIN/집계 쿼리 불가. 만다라트 진행률처럼 다단계 집계는 클라이언트에서 계산해야 한다. 하지만 개인용 앱이므로 데이터량이 적어 클라이언트 계산으로 충분하다.

### 12.2 tasks 서브컬렉션 위치

- **선택: goals/{goalId}/tasks/ (goal 바로 아래)**
- 대안: goals/{goalId}/subGoals/{subGoalId}/tasks/ (3단 중첩)
- 근거: 3단 중첩 시 특정 goal의 전체 tasks 조회가 불가능(컬렉션 그룹 쿼리 필요). 플랫 구조 + subGoalId 필드 필터링이 진행률 계산에 유리하다.
- 트레이드오프: subGoal 삭제 시 해당 tasks를 별도로 찾아 삭제해야 한다. batch write로 해결 가능.

### 12.3 서브탭을 라우트로 할지 상태로 할지

- **선택: 내부 StateProvider (라우트 아님)**
- 대안: /calendar/monthly, /calendar/weekly 등 개별 라우트
- 근거: 서브탭 전환 시 상태 보존이 중요하고(선택된 날짜, 스크롤 위치), 딥링크 필요성이 낮다. 라우트로 만들면 상태 보존을 위한 추가 로직이 필요하다.
- 트레이드오프: URL로 특정 뷰를 공유할 수 없다. 향후 필요 시 쿼리 파라미터(?view=weekly)로 확장 가능하다.

### 12.4 freezed 사용

- **선택: freezed + json_serializable**
- 대안: 수동 copyWith + fromJson
- 근거: 불변 객체 보장, copyWith 자동 생성, union 타입 지원, JSON 직렬화 자동 생성. 코드 생성 빌드 시간이 추가되지만, 런타임 안정성과 개발 생산성이 압도적으로 우수하다.
- 트레이드오프: `build_runner` 의존, 생성 파일 관리 필요. `.g.dart`와 `.freezed.dart` 파일이 생성된다.

---

## 13. spec-product, spec-security에 대한 의견

### spec-product에게

- **투두-목표 연동**: Todo 모델에 `linkedGoalId` 필드를 두어 특정 투두를 목표의 실천 할일과 연결할 수 있게 설계함. 이 연동이 사용자 관점에서 필수인지, 아니면 Phase 2 이후 추가 기능인지 확인 요청한다.
- **습관 프리셋**: 인기 습관 프리셋 데이터를 Firestore에 공용 컬렉션으로 둘지, 클라이언트에 하드코딩할지 결정이 필요하다. 개인용 앱이므로 클라이언트 하드코딩을 권장하지만, 프리셋 업데이트 가능성이 있다면 Firestore 공용 컬렉션이 적합하다.
- **만다라트 입력 위저드**: 3단계 위저드(핵심목표 -> 세부목표 -> 실천과제)가 UX 측면에서 적절한지, 혹시 한 화면에서 직접 그리드를 채우는 것이 더 나은지 의견을 구한다.
- **온보딩 플로우**: 최초 로그인 시 이름 입력 -> 바로 시작으로 충분한지, 또는 관심 습관 선택/목표 설정 등 추가 온보딩 스텝이 필요한지 확인한다.

### spec-security에게

- **Firestore 보안 규칙**: 현재 `request.auth.uid == userId` 단일 조건만 설정함. 필드 레벨 검증(예: colorIndex가 0~7 범위인지, title 길이 제한 등)을 보안 규칙에 추가할 것을 권장한다. Firestore 보안 규칙에서의 데이터 검증 범위를 정의해 달라.
- **Google OAuth 토큰 관리**: Firebase Auth가 토큰 갱신을 자동 처리하지만, 웹 환경에서 토큰 저장 위치(localStorage vs sessionStorage vs httpOnly cookie)에 대한 보안 검토를 요청한다. Firebase SDK가 기본적으로 IndexedDB를 사용하는데 이 기본 설정이 충분한지 의견을 구한다.
- **오프라인 캐시 보안**: Hive에 저장되는 사용자 데이터의 암호화 필요 여부를 검토해 달라. 개인 기기에서만 사용하므로 암호화 없이도 충분하다고 판단하지만, 보안 관점의 의견이 필요하다.
- **CORS/CSP**: Firebase Hosting에서 제공하는 기본 보안 헤더 외에 추가로 설정해야 할 Content-Security-Policy가 있는지 확인한다.
- **Rate Limiting**: Firestore 보안 규칙만으로는 Rate Limiting이 불가능하다. 개인용 앱이므로 별도 Cloud Functions 기반 Rate Limiting이 필요하지 않다고 판단하지만, 확인을 구한다.

---

## 14. 설계 검증 체크리스트

- [x] 모든 모듈의 OUT이 정확히 1개인가? -- 각 모듈 명세에서 단일 OUT 확인 완료
- [x] 모든 IN에 파라미터명, 타입, 출처가 명시되어 있는가? -- 섹션 3에서 명시 완료
- [x] 메인 파이프라인이 분기 없는 직선인가? -- 앱 초기화 파이프라인 및 Feature 내부 파이프라인 모두 직선
- [x] 각 Feature 내부 파이프라인도 직선인가? -- F1~F5 모두 직선 파이프라인
- [x] SRP 위반 모듈이 없는가? -- 각 모듈이 단일 책임(변경 이유 1개)을 가짐
- [x] C0과 Feature가 물리적으로 분리되어 있는가? -- lib/core/ vs lib/features/
- [x] Feature 간 직접 의존이 없는가? -- provider 경유 간접 참조만 허용
- [x] 순환 의존이 없는가? -- 의존성 매트릭스(섹션 11)에서 확인 완료
- [x] 최하위 모듈이 원자적인가? -- StreakCalculator, TimeLockValidator 등 30줄 이내 순수 함수
- [x] 모듈 이름이 기능을 명확히 설명하는가? -- "Manager", "Processor" 같은 모호한 이름 없음
