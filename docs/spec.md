# Design Your Life - 기술 명세서

---

## 1. 프로젝트 개요

**앱 이름**: Design Your Life

**플랫폼**: Flutter Web + Android (단일 코드베이스)

**목적**: 투두, 캘린더, 습관 트래킹, 목표 관리를 하나의 앱에서 처리하는 개인 생산성 대시보드다. 웹에서 계획을 세우고, 앱에서 실행하는 크로스플랫폼 사용 패턴을 지원한다.

**하단 네비게이션 5탭 구조**:
```
[홈] [캘린더] [투두] [습관/루틴] [목표]
```

---

## 2. 기술 스택

| 항목 | 선택 | 버전 |
|---|---|---|
| Framework | Flutter (Web + Android) | 3.29 Stable |
| 언어 | Dart | 3.7 |
| 상태관리 | Riverpod | 2.6 |
| 라우팅 | GoRouter | 14.x |
| Backend | Firebase (서버리스) | - |
| 인증 | Firebase Auth (Google OAuth) | - |
| DB | Cloud Firestore | - |
| 로컬 캐시 | Hive | 2.2.3 |
| 캘린더 UI | table_calendar | latest |
| 차트 | fl_chart | latest |
| 날짜/i18n | intl | latest |
| 직렬화 | freezed + json_serializable | latest |
| 배포 (Web) | Firebase Hosting | - |
| 배포 (Android) | Google Play Store | - |
| 테마 | 라이트 + 다크 모드 | - |
| 렌더러 (Web) | CanvasKit (WASM) | - |

---

## 3. 아키텍처 설계

### 3.1 계층 구조

```
┌──────────────────────────────────────────┐
│           Flutter Application            │
│           (Single Codebase)              │
├──────────────────────────────────────────┤
│   Presentation Layer                     │
│   GoRouter + 5 Tab Screens + Widgets     │
│                  │ watches / reads        │
│   State Layer (Riverpod)                 │
│   Providers / Notifiers / StateModels    │
│                  │ calls                  │
│   Domain / Service Layer                 │
│   Repositories + Use Cases (Atomic)      │
│          │               │               │
│   Firestore Gateway    Hive Cache        │
└──────────┼───────────────┼───────────────┘
           │               │
    Firebase Cloud    로컬 디스크
    (Firestore/Auth)  (IndexedDB/File)
```

**계층 흐름 원칙**: UI -> State -> Service -> Data (단방향). 하위에서 상위 참조를 금지한다.

### 3.2 📁 프로젝트 폴더 구조

Feature-based 구조를 채택한다. SRP 원칙에 따라 core(C0 공통), shared(공유 타입), features(F1~F5 기능)를 물리적으로 분리한다.

```
lib/
├── main.dart                          # 앱 진입점
├── app.dart                           # MaterialApp.router 설정
│
├── core/                              # C0: 공통 인프라 모듈
│   ├── firebase/
│   │   ├── firebase_initializer.dart  # C0.1 Firebase 초기화
│   │   └── firestore_gateway.dart     # C0.2 Firestore CRUD 래퍼
│   ├── auth/
│   │   ├── auth_service.dart          # C0.3 Firebase Auth 서비스
│   │   └── auth_provider.dart         # C0.3 인증 상태 Provider
│   ├── router/
│   │   ├── app_router.dart            # C0.4 GoRouter 설정
│   │   └── route_paths.dart           # C0.4 라우트 경로 상수
│   ├── theme/
│   │   ├── app_theme.dart             # C0.5 ThemeData (라이트/다크)
│   │   ├── color_tokens.dart          # C0.5 디자인 토큰 (컬러)
│   │   ├── typography_tokens.dart     # C0.5 디자인 토큰 (타이포)
│   │   └── glassmorphism.dart         # C0.5 글래스모피즘 데코레이션
│   ├── cache/
│   │   ├── hive_initializer.dart      # C0.6 Hive 초기화 + Box 등록
│   │   └── hive_cache_service.dart    # C0.6 캐시 읽기/쓰기
│   ├── constants/
│   │   ├── app_constants.dart         # C0.7 앱 전역 상수
│   │   └── firestore_paths.dart       # C0.7 Firestore 경로 상수
│   ├── error/
│   │   ├── app_exception.dart         # C0.8 커스텀 예외 클래스
│   │   └── error_handler.dart         # C0.8 전역 에러 핸들링
│   └── utils/
│       ├── date_utils.dart            # C0.9 날짜 유틸
│       └── color_utils.dart           # C0.9 색상 유틸
│
├── shared/                            # 공유 모델 및 위젯
│   ├── models/                        # Firestore <-> Dart 모델
│   ├── enums/                         # 공유 Enum
│   ├── widgets/                       # 공용 위젯
│   └── extensions/                    # 확장 메서드
│
├── features/                          # F1~F5: 기능 모듈
│   ├── home/                          # F1: 홈 대시보드
│   ├── calendar/                      # F2: 캘린더
│   ├── todo/                          # F3: 투두
│   ├── habit/                         # F4: 습관 + 루틴
│   └── goal/                          # F5: 목표 + 만다라트
│
└── generated/                         # freezed, json_serializable 생성 파일
```

**의존 방향**: `features/` -> `shared/` -> `core/` (단방향)
- core/는 features/를 절대 import하지 않는다.
- features/ 간 직접 import를 금지한다. Riverpod provider를 통해서만 데이터를 교환한다.
- shared/는 core/만 의존할 수 있다.

### 3.3 📐 모듈 계층 설계 (C0 + F1~F5)

#### C0: 공통 인프라 모듈

| 모듈 | IN (메인) | IN (보조) | OUT |
|---|---|---|---|
| C0.1 FirebaseInitializer | 없음 (앱 시작) | firebase_options.dart | FirebaseApp |
| C0.2 FirestoreGateway | FirebaseApp | collection_path, document_id | FirestoreGateway (CRUD 래퍼) |
| C0.3 AuthService | FirebaseApp | - | AuthState (userId, displayName, isAuthenticated) |
| C0.4 AppRouter | AuthState | route_paths 상수 | GoRouter (인증 가드 포함) |
| C0.5 ThemeManager | 없음 | - | ThemeData (라이트/다크) |
| C0.6 HiveCacheManager | 없음 (앱 시작) | - | HiveCacheService |
| C0.7 AppConstants | 없음 (정적) | - | 상수 값들 |
| C0.8 ErrorHandler | Exception/Error | - | AppException |
| C0.9 DateTimeUtils | DateTime | - | 포맷 문자열/변환 DateTime |

#### F1: 홈 대시보드

```
메인 파이프라인:
[F1.1 TodayTodoAggregator] → [F1.2 TodayHabitAggregator] → [F1.3 DdayCollector] → [F1.4 WeeklySummarizer] → [F1.5 HomeOrchestrator]
```

| 모듈 | IN | OUT |
|---|---|---|
| F1.1 TodayTodoAggregator | userId, today, firestoreGateway | TodoSummary (totalCount, completedCount, completionRate, previewItems) |
| F1.2 TodayHabitAggregator | userId, today, firestoreGateway | HabitSummary (totalCount, completedCount, achievementRate, previewCards) |
| F1.3 DdayCollector | userId, today, firestoreGateway | List\<DdayItem\> (eventName, daysRemaining, urgencyLevel) |
| F1.4 WeeklySummarizer | TodoSummary + HabitSummary, weekRange | WeeklySummary (todoWeekRate, habitWeekRate, trend) |
| F1.5 HomeOrchestrator | F1.1~F1.4 전체 OUT | HomeViewState |

HomeOrchestrator는 직접 로직을 수행하지 않는다. F1.1~F1.4를 호출하고 결과를 조합만 한다.

#### F2: 캘린더

```
메인 파이프라인:
[F2.1 EventFetcher] → [F2.2 RoutineOverlayer] → [F2.3 EventMapper] → [F2.4 CalendarOrchestrator]
```

| 모듈 | IN | OUT |
|---|---|---|
| F2.1 EventFetcher | userId, dateRange, firestoreGateway | List\<Event\> |
| F2.2 RoutineOverlayer | List\<Event\>, List\<Routine\> (provider 경유) | List\<CalendarEntry\> |
| F2.3 EventMapper | List\<CalendarEntry\>, ViewType | CalendarViewData |
| F2.4 CalendarOrchestrator | CalendarViewData | CalendarViewState |

#### F3: 투두

```
메인 파이프라인:
[F3.1 TodoFetcher] → [F3.2 TodoFilter] → [F3.3 TodoStatsCalculator] → [F3.4 TodoOrchestrator]
```

| 모듈 | IN | OUT |
|---|---|---|
| F3.1 TodoFetcher | userId, targetDate, firestoreGateway | List\<Todo\> |
| F3.2 TodoFilter | List\<Todo\>, filterType | List\<Todo\> (필터링 결과) |
| F3.3 TodoStatsCalculator | List\<Todo\> (원본) | TodoStats (completionRate, 유형별 카운트) |
| F3.4 TodoOrchestrator | F3.1~F3.3 OUT | TodoViewState |

#### F4: 습관 + 루틴

```
메인 파이프라인 (습관):
[F4.1 HabitFetcher] → [F4.2 HabitLogFetcher] → [F4.3 StreakCalculator] → [F4.4 TimeLockValidator] → [F4.5 HabitOrchestrator]

메인 파이프라인 (루틴):
[F4.6 RoutineFetcher] → [F4.7 RoutineScheduler] → [F4.8 RoutineOrchestrator]
```

| 모듈 | IN | OUT |
|---|---|---|
| F4.1 HabitFetcher | userId, firestoreGateway | List\<Habit\> |
| F4.2 HabitLogFetcher | userId, targetDate, firestoreGateway | List\<HabitLog\> |
| F4.3 StreakCalculator | habitId, allLogs, today | StreakResult (currentStreak, longestStreak) |
| F4.4 TimeLockValidator | targetDate, now | TimeLockResult (isEditable, reason) |
| F4.5 HabitOrchestrator | F4.1~F4.4 OUT | HabitViewState |
| F4.6 RoutineFetcher | userId, firestoreGateway | List\<Routine\> |
| F4.7 RoutineScheduler | List\<Routine\>, targetWeek | Map\<DayOfWeek, List\<ScheduledRoutine\>\> |
| F4.8 RoutineOrchestrator | F4.6~F4.7 OUT | RoutineViewState |

#### F5: 목표 + 만다라트

```
메인 파이프라인:
[F5.1 GoalFetcher] → [F5.2 SubGoalFetcher] → [F5.3 TaskFetcher] → [F5.4 ProgressCalculator] → [F5.5 MandalartMapper] → [F5.6 GoalOrchestrator]
```

| 모듈 | IN | OUT |
|---|---|---|
| F5.1 GoalFetcher | userId, period, firestoreGateway | List\<Goal\> |
| F5.2 SubGoalFetcher | goalId, firestoreGateway | List\<SubGoal\> |
| F5.3 TaskFetcher | subGoalId, firestoreGateway | List\<GoalTask\> |
| F5.4 ProgressCalculator | List\<Goal\> + List\<SubGoal\> + List\<GoalTask\> | GoalProgress (achievementRate, avgProgress) |
| F5.5 MandalartMapper | Goal + List\<SubGoal\>(8) + List\<List\<GoalTask\>\>(각8) | MandalartGrid (9x9) |
| F5.6 GoalOrchestrator | F5.1~F5.5 OUT | GoalViewState |

### 3.4 상태 관리 (Riverpod)

#### Provider 계층

```
Global Providers (core/)
  firebaseAppProvider, firestoreProvider,
  authStateProvider, currentUserIdProvider,
  themeProvider, hiveCacheProvider
          │ (DI 주입)
Repository Providers (per feature)
  eventRepositoryProvider, todoRepositoryProvider,
  habitRepositoryProvider, routineRepositoryProvider,
  goalRepositoryProvider
          │
Feature State Providers
  homeViewStateProvider, calendarViewStateProvider,
  todoViewStateProvider, habitViewStateProvider,
  routineViewStateProvider, goalViewStateProvider,
  mandalartViewStateProvider
```

#### Provider 타입 기준

| 용도 | Provider 타입 |
|---|---|
| 인프라 싱글톤 (Firebase, Auth) | `Provider<T>` |
| Firestore 실시간 스트림 | `StreamProvider<T>` |
| 단순 UI 상태 (선택된 날짜, 뷰 타입) | `StateProvider<T>` |
| 비동기 비즈니스 로직 (CRUD) | `AsyncNotifierProvider<T>` |
| 파생 데이터 (통계, 필터 결과) | `Provider<T>` (watch 조합) |

#### Feature 간 데이터 공유

Feature 간 직접 import를 금지하므로 두 가지 방법만 사용한다.

1. **Shared Provider 패턴**: shared/models/ 공통 모델을 통해 Riverpod provider가 중개한다. 예: F2(캘린더)가 F4(루틴) 데이터가 필요하면 `activeRoutineStreamProvider`를 core 레벨에 둔다.
2. **Orchestrator 패턴**: F1(홈)처럼 여러 Feature 데이터를 집계할 때, HomeOrchestrator가 각 Repository Provider를 watch하여 수집한다.

### 3.5 라우팅 (GoRouter)

```
GoRouter 구조:
├── /splash              # 스플래시 (Firebase init + Auth 확인)
├── /login               # 로그인 (Google 로그인)
└── StatefulShellRoute    # 하단 네비게이션 + IndexedStack
    ├── /home             # F1: 홈 대시보드
    ├── /calendar         # F2: 캘린더
    ├── /todo             # F3: 투두
    ├── /habit            # F4: 습관/루틴
    └── /goal             # F5: 목표/만다라트
```

**설계 원칙**:
- `StatefulShellRoute.indexedStack`으로 탭 전환 시 상태(스크롤 위치, 선택 날짜)를 보존한다.
- 서브탭(월간/주간/일간, 습관/루틴 등)은 라우트가 아닌 내부 StateProvider로 전환한다. 딥링크 필요성이 낮고 상태 보존이 중요하기 때문이다.
- `authStateProvider`를 감시하여 미인증 시 /login, 인증 상태에서 /login 접근 시 /home으로 리다이렉트한다.
- GoRouter redirect는 클라이언트 측 가드일 뿐이다. 데이터 보호는 반드시 Firestore Rules에 의존해야 한다.

### 3.6 로컬 캐시 전략 (Hive)

#### Hive Box 구성

```
userProfileBox       # 사용자 프로필 캐시
eventsBox            # 이벤트 캐시 (key: "events_{yyyy-MM}")
todosBox             # 투두 캐시 (key: "todos_{yyyy-MM-dd}")
habitsBox            # 습관 정의 캐시
habitLogsBox         # 습관 로그 캐시 (key: "logs_{yyyy-MM}")
routinesBox          # 루틴 캐시
goalsBox             # 목표 캐시
settingsBox          # 앱 설정 (테마, 언어)
syncMetaBox          # 동기화 메타데이터 (마지막 동기화 시각)
```

#### 캐시 전략: Write-Through + Read-from-Cache

```
[쓰기 흐름]
UI 액션 → Repository → Firestore 쓰기
  → 성공 시: Hive 캐시 업데이트
  → 실패 시 (오프라인): Hive에 pending 마크 → 온라인 복구 시 동기화

[읽기 흐름]
UI 요청 → Repository → Hive 캐시 확인
  → 캐시 있음: 즉시 반환 + 백그라운드 Firestore 동기화
  → 캐시 없음: Firestore 조회 → 캐시 저장 → 반환
```

Firestore가 정본(source of truth)이다. Hive는 보조 캐시로만 사용한다. Firestore 내장 오프라인 캐시(IndexedDB/SQLite)가 1차, Hive는 앱 시작 시 빠른 초기 렌더링을 위한 2차 캐시다.

**Hive를 추가 사용하는 이유**:
- Firebase 초기화 전에도 Hive 데이터를 읽을 수 있어 스플래시 → 대시보드 전환이 빠르다.
- 테마 모드, 마지막 선택 탭 등 로컬 전용 설정을 저장한다.
- 주간 요약, 스트릭 등 계산 비용이 높은 파생 데이터를 캐싱한다.

### 3.7 앱 초기화 파이프라인

```
[앱 시작]
    │
    ▼
[C0.1 Firebase 초기화] Firebase.initializeApp()
    │
    ▼
[C0.6 Hive 초기화] Hive.initFlutter() + Box 오픈
    │
    ▼
[C0.3 Auth 상태 확인] authStateChanges() 구독
    ├── 미인증 → /login (Google 로그인)
    └── 인증됨
         │
         ▼
    [C0.2 Firestore 오프라인 캐시 활성화]
         │
         ▼
    [ProviderScope Override]
         │
         ▼
    [GoRouter → /home]
         │
         ▼
    [F1 HomeOrchestrator 실행] 투두/습관/D-day/주간요약 병렬 fetch
         │
         ▼
    [대시보드 렌더링 완료]
```

### 3.8 의존성 매트릭스

```
         C0  shared  F1   F2   F3   F4   F5
C0        -    X     X    X    X    X    X
shared   OK    -     X    X    X    X    X
F1       OK   OK     -    X    X    X    X
F2       OK   OK     X    -    X   OK*   X
F3       OK   OK     X    X    -    X    X
F4       OK   OK     X    X    X    -    X
F5       OK   OK     X    X    X    X    -

OK = 참조, X = 참조 금지, OK* = provider 경유 간접 참조
```

순환 의존 없음. 모든 참조가 core/shared 방향(상위)으로만 향한다.

---

## 4. 공유 타입 정의

모든 모델은 `freezed` + `json_serializable`로 불변 객체를 생성한다. `fromJson`/`toJson` 팩토리를 포함한다.

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
    @Default(1) int schemaVersion,      // 데이터 마이그레이션용
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;
}
```

### 4.2 Event (캘린더 일정)

```dart
@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    required String userId,
    required String title,              // 최대 200자
    required EventType type,            // 일반, 범위, 반복, 할일
    required DateTime startDate,
    DateTime? endDate,                  // 범위 일정용
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    required int colorIndex,            // 0~7 (8가지 색상)
    String? location,                   // 최대 200자
    String? memo,                       // 최대 2000자
    RepeatCycle? repeatCycle,           // 반복 일정용
    List<int>? repeatDays,              // 반복 요일 (1=월 ~ 7=일)
    String? rangeTag,                   // 범위 태그 (여행/시험/휴가/프로젝트/기타)
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Event;
}
```

### 4.3 Todo

```dart
@freezed
class Todo with _$Todo {
  const factory Todo({
    required String id,
    required String userId,
    required String title,              // 최대 200자
    required DateTime date,
    TimeOfDay? time,
    @Default(false) bool isCompleted,
    required int colorIndex,            // 0~7
    String? memo,                       // 최대 2000자
    String? linkedGoalId,               // 목표 연동 (선택)
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Todo;
}
```

### 4.4 Habit

```dart
@freezed
class Habit with _$Habit {
  const factory Habit({
    required String id,
    required String userId,
    required String name,               // 최대 100자
    String? icon,                       // 이모지 아이콘
    required int colorIndex,            // 0~7
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _Habit;
}
```

### 4.5 HabitLog

```dart
@freezed
class HabitLog with _$HabitLog {
  const factory HabitLog({
    required String id,                 // 권장 ID 형식: {habitId}_{yyyy-MM-dd}
    required String habitId,
    required String userId,
    required DateTime date,             // 날짜만 (yyyy-MM-dd 기준)
    @Default(false) bool isCompleted,
    required DateTime checkedAt,        // 실제 체크한 시각
  }) = _HabitLog;
}
```

`id`를 `{habitId}_{date}` 형식으로 구성하여 동일 날짜에 중복 문서 생성을 방지한다.

### 4.6 Routine

```dart
@freezed
class Routine with _$Routine {
  const factory Routine({
    required String id,
    required String userId,
    required String name,               // 최대 200자
    required List<int> repeatDays,      // 반복 요일 (1=월 ~ 7=일)
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int colorIndex,            // 0~7
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Routine;
}
```

### 4.7 Goal

```dart
@freezed
class Goal with _$Goal {
  const factory Goal({
    required String id,
    required String userId,
    required String title,              // 최대 200자
    String? description,                // 최대 1000자
    required GoalPeriod period,         // 년간 / 월간
    required int year,
    int? month,                         // 월간 목표일 때만
    @Default(false) bool isCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Goal;
}
```

### 4.8 SubGoal

```dart
@freezed
class SubGoal with _$SubGoal {
  const factory SubGoal({
    required String id,
    required String goalId,
    required String title,              // 최대 200자
    @Default(false) bool isCompleted,
    required int orderIndex,            // 만다라트 위치 (0~7)
    required DateTime createdAt,
  }) = _SubGoal;
}
```

### 4.9 GoalTask (실천 할일)

```dart
@freezed
class GoalTask with _$GoalTask {
  const factory GoalTask({
    required String id,
    required String subGoalId,
    required String title,              // 최대 200자
    @Default(false) bool isCompleted,
    required int orderIndex,            // 만다라트 위치 (0~7)
    required DateTime createdAt,
  }) = _GoalTask;
}
```

### 4.10 MandalartGrid (뷰 전용, Firestore 미저장)

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

## 5. 🗄️ Firestore 스키마

### 5.1 컬렉션 구조

```
firestore-root/
└── users/                              # 컬렉션
    └── {userId}/                       # 문서 (UserProfile 필드)
        ├── events/                     # 서브컬렉션
        │   └── {eventId}/
        ├── todos/                      # 서브컬렉션
        │   └── {todoId}/
        ├── habits/                     # 서브컬렉션
        │   └── {habitId}/
        ├── habitLogs/                  # 서브컬렉션
        │   └── {logId}/               # ID: {habitId}_{yyyy-MM-dd}
        ├── routines/                   # 서브컬렉션
        │   └── {routineId}/
        └── goals/                      # 서브컬렉션
            └── {goalId}/
                ├── subGoals/           # 서브컬렉션
                │   └── {subGoalId}/
                └── tasks/              # goal 아래 플랫 배치
                    └── {taskId}/       # subGoalId 필드로 필터링
```

**tasks를 goal 아래에 플랫하게 배치하는 이유**: 3단 중첩(goals -> subGoals -> tasks)은 특정 goal의 전체 tasks 조회 시 컬렉션 그룹 쿼리가 필요하다. 플랫 구조 + `subGoalId` 필드 필터링이 진행률 계산에 효율적이다.

### 5.2 필수 복합 인덱스

| 컬렉션 | 인덱스 필드 | 용도 |
|---|---|---|
| events | userId(ASC) + startDate(ASC) | 날짜 범위 쿼리 |
| events | userId(ASC) + type(ASC) + startDate(ASC) | 유형별 필터링 |
| todos | userId(ASC) + date(ASC) | 날짜별 투두 조회 |
| todos | userId(ASC) + date(ASC) + isCompleted(ASC) | 완료 상태 필터링 |
| habitLogs | userId(ASC) + habitId(ASC) + date(DESC) | 스트릭 계산용 |
| habitLogs | userId(ASC) + date(ASC) | 날짜별 전체 로그 |
| goals | userId(ASC) + period(ASC) + year(ASC) | 기간별 목표 조회 |
| tasks (goal 하위) | subGoalId(ASC) + orderIndex(ASC) | 서브목표별 할일 정렬 |

### 5.3 🔐 Firestore 보안 규칙

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 기본 정책: 전부 거부 (화이트리스트 방식)
    match /{document=**} {
      allow read, write: if false;
    }

    // 사용자 데이터: 본인만 접근 가능
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

컬렉션별 세부 규칙(필드 검증, 길이 제한, enum 검증)은 구현 단계에서 추가한다. 기본 원칙:
- `request.resource.data.title.size() <= 200` 등 길이 제한
- `request.resource.data.type in ['normal', 'range', 'recurring', 'todo']` 등 enum 검증
- 필수 필드 존재 여부: `request.resource.data.keys().hasAll([...])`
- 타입 검사: `is string`, `is bool`, `is number`, `is timestamp`

### 5.4 페이지네이션 필수 적용 대상

- `events`: 월별로 쿼리 범위를 제한한다. 전체 기간 조회를 금지한다.
- `habitLogs`: 월별 페이지네이션을 적용한다.
- `todos`: 일 단위 또는 주 단위로 쿼리한다.

---

## 6. 사용자 시나리오

### 6.1 플랫폼별 사용 맥락

| 구분 | 웹 (Flutter Web) | 앱 (Android) |
|---|---|---|
| 주요 맥락 | 데스크톱에서 집중 계획 수립 | 이동 중 빠른 체크/기록 |
| 세션 평균 시간 | 5~15분 | 30초~3분 |
| 핵심 행동 | 목표 설정, 만다라트 작성, 루틴 편집, 통계 리뷰 | 습관 체크, 투두 완료, 일정 확인 |
| 입력 방식 | 키보드 + 마우스 | 터치 (탭 위주) |

### 6.2 시나리오 A: 최초 진입 (온보딩)

1. Google 로그인 버튼 탭 -> OAuth 동의
2. 개인정보 처리 동의 화면 (필수, 생략 불가)
3. 이름 입력 화면 ("어떻게 불러드릴까요?", 1~20자)
4. 홈 대시보드 진입 -> 빈 상태 카드들이 행동 유도 메시지와 함께 표시

로그인부터 첫 화면까지 최소 탭으로 완료한다. 별도 튜토리얼 없이 빈 상태 UI가 가이드 역할을 한다.

### 6.3 시나리오 B: 일상 사용

**아침 (앱)**: 홈 열기 -> 인사 메시지 확인 -> 투두 완료율 0% 확인 -> D-day 카드 확인 -> 투두 탭에서 체크 시작

**퇴근 후 (앱)**: 투두 완료율 65% 확인 -> 습관 탭에서 "운동 30분", "물 2L" 체크 -> 스트릭 증가 확인

**주말 (웹)**: 캘린더 주간 뷰로 다음 주 일정 확인/추가 -> 목표 진행률 리뷰 -> 루틴 시간표 조정

### 6.4 시나리오 C: 캘린더 일정 생성 (4유형)

1. **일반 일정**: 날짜 탭 -> "+" -> 제목, 시간, 색상, 위치, 메모 입력 -> 저장
2. **범위 일정**: 제목 + 태그(여행/시험/휴가/프로젝트/기타) + 시작~종료일 + 색상 -> 캘린더에서 범위 연결 표시
3. **반복 일정**: 이름 + 반복 요일(복수 선택) + 시작/종료 시간 + 색상 -> 선택 요일마다 자동 반영
4. **할일 일정**: 제목 + 시간 지정 토글 + 색상 + 메모 -> 시간 지정 시 타임라인, 미지정 시 목록에만 표시

### 6.5 시나리오 D: 습관 트래킹

- 첫 진입 시 "인기 습관으로 시작하기" 카드 표시 -> 프리셋 선택 -> 즉시 등록
- 체크 시 스트릭 +1, 도넛차트 실시간 갱신
- **시간 잠금**: 오늘(00:00~23:59)만 체크/해제 가능. 자정 이후 어제 습관은 잠금. 미체크 시 스트릭 0 리셋.

### 6.6 시나리오 E: 만다라트 생성

3단계 위저드로 진입장벽을 낮춘다.
1. **1단계**: 핵심 목표 1개 입력
2. **2단계**: 세부목표 8개 입력 (건너뛰기 가능)
3. **3단계**: 실천과제 입력 (세부목표별 펼침)
- 부분 저장 허용. 빈 칸은 "탭하여 추가" 상태로 유지.
- 목표 리스트와 만다라트는 동일 데이터를 다른 시각으로 표현한다.

---

## 7. 📋 수락 기준 (Acceptance Criteria)

### 7.1 온보딩 (AC-ON)

| ID | 기준 |
|---|---|
| AC-ON-01 | 비로그인 사용자가 앱 진입 시 Google 로그인 버튼만 표시된다 |
| AC-ON-02 | Google 로그인 성공 시 개인정보 처리 동의 화면으로 이동한다 |
| AC-ON-03 | 동의 후 이름 입력 화면으로 이동한다 |
| AC-ON-04 | 이름은 1~20자 사이, 빈 값 불가 |
| AC-ON-05 | 이름 입력 후 "시작하기" 탭 시 홈 대시보드로 이동한다 |
| AC-ON-06 | 재방문 사용자는 로그인 없이 홈으로 직행한다 |
| AC-ON-07 | 웹과 앱에서 동일 Google 계정 로그인 시 데이터가 동기화된다 |

### 7.2 홈 대시보드 (AC-HM)

| ID | 기준 |
|---|---|
| AC-HM-01 | 인사 메시지에 사용자 이름이 표시된다 |
| AC-HM-02 | 오늘의 투두 완료율이 도넛차트로 정확히 표시된다 |
| AC-HM-03 | 오늘의 습관 달성률이 도넛차트로 정확히 표시된다 |
| AC-HM-04 | D-day 카드는 가장 가까운 일정부터 정렬된다 |
| AC-HM-05 | D-3 이하 일정은 빨간색 강조 표시된다 |
| AC-HM-06 | 이번주 요약은 월~일 기준으로 자동 집계된다 |
| AC-HM-07 | 모든 섹션 비어있을 때 빈 상태 UI가 표시된다 |

### 7.3 캘린더 (AC-CL)

| ID | 기준 |
|---|---|
| AC-CL-01 | 월간/주간/일간 3가지 뷰를 상단 탭으로 전환 가능하다 |
| AC-CL-02 | 월간 뷰에서 일정 있는 날짜에 dot이 표시된다 |
| AC-CL-03 | 일간 뷰에서 현재 시간 위치에 빨간색 가로선이 표시된다 |
| AC-CL-04 | 일정 유형 4가지 각각 CRUD가 가능하다 |
| AC-CL-05 | 범위 일정은 시작~종료일이 캘린더에서 연결 표시된다 |
| AC-CL-06 | 반복 일정은 선택 요일마다 자동 표시된다 |
| AC-CL-07 | 활성 루틴이 주간/일간 타임라인에 반영된다 |
| AC-CL-08 | 모든 일정에 D-day 카운트가 자동 표시된다 |
| AC-CL-09 | 8가지 색상 선택 후 해당 색으로 표시된다 |

### 7.4 투두 (AC-TD)

| ID | 기준 |
|---|---|
| AC-TD-01 | 주간 슬라이더에서 좌우 스와이프로 날짜 변경 가능하다 |
| AC-TD-02 | "하루 일정표"/"할 일 목록" 서브탭 전환이 가능하다 |
| AC-TD-03 | 하루 일정표 좌측에 완료율 도넛차트가 표시된다 |
| AC-TD-04 | 하루 일정표 우측에 시간별 타임라인이 표시된다 |
| AC-TD-05 | 체크박스 탭 시 완료 상태로 전환된다 |
| AC-TD-06 | 제목 필수, 시간/색상/메모는 선택이다 |
| AC-TD-07 | 할 일 없는 날짜는 빈 상태 UI가 표시된다 |

### 7.5 습관/루틴 (AC-HB)

| ID | 기준 |
|---|---|
| AC-HB-01 | 습관 체크는 오늘(00:00~23:59)만 가능하다 |
| AC-HB-02 | 스트릭 카운터가 연속 체크 일수를 정확히 표시한다 |
| AC-HB-03 | 하루 빠지면 스트릭이 0으로 리셋된다 |
| AC-HB-04 | 습관 캘린더 각 날짜에 미니 도넛차트와 % 숫자가 표시된다 |
| AC-HB-05 | 프리셋 선택 시 즉시 습관이 등록된다 |
| AC-HB-06 | 루틴 활성/비활성 토글이 즉시 캘린더에 반영된다 |
| AC-HB-07 | 과거 날짜의 습관 캘린더는 읽기 전용이다 |

### 7.6 목표/만다라트 (AC-GL)

| ID | 기준 |
|---|---|
| AC-GL-01 | 년간/월간 탭 전환이 가능하다 |
| AC-GL-02 | 하위 할일 완료 시 목표 진행률이 자동 재계산된다 |
| AC-GL-03 | 상단 통계(달성률/평균 진행률/총 목표 수)가 정확하다 |
| AC-GL-04 | 만다라트 위저드가 3단계로 분리 동작한다 |
| AC-GL-05 | 만다라트의 빈 칸은 "탭하여 추가" 상태로 유지된다 |
| AC-GL-06 | 만다라트와 목표 리스트는 동일 데이터를 공유한다 |
| AC-GL-07 | 목표 카드의 완료 체크가 달성률에 반영된다 |

### 7.7 크로스 플랫폼 (AC-XP)

| ID | 기준 |
|---|---|
| AC-XP-01 | 웹에서 추가한 데이터가 앱에서 실시간 표시된다 |
| AC-XP-02 | 오프라인 상태에서 읽기가 가능하다 (캐시 기반) |
| AC-XP-03 | 오프라인 상태에서 쓰기 시 온라인 복구 후 자동 동기화된다 |
| AC-XP-04 | 로그아웃 시 로컬 캐시가 완전 삭제된다 |

---

## 8. MVP 범위

### 8.1 v1.0 (MVP) - 반드시 포함

**핵심 원칙**: "매일 열어서 쓸 수 있는 최소한의 완전한 경험"

| 기능 | 우선순위 |
|---|---|
| Google 로그인 + 개인정보 동의 + 이름 설정 | P0 |
| 홈 대시보드 (투두 완료율, 습관 달성률, D-day) | P0 |
| 캘린더 - 월간 뷰 + 일간 뷰 | P0 |
| 캘린더 - 일반 일정 CRUD | P0 |
| 캘린더 - 범위 일정 CRUD | P0 |
| 투두 - 할 일 목록 (체크리스트) | P0 |
| 투두 - 하루 일정표 (타임라인) | P0 |
| 습관 트래커 - 오늘의 습관 (체크 + 스트릭) | P0 |
| 습관 - 시간 잠금 (자정 기준) | P0 |
| 습관 - 인기 프리셋 5개 | P0 |
| 목표 리스트 - 년간/월간 + 진행률 | P0 |
| 빈 상태 UI (전체 탭) | P0 |
| 라이트 모드 | P0 |
| 8가지 색상 팔레트 | P0 |
| Firestore 실시간 동기화 | P0 |
| Firestore 보안 규칙 (기본 거부 + userId 검증) | P0 |
| 주간 날짜 슬라이더 (투두) | P1 |
| 년/월 피커 (투두, 캘린더) | P1 |
| 습관 캘린더 (월간 미니 도넛) | P1 |

### 8.2 v1.1 - 빠른 후속 업데이트

| 기능 | 우선순위 |
|---|---|
| 캘린더 - 주간 뷰 | P1 |
| 캘린더 - 반복 일정 | P1 |
| 루틴 (주간 시간표) | P1 |
| 루틴-캘린더 연동 | P1 |
| 다크 모드 | P1 |
| 목표 템플릿 (토익/자격증 등) | P1 |
| 이번주 요약 (홈) | P1 |

### 8.3 v2.0 - 차기 메이저 업데이트

| 기능 | 우선순위 |
|---|---|
| 만다라트 뷰 + 위저드 | P2 |
| 캘린더 - 할일 유형 (캘린더 내) | P2 |
| 푸시 알림 (습관/일정) | P2 |
| 위젯 (Android) | P2 |
| 통계/리포트 화면 | P2 |
| 데이터 내보내기 (CSV/PDF) | P3 |
| 다국어 지원 | P3 |

### 8.4 MVP 판단 기준

1. **일일 사용 루프 완성**: 열기 -> 체크 -> 확인 루프가 끊김 없이 동작하는가
2. **탭 간 연결 성립**: 5개 탭 모두 최소 1개 핵심 기능이 동작하는가
3. **데이터 흐름 완결**: 입력 -> 저장 -> 표시 -> 수정 -> 삭제가 모든 데이터에서 동작하는가
4. **과도한 복잡성 배제**: 구현 복잡도 대비 사용자 가치가 낮은 기능은 후속 버전으로 미루는가

---

## 9. 진입장벽 완화 전략

### 9.1 습관: 인기 프리셋

| 프리셋 | 아이콘 | 설명 |
|---|---|---|
| 운동 30분 | 운동 아이콘 | 매일 30분 이상 운동하기 |
| 독서 | 책 아이콘 | 매일 독서하기 |
| 물 2L | 물방울 아이콘 | 하루 물 2리터 마시기 |
| 영어 공부 | 말풍선 아이콘 | 매일 영어 학습하기 |
| 일기 쓰기 | 펜 아이콘 | 매일 일기 쓰기 |

프리셋은 앱 번들에 정적으로 포함한다. 서버에 저장하면 인증 전 접근 가능한 공개 컬렉션이 필요해져 보안 규칙이 복잡해진다. 프리셋 선택 시 추가 입력 없이 즉시 등록된다.

### 9.2 루틴: 빈 상태 가이드

- 중앙에 시간표 아이콘 배치
- "아직 등록된 루틴이 없어요" + "반복되는 일정을 루틴으로 등록하면, 캘린더에 자동으로 표시돼요!"
- "첫 루틴 만들기" CTA 버튼
- 입력 필드에 placeholder로 "예: 영어 수업" 제공

### 9.3 목표: 템플릿 (v1.1)

| 템플릿 | 하위목표 예시 | 타겟 |
|---|---|---|
| 토익 800+ | LC 파트 집중, RC 문법 정리, 모의고사 | 취업 준비생 |
| 정보처리기사 | 필기 이론, 기출 풀이, 실기 연습 | IT 취준생/직장인 |
| 다이어트 -5kg | 식단 관리, 운동 루틴, 체중 기록 | 건강 관심층 |
| 영어 회화 | 매일 회화 연습, 영어 일기, 원서 읽기 | 자기계발층 |

### 9.4 만다라트: 개념 설명 + 위저드 (v2.0)

- "만다라트란?" 툴팁으로 개념을 설명한다
- 3단계 위저드로 단계별 입력한다 (한 번에 9x9를 보여주지 않는다)
- 부분 저장을 허용하여 모든 칸을 채우지 않아도 저장 가능하다

### 9.5 홈: 최소 온보딩

별도 튜토리얼 화면을 만들지 않는다. Google 로그인 -> 개인정보 동의 -> 이름 입력 -> 홈 진입. 빈 상태 UI가 곧 가이드다.

---

## 10. 🔐 보안 요구사항

### 10.1 Firestore 보안 규칙

**기본 원칙**: 전부 거부(기본 정책) + 화이트리스트 방식으로 허용한다.

| 항목 | 위험 등급 | 요구사항 |
|---|---|---|
| 기본 거부 정책 | 🔴 Critical | 최상위에 `allow read, write: if false;` 선언 |
| userId 일치 검증 | 🔴 Critical | `request.auth.uid == userId` 모든 하위 컬렉션에 일관 적용 |
| 와일드카드 매칭 범위 | 🔴 Critical | `{document=**}` 재귀 매칭 범위를 정확히 검증 |
| 필드 레벨 검증 | 🟡 High | 문서 생성/수정 시 필수 필드 존재, 타입, 길이 제한 검증 |
| 문서 크기 제한 | 🟡 Medium | `request.resource.data.size()` 등으로 과도한 쓰기 방지 |

**보안 규칙 테스트**: Firebase Emulator Suite로 다음 시나리오를 반드시 테스트한다.
1. 인증 없이 접근 -> 거부
2. 인증된 사용자가 타 사용자 문서 접근 -> 거부
3. 인증된 사용자가 본인 문서 CRUD -> 성공
4. 잘못된 필드 타입 생성 -> 거부
5. 필수 필드 누락 -> 거부
6. 과도한 크기 문자열 -> 거부

### 10.2 인증 (Firebase Auth)

| 항목 | 요구사항 |
|---|---|
| OAuth 도메인 제한 | Firebase Console에서 승인 도메인만 허용. 와일드카드 도메인 사용 금지 |
| 토큰 저장 (Web) | IndexedDB (Firebase SDK 기본값). localStorage 변경 금지 |
| 토큰 저장 (Android) | Android Keystore (SDK 기본 동작) |
| 로그아웃 순서 | (1) Firebase signOut -> (2) Hive 캐시 클리어 -> (3) Riverpod 상태 초기화 |
| Auth State 감지 | `authStateChanges()` 스트림을 Riverpod Provider로 관리 |
| SDK 우회 금지 | Firebase Auth SDK를 우회하는 커스텀 OAuth 구현 금지 |

### 10.3 입력값 검증

모든 사용자 입력은 클라이언트 + Firestore Rules 양측에서 검증한다.

| 입력 필드 | 최대 길이 | 추가 검증 |
|---|---|---|
| 일정 제목 | 200자 | 공백만 입력 불가 |
| 투두 이름 | 200자 | 공백만 입력 불가 |
| 습관 이름 | 100자 | 공백만 입력 불가 |
| 목표 이름 | 200자 | 공백만 입력 불가 |
| 목표 설명 | 1000자 | 선택 필드 |
| 메모 | 2000자 | 선택 필드 |
| 위치 | 200자 | 선택 필드 |
| 사용자 이름 | 50자 | 공백만 입력 불가 |
| 색상 | enum 고정 | 8색 중 선택, 자유 입력 불가 |

### 10.4 데이터 보호

| 항목 | 요구사항 |
|---|---|
| XSS 방지 (Web) | CanvasKit 렌더러 사용. `dart:html` 직접 DOM 조작 금지. 사용자 입력은 `Text` 위젯으로만 표시 |
| Hive 캐시 암호화 | Hive 2.2.3 AES 암호화 적용. 256-bit 키를 `flutter_secure_storage`에 저장 |
| 캐시 데이터 범위 | UI 상태와 최근 데이터만 저장. 인증 토큰, API 키는 캐시에 저장하지 않음 |
| 캐시 삭제 | 로그아웃 시 모든 Hive Box를 `deleteFromDisk()`로 완전 삭제 |
| 전송 암호화 | Firestore SDK가 TLS(HTTPS) 기본 적용. 추가 설정 불필요 |

### 10.5 Web 보안 헤더

`firebase.json`에 다음 보안 헤더를 설정한다.

| 헤더 | 값 |
|---|---|
| X-Frame-Options | DENY |
| X-Content-Type-Options | nosniff |
| X-XSS-Protection | 1; mode=block |
| Referrer-Policy | strict-origin-when-cross-origin |
| Permissions-Policy | camera=(), microphone=(), geolocation=() |
| Content-Security-Policy | default-src 'self'; script-src 'self' googleapis 도메인 허용; frame-src Google 도메인 허용 |

CSP 주의: CanvasKit WASM 로딩을 위해 `'wasm-unsafe-eval'`이 필요할 수 있다. 빌드 후 동작 검증 필수.

### 10.6 Android 보안

| 항목 | 요구사항 |
|---|---|
| R8 난독화 | 릴리스 빌드에서 `minifyEnabled true`, `shrinkResources true` |
| google-services.json | `.gitignore` 등록. CI/CD에서 환경변수로 주입 |
| SHA-1/SHA-256 | Firebase Console에 등록된 지문과 앱 서명 키 일치 확인 |
| Play App Signing | Google Play App Signing 사용. 업로드 키/서명 키 분리 |
| Data Safety 섹션 | 수집 데이터, 사용 목적, 공유 여부 정확 기재 |

### 10.7 개인정보 보호

| 요구사항 | 위험 등급 |
|---|---|
| 앱 내 개인정보 처리방침 제공 (Google Play 필수) | 🟡 High |
| 최초 로그인 시 개인정보 수집/이용 동의 수집 | 🟡 High |
| 계정 삭제 시 Firestore 하위 컬렉션 재귀 삭제 | 🔴 Critical |
| 계정 삭제 시 Hive 캐시 완전 삭제 | 🟡 High |
| 계정 삭제 시 Firebase Auth 사용자 정보 삭제 | 🔴 Critical |

계정 삭제 시 주의: Firestore 하위 컬렉션은 상위 문서 삭제만으로 자동 삭제되지 않는다. Cloud Function 또는 Firebase Extension `Delete User Data`를 사용하여 재귀 삭제를 구현해야 한다.

### 10.8 데이터 마이그레이션

UserProfile에 `schemaVersion` 필드를 포함한다. 앱 시작 시 버전 불일치 확인 -> 순차 마이그레이션 실행(v1->v2->v3). 원본 필드를 즉시 삭제하지 않고 일정 기간 유지한다.

---

## 11. 에지 케이스 및 에러 핸들링

### 11.1 네트워크 단절

| 시나리오 | 대응 |
|---|---|
| 투두/습관 체크 중 끊김 | Firestore 오프라인 지속성으로 로컬 저장 -> 복구 시 자동 동기화 |
| 목표 삭제 중 끊김 | 오프라인 큐에 적재. 다른 기기에서 해당 문서 수정 시 충돌 가능 |
| 장기간 오프라인 | Firestore 캐시 기본 크기(Web 40MB, Android 100MB) 초과 시 오래된 캐시 제거 |

필수 구현:
- `Stream<ConnectivityResult>`로 네트워크 상태 실시간 감시
- 오프라인 상태에서 "오프라인 모드" 배너 표시
- `waitForPendingWrites()`로 로컬 변경의 서버 반영 여부 확인

### 11.2 동시 편집 (다중 기기/탭)

| 시나리오 | 대응 |
|---|---|
| 같은 투두를 두 기기에서 동시 수정 | Last-Write-Wins. Firestore 실시간 리스너로 변경 즉시 반영 |
| 같은 습관을 두 기기에서 동시 체크 | habitLog ID를 `{habitId}_{date}` 형태로 구성하여 중복 방지 |
| 한 기기에서 삭제한 데이터를 다른 기기에서 수정 | 실시간 리스너로 삭제 감지 -> 편집 화면 닫기 + 사용자 알림 |

Web 멀티탭 지원: `enablePersistence(PersistenceSettings(synchronizeTabs: true))` 설정 필수. 미설정 시 한 탭에서만 오프라인 지속성이 동작한다.

### 11.3 습관 시간 잠금

**위협**: 클라이언트 시간 조작으로 우회 가능.

| 검증 위치 | 구현 | 비고 |
|---|---|---|
| 클라이언트 (1차) | `DateTime.now()` 기반 과거 날짜 UI 비활성화 | 시간 조작에 취약 |
| Firestore Rules (2차) | `request.time`(서버 타임스탬프) 검증 | 날짜 비교 로직이 복잡 |
| Cloud Functions (3차, 향후) | 서버 시간 기준 검증 후 부적합 데이터 롤백 | 비용 발생 |

**위험 수용 판단**: 개인 생산성 도구이므로 시간 잠금 우회의 실질적 피해는 본인 기록 왜곡에 그친다. 클라이언트 + Firestore Rules 기본 검증으로 충분하다. 게이미피케이션(스트릭 보상) 도입 시 Cloud Functions를 필수 추가한다.

### 11.4 타임존/날짜 경계

| 원칙 | 설명 |
|---|---|
| 저장 | UTC Timestamp (Firestore `Timestamp` 타입) |
| 날짜 전용 필드 | `YYYY-MM-DD` 문자열 (타임존 무관) |
| 표시 | `intl` 패키지 `DateFormat`으로 로컬 시간 변환 |
| 비교 | 항상 UTC 기준 비교, 표시만 로컬 변환 |
| 자정 경계 | 00:00 시작 일정은 시작일 소속 |

### 11.5 에러 분류 및 처리

| 등급 | 정의 | 사용자 대응 | 개발자 대응 |
|---|---|---|---|
| Fatal | 앱 사용 불가 (인증 실패, Firestore 접속 불가) | 에러 화면 + 재시도 버튼 | Crashlytics 자동 보고 |
| Recoverable | 특정 기능 실패 (저장 실패, 일시 단절) | SnackBar 알림 + 자동 재시도 | 에러 로그 기록 |
| Warning | 계속 사용 가능 (캐시 불일치, 부분 로드 실패) | 무음 또는 미세 표시 | 디버그 로그 |
| Validation | 사용자 입력 오류 | 인라인 에러 메시지 | 로그 불필요 |

### 11.6 클라이언트 Rate Limiting

| 대상 | Debounce |
|---|---|
| 습관 체크박스 | 300ms |
| 투두 생성 버튼 | 버튼 비활성화 + 낙관적 UI |
| 검색/필터 | 500ms |

### 11.7 앱 크래시 후 복구

- 일정 생성 모달 작성 중 크래시: Hive에 임시 저장(draft). 재시작 시 복원 여부를 묻는다.
- 만다라트 위저드 중간 단계 크래시: 각 단계 완료 시 중간 상태를 Hive에 저장. 마지막 완료 단계에서 재개.
- Riverpod 상태 유실: `authStateChanges()` + Firestore 실시간 리스너로 자동 복구.

---

## 12. 빈 상태 / 에러 상태 UI

### 12.1 빈 상태 설계 원칙

모든 빈 상태 UI는 3요소를 포함한다.
1. **시각적 요소**: 기능을 상징하는 아이콘
2. **안내 텍스트**: "무엇이 없다" + "무엇을 하면 된다" 한 쌍
3. **행동 유도 (CTA)**: 바로 추가할 수 있는 버튼 또는 프리셋

빈 상태와 에러 상태를 명확히 구분한다. Firestore 접근 권한 문제로 데이터를 못 가져온 것인지, 실제로 데이터가 없는 것인지 다르게 표시해야 한다.

### 12.2 탭별 빈 상태

| 탭/섹션 | 메인 텍스트 | CTA |
|---|---|---|
| 홈 - 투두 | "오늘 할 일이 없어요" | "할 일 추가하러 가기" (투두 탭 이동) |
| 홈 - 습관 | "등록된 습관이 없어요" | "습관 등록하러 가기" |
| 홈 - D-day | "다가오는 일정이 없어요" | "일정 추가하러 가기" |
| 홈 - 주간 요약 | "이번 주 데이터가 아직 없어요" | 없음 (자동 생성) |
| 캘린더 - 날짜별 | "일정이 없습니다" | "+" 버튼 |
| 투두 - 목록 | "오늘 일정이 없습니다" | "+" 버튼 |
| 습관 - 오늘 | "아직 등록된 습관이 없어요" | "인기 습관으로 시작하기" + "직접 만들기" |
| 루틴 - 목록 | "아직 등록된 루틴이 없어요" | "첫 루틴 만들기" |
| 목표 - 년간 | "아직 등록된 목표가 없어요" | "목표 추가하기" |
| 목표 - 월간 | "이번 달 목표가 없어요" | "하위 목표 추가하기" |
| 만다라트 | "만다라트로 목표를 구조화해보세요!" | "만다라트 만들기" |

### 12.3 에러 상태 처리

| 에러 유형 | 표시 위치 | 메시지 | 처리 |
|---|---|---|---|
| 네트워크 에러 | 상단 지속 배너 | "인터넷 연결이 불안정해요" | 오프라인 모드 전환, 복구 시 자동 동기화 |
| 인증 에러 | 풀스크린 오버레이 | "로그인이 만료되었어요" | "다시 로그인" 버튼, 성공 시 이전 화면 복귀 |
| 동기화 에러 | 하단 스낵바 (일시) | "동기화하지 못했어요" | 자동 재시도 30초x3회 -> 수동 동기화 버튼 |
| 입력 에러 | 인라인 | 필드별 메시지 | 실시간 유효성 검사, 에러 시 저장 버튼 비활성화 |
| 서버 에러 | 풀스크린 | "서비스에 문제가 발생했어요" | 재시도 버튼 + 캐시 기반 읽기 전용 모드 |

**에러 처리 UX 원칙**:
- "잘못된 입력입니다" 대신 "OOO을 입력해주세요" 형태로 표시한다
- 에러 메시지와 함께 항상 다음 행동을 안내한다
- 입력 중 네트워크 에러 발생 시에도 작성 내용을 로컬에 보존한다
- 에러 복구 시 별도 조작 없이 자동으로 정상 상태로 복귀한다
- 사용자가 인지할 필요 없는 기술적 에러(캐시 미스 등)는 내부 로깅만 수행한다

---

## 13. 🖥️ 플랫폼별 고려사항

### 13.1 Web vs Android 차이

| 항목 | Flutter Web | Flutter Android |
|---|---|---|
| 렌더링 | CanvasKit (WASM) | Skia (네이티브) |
| Hive 저장소 | IndexedDB | 파일 시스템 |
| Firebase Auth | 브라우저 팝업/리다이렉트 | Google Play Services |
| Firestore 캐시 | IndexedDB (명시적 활성화 필요) | SQLite (기본 활성) |
| 오프라인 지속성 | 명시적 활성화 + `synchronizeTabs: true` 필수 | 기본 활성 |
| 배포 | Firebase Hosting | Google Play Store |
| 반응형 | 필수 (데스크톱 대응) | 모바일 고정 |
| URL 공유 | 가능 (GoRouter 히스토리 연동) | 선택적 |
| 키보드 | 물리 키보드 단축키 고려 | 소프트 키보드 대응 |

### 13.2 반응형 브레이크포인트

```dart
abstract class Breakpoints {
  static const double mobile = 600;    // < 600: 모바일
  static const double tablet = 900;    // 600~900: 태블릿
  static const double desktop = 1200;  // > 1200: 데스크톱
}
```

- **모바일 (< 600px)**: 하단 네비게이션, 세로 스크롤, 풀 너비 카드
- **태블릿 (600~900px)**: 하단 네비게이션 유지, 카드 2열 그리드
- **데스크톱 (> 1200px)**: 하단 네비게이션 유지, 콘텐츠 maxWidth 960px 제한

### 13.3 Web 전용

- 초기 로딩: CanvasKit WASM 2~3MB -> 스플래시/로딩 화면 필수
- PWA 지원: `manifest.json` + `service-worker.js`로 설치 가능
- 브라우저 뒤로가기: GoRouter가 자동 연동

### 13.4 Android 전용

- Google Play 정책: 앱 아이콘, 스플래시, 권한 선언, Data Safety 섹션
- 앱 크기: `--split-per-abi` 빌드로 APK 최적화
- 알림(v2.0): `flutter_local_notifications` + `workmanager` 패키지 검토

---

## 14. 구현 우선순위

### Phase 1: 기반 설정

1. Flutter 프로젝트 생성 + Firebase 연동 (`flutterfire configure`)
2. core/ 모듈 구현 (C0.1~C0.9)
3. shared/models/ 전체 모델 정의 (freezed)
4. shared/enums/ 정의
5. Firestore 보안 규칙 작성 + Emulator 테스트
6. GoRouter 설정 + 인증 가드
7. Hive 초기화 + 캐시 암호화 설정

### Phase 2: 인증 + 온보딩

1. Google 로그인 구현 (Web + Android)
2. 개인정보 처리 동의 화면
3. 이름 입력 화면
4. 스플래시 화면

### Phase 3: 핵심 탭 구현

1. **투두 탭** (F3): 데이터 CRUD의 가장 기본. 다른 탭의 기반이 된다.
2. **습관 탭** (F4.1~F4.5): 시간 잠금, 스트릭 등 고유 로직을 포함한다.
3. **캘린더 탭** (F2): 월간+일간 뷰 + 일반/범위 일정 CRUD.
4. **목표 탭** (F5): 계층 구조(년간->월간->실천) + 진행률 계산.
5. **홈 탭** (F1): 다른 탭 데이터를 집계하므로 마지막에 구현한다.

### Phase 4: UX 완성

1. 빈 상태 UI 전체 적용
2. 에러 상태 처리 (네트워크/인증/동기화/입력)
3. 오프라인 모드 + Hive 캐시 전략
4. 습관 프리셋
5. 반응형 레이아웃 (Web 데스크톱 대응)

### Phase 5: 보안 + 배포

1. firebase.json 보안 헤더 설정
2. Firestore Rules 세부 필드 검증 추가
3. 계정 삭제 기능 (재귀 삭제)
4. R8 난독화 (Android)
5. Firebase Hosting 배포 (Web)
6. Google Play Store 배포 (Android)

---

## 부록: 기술적 트레이드오프 기록

| 결정 | 선택 | 대안 | 근거 |
|---|---|---|---|
| DB | Firestore | Supabase (PostgreSQL) | 실시간 동기화/오프라인 캐시 내장, Firebase 생태계 통합 |
| tasks 위치 | goals/{goalId}/tasks/ | goals/subGoals/tasks/ (3단 중첩) | 전체 tasks 조회 효율성, 진행률 계산 용이 |
| 서브탭 | 내부 StateProvider | 개별 라우트 | 상태 보존 중요, 딥링크 불필요 |
| 직렬화 | freezed + json_serializable | 수동 구현 | 불변 객체, copyWith, JSON 자동 생성 |
| 캐시 | Hive (보조) + Firestore 내장 (1차) | Firestore만 사용 | 앱 시작 속도, 로컬 설정 저장 |
| 습관 프리셋 | 앱 번들 하드코딩 | Firestore 공용 컬렉션 | 보안 규칙 단순화 (공개 컬렉션 불필요) |
