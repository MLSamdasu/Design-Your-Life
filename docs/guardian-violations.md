# Guardian Violation Report

## 조사 완료 범위
- 모든 공유 모델 (11개): Todo, Event, Goal, GoalTask, SubGoal, Habit, HabitLog, Routine, Tag, UserProfile, MandalartGrid
- 모든 Repository (9개): TodoRepository, EventRepository, GoalRepository, SubGoalRepository, TaskRepository, HabitRepository, HabitLogRepository, RoutineRepository, TagRepository, TimerRepository
- 모든 Provider (9개 기능): todo_provider, event_provider, goal_provider, mandalart_provider, habit_provider, routine_provider, timer_provider, tag_provider, achievement_provider
- 홈 대시보드 Provider (3개): home_provider, home_dday_provider, home_models
- 핵심 Provider: global_providers, auth_provider, calendar_provider
- UI 화면: home_screen, todo_screen, calendar_screen

---

## [VIOLATION-001] Severity: P0
- **Discovery point**: Initial Investigation
- **Violating agent**: 이전 구현 에이전트 (habit_provider, routine_provider, goal_provider)
- **Violation type**: 데이터 연결 단절 (로컬 퍼스트 아키텍처 비일관성)
- **Violation details**: 
  **habit_provider, routine_provider, goal_provider는 `currentUserIdProvider`가 null이면 빈 리스트를 반환한다.**
  그러나 이 앱은 로컬 퍼스트 아키텍처로, 로그인 없이도 모든 기능이 동작해야 한다.
  `currentUserIdProvider`는 `authStateProvider.valueOrNull?.userId`를 반환하는데,
  앱 시작 시 `authStateProvider`는 `AsyncLoading` 상태이고, 세션 복원이 완료되기 전까지 `valueOrNull`은 null이다.
  또한 사용자가 로그인하지 않으면 영구적으로 null이다.
  
  **결과**: 로그인하지 않은 사용자는 습관, 루틴, 목표 데이터가 전혀 표시되지 않는다.
  
  **영향받는 Provider 목록**:
  - `activeHabitsProvider` (habit_provider.dart:57) — `if (userId == null) return const [];`
  - `habitLogsForDateProvider` (habit_provider.dart:85)
  - `habitLogsForMonthProvider` (habit_provider.dart:97)
  - `toggleHabitProvider` (habit_provider.dart:214)
  - `createHabitProvider` (habit_provider.dart:257)
  - `updateHabitProvider` (habit_provider.dart:272)
  - `deleteHabitProvider` (habit_provider.dart:285)
  - `routinesProvider` (routine_provider.dart:30)
  - `activeRoutinesProvider` (routine_provider.dart:41)
  - `createRoutineProvider` (routine_provider.dart:54)
  - `toggleRoutineActiveProvider` (routine_provider.dart:73)
  - `updateRoutineProvider` (routine_provider.dart:92)
  - `deleteRoutineProvider` (routine_provider.dart:111)
  - `goalsStreamProvider` (goal_provider.dart:71)
  - `goalsByYearStreamProvider` (goal_provider.dart:82)
  - `goalsByYearAndPeriodStreamProvider` (goal_provider.dart:93)
  - `subGoalsStreamProvider` (goal_provider.dart:108)
  - `tasksByGoalStreamProvider` (goal_provider.dart:121)
  - `tasksBySubGoalStreamProvider` (goal_provider.dart:137)
  
  **비교**: `todosForDateProvider`와 `eventsForMonthProvider`는 userId를 체크하지 않고 정상 동작한다.
  `todayTodosProvider`, `todayHabitsProvider`, `todayRoutinesProvider` (홈 대시보드)도 userId를 체크하지 않고 Hive에서 직접 조회하여 정상 동작한다. 이로 인해 홈 대시보드에서는 습관 데이터가 보이지만, 습관 탭으로 이동하면 데이터가 비어 있는 불일치가 발생한다.

- **Related file**: 
  - `lib/features/habit/providers/habit_provider.dart:54-57`
  - `lib/features/habit/providers/routine_provider.dart:26-30`
  - `lib/features/goal/providers/goal_provider.dart:69-71`
- **Original requirement**: "백앤드(DB)랑 프론트앤드 위치 연결 전부 세세하게 모두 조사" — 연결이 끊어진 상태
- **Correction order**: 
  habit_provider, routine_provider, goal_provider의 모든 FutureProvider 및 CRUD 액션에서 
  `if (userId == null) return const [];` / `if (userId == null) return;` 가드를 제거하거나,
  `final userId = ref.watch(currentUserIdProvider) ?? AppConstants.localUserId;` 패턴으로 변경하여
  로컬 퍼스트 아키텍처에서 항상 데이터를 반환하도록 수정해야 한다.
  todo_provider.dart와 event_provider.dart의 패턴(userId 체크 없음)과 일관성을 유지해야 한다.
- **Status**: OPEN

---

## [VIOLATION-002] Severity: P1
- **Discovery point**: Initial Investigation
- **Violating agent**: 이전 구현 에이전트
- **Violation type**: 교차 기능 데이터 비일관성
- **Violation details**: 
  **홈 대시보드 Provider(home_provider.dart)와 기능별 Provider의 데이터 조회 방식이 불일치한다.**
  
  홈 대시보드의 `todayHabitsProvider`는 HiveCacheService로 Hive에서 직접 조회하여 습관 데이터를 정상 반환한다 (userId 체크 없음).
  그러나 습관 탭의 `activeHabitsProvider`는 userId를 체크하여 미로그인 시 빈 리스트를 반환한다.
  
  **결과**: 홈에서는 습관 3개가 보이지만, 습관 탭으로 이동하면 빈 화면이 표시되는 UX 불일치.
  
  마찬가지로 `todayRoutinesProvider` (홈)는 데이터를 표시하지만 `routinesProvider` (루틴 탭)는 빈 리스트를 반환한다.

- **Related file**: 
  - `lib/features/home/providers/home_provider.dart:75-174` (홈: userId 체크 없이 정상 동작)
  - `lib/features/habit/providers/habit_provider.dart:53-59` (습관 탭: userId null이면 빈 리스트)
- **Original requirement**: "프론트앤드에서 보여줘야하는것을 확인 → 그것을 백앤드의 어디부분에 연결"
- **Correction order**: VIOLATION-001 수정으로 함께 해결된다. 모든 Provider에서 로컬 퍼스트 패턴 통일 필요.
- **Status**: OPEN

---

## [VIOLATION-003] Severity: P1
- **Discovery point**: Initial Investigation
- **Violating agent**: 이전 구현 에이전트
- **Violation type**: 초기 인증 상태 타이밍 문제
- **Violation details**: 
  **앱 시작 시 `authStateProvider`가 `AsyncLoading` 상태에서 시작하여 `valueOrNull`이 null을 반환한다.**
  
  `main.dart`에서 `restoreSession()`을 `Future.microtask` 안에서 호출하므로,
  앱의 첫 번째 프레임이 렌더링될 때 `currentUserIdProvider`는 null이다.
  Goal/Habit/Routine 탭이 이 시점에 데이터를 요청하면 빈 리스트를 받는다.
  세션 복원이 완료되면 Provider가 갱신될 수 있지만, 만약 사용자가 로그인하지 않은 상태라면
  `authStateProvider`는 `AsyncData(AuthState.unauthenticated())`가 되고 `userId`는 영구적으로 null이 된다.
  
  이는 VIOLATION-001의 근본 원인 분석이다.

- **Related file**: 
  - `lib/main.dart:62-65` (Future.microtask로 세션 복원)
  - `lib/core/auth/auth_provider.dart:109-111` (currentUserIdProvider)
- **Original requirement**: "이 백앤드는 프론트앤드에 또 다른 어디에 연결 이런식으로 계속 타고가면서 맞는지 확인"
- **Correction order**: VIOLATION-001의 수정이 근본적 해결책이다. userId null 가드를 제거하여 인증 상태와 무관하게 로컬 데이터를 표시해야 한다.
- **Status**: OPEN

---

## [VIOLATION-004] Severity: P2
- **Discovery point**: Initial Investigation
- **Violating agent**: 이전 구현 에이전트
- **Violation type**: 파일 크기 규칙 위반
- **Violation details**: 
  다음 파일들이 300줄 제한을 초과한다:
  - `theme_preset_registry.dart`: 954줄 (300줄 제한의 3.18배)
  - `layout_tokens.dart`: 757줄
  - `tag_management_screen.dart`: 713줄
  - `daily_schedule_view.dart`: 697줄
  - `habit_tracker_view.dart`: 605줄
  - `cloud_backup_card.dart`: 510줄
  - `event_provider.dart`: 506줄
  - `sub_goal_card.dart`: 476줄
  - `tag_chip_selector.dart`: 457줄
  - `goal_card.dart`: 450줄
  - `event_create_dialog.dart`: 441줄
  - `goal_provider.dart`: 421줄
  - `todo_create_dialog.dart`: 380줄
  - `todo_screen.dart`: 369줄
  - `habit_preset_sheet.dart`: 350줄
  - `todo_item_tile.dart`: 349줄
  - `event_overlap_layout.dart`: 321줄
  - `daily_view.dart`: 317줄
  - `settings_screen.dart`: 316줄
  - `backup_service.dart`: 312줄
  - `habit_card.dart`: 308줄
  - `goal_create_dialog.dart`: 305줄
  - `theme_preview_card.dart`: 304줄
  - `app_router.dart`: 304줄
  
  총 24개 파일이 300줄 제한을 초과한다.

- **Related file**: 위 파일 목록 참조
- **Original requirement**: CLAUDE.md Non-negotiable SRP 규칙 "file 200 lines, component 150 lines max"
- **Correction order**: 현재 Phase에서는 데이터 연결 검사가 주 목적이므로 P2로 분류. 추후 리팩토링 Phase에서 SRP 기반 분리 필요.
- **Status**: OPEN (데이터 연결 수정과 별개 이슈)

---

## [VIOLATION-005] Severity: P2
- **Discovery point**: Initial Investigation
- **Violating agent**: 이전 구현 에이전트
- **Violation type**: 에러 삼킴 패턴 (catch 블록에서 에러 무시)
- **Violation details**: 
  다음 위치에서 catch (_)로 에러를 삼키고 있다:
  - `timer_repository.dart:47,73,98` — 파싱 실패한 항목을 continue로 건너뛴다 (로그 없음)
  - `home_provider.dart:68,171,229` — 전체 Provider가 empty 값을 반환 (에러 원인 파악 불가)
  - `home_dday_provider.dart:69` — 전체 D-Day 목록이 빈 리스트 반환 (에러 원인 파악 불가)
  - `routine.dart:97` — 시간 파싱 실패 시 자정으로 기본 처리 (로그 없음)
  
  이는 "우회(workaround) 금지" 규칙에 해당할 수 있으나, 방어적 코딩의 일환으로 볼 수도 있다.
  그러나 에러가 발생해도 사용자에게 피드백이 없어 문제 진단이 어렵다.

- **Related file**: 
  - `lib/features/timer/services/timer_repository.dart:47`
  - `lib/features/home/providers/home_provider.dart:68`
- **Original requirement**: CLAUDE.md "에러 발생 시 근본 원인을 해결해야 한다"
- **Correction order**: 최소한 debugPrint 또는 ErrorHandler.logServiceError로 에러를 기록하도록 수정 필요. try-catch로 에러를 완전히 삼키는 것은 문제의 원인을 은폐한다.
- **Status**: OPEN

---

## [VIOLATION-006] Severity: P2
- **Discovery point**: Initial Investigation
- **Violating agent**: 이전 구현 에이전트
- **Violation type**: 데이터 일관성 리스크
- **Violation details**: 
  **Todo.colorIndex가 항상 0을 반환하는 하드코딩 문제.**
  `lib/shared/models/todo.dart:52` — `int get colorIndex => 0;`
  Todo 모델의 `colorIndex` 게터가 항상 0을 반환한다.
  Routine 모델에는 hex 문자열 ↔ colorIndex 변환 로직이 구현되어 있으나,
  Todo 모델에는 이 변환 로직이 없어 모든 투두가 동일한 색상(인덱스 0)으로 표시된다.
  
  캘린더에서 투두를 CalendarEvent로 변환할 때 `colorIndex: todo.colorIndex`를 사용하므로(event_provider.dart:420),
  캘린더의 투두 이벤트도 항상 첫 번째 색상으로만 표시된다.
  
  Todo에는 `color` 필드(hex 문자열)가 있지만, `colorIndex` 게터에서 이 필드를 활용하지 않는다.

- **Related file**: 
  - `lib/shared/models/todo.dart:52`
  - `lib/features/calendar/providers/event_provider.dart:420`
- **Original requirement**: "디자인,프론트앤드에서 보여줘야하는것을 확인 → 그것을 백앤드의 어디부분에 연결"
- **Correction order**: Todo.colorIndex 게터에서 color 필드(hex 문자열)를 Routine._hexToColorIndex와 같은 방식으로 변환하거나, 별도의 colorIndex 필드를 모델에 추가해야 한다.
- **Status**: OPEN

---

## [VIOLATION-007] Severity: P2
- **Discovery point**: Initial Investigation
- **Violating agent**: 이전 구현 에이전트
- **Violation type**: 데이터 일관성 리스크
- **Violation details**: 
  **Habit.colorIndex도 항상 0을 반환하는 하드코딩 문제.**
  `lib/shared/models/habit.dart:49` — `int get colorIndex => 0;`
  Habit 모델의 `colorIndex` 게터가 항상 0을 반환한다.
  Habit에는 `color` 필드(hex 문자열)가 있지만 변환 로직이 없다.
  
  HabitPreset에는 color가 hex 문자열로 정의되어 있어 프리셋으로 생성한 습관도 
  UI에서는 항상 첫 번째 색상으로 표시된다.

- **Related file**: `lib/shared/models/habit.dart:49`
- **Original requirement**: "디자인,프론트앤드에서 보여줘야하는것을 확인"
- **Correction order**: Todo.colorIndex와 동일한 수정 필요. hex color → colorIndex 변환 로직을 추가해야 한다.
- **Status**: OPEN

---

## [VIOLATION-008] Severity: P1
- **Discovery point**: Initial Investigation
- **Violating agent**: 이전 구현 에이전트
- **Violation type**: 교차 기능 데이터 연결 검증
- **Violation details**: 
  **Goal Provider에서 `currentUserIdProvider` null 체크로 인해 만다라트 마법사가 작동하지 않을 수 있다.**
  
  `lib/features/goal/presentation/widgets/mandalart_wizard.dart:72-73`:
  ```dart
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return;
  ```
  
  만다라트 마법사에서 목표 저장 시 userId가 null이면 저장 동작이 실행되지 않는다.
  사용자가 만다라트를 채우고 저장 버튼을 눌러도 아무 반응이 없게 된다.
  
  이는 VIOLATION-001의 확장이지만, 사용자 경험에 직접적인 영향을 미치는 UI 수준 버그이다.

- **Related file**: `lib/features/goal/presentation/widgets/mandalart_wizard.dart:72-73`
- **Original requirement**: "잘못된 부분은 수정하면서 전부 검사,수정 진행해"
- **Correction order**: userId null 가드를 제거하거나 로컬 사용자 ID 폴백을 적용해야 한다.
- **Status**: OPEN

---

## [VIOLATION-009] Severity: P2
- **Discovery point**: Initial Investigation
- **Violating agent**: 이전 구현 에이전트
- **Violation type**: 데이터 직렬화 키 불일치
- **Violation details**: 
  **TagRepository._toHiveMap()은 camelCase 키를 사용하지만, 일부 조회 로직은 snake_case 키를 기대한다.**
  
  TagRepository.toHiveMap (tag_repository.dart:100-108)은 `colorIndex`, `createdAt`, `userId` (camelCase)로 저장한다.
  Tag.fromMap (tag.dart:45-46)은 `color_index`와 `colorIndex` 양쪽 모두 지원한다.
  
  그러나 `todayTodosProvider` (home_provider.dart)에서 태그를 참조할 때는
  `scheduled_date` (snake_case)로 필터링한다.
  
  **현재는 fromMap에서 양쪽 키를 모두 처리하므로 직접적인 버그는 아니지만,**
  **같은 프로젝트 내에서 snake_case와 camelCase가 혼용되어 향후 유지보수 위험이 있다.**

  특히 BackupService에서 복원할 때, 원본 데이터의 키 형식에 따라 파싱 실패 가능성이 있다.

- **Related file**: 
  - `lib/shared/services/tag_repository.dart:100-108`
  - `lib/features/timer/services/timer_repository.dart:149-161`
- **Original requirement**: "전부 세세하게 모두 조사"
- **Correction order**: 프로젝트 전체에서 Hive 저장 키를 snake_case 또는 camelCase 중 하나로 통일하는 것을 권장. 현재는 fromMap에서 양쪽 모두 처리하므로 기능 장애는 없으나, 일관성 확보가 필요하다.
- **Status**: OPEN

---

## 정상 확인된 데이터 흐름 (위반 없음)

### 1. Todo 데이터 흐름 (정상)
```
Todo Model (shared/models/todo.dart)
  → TodoRepository (features/todo/services/todo_repository.dart) — Hive todosBox 직접 CRUD
    → TodoProvider (features/todo/providers/todo_provider.dart) — userId 체크 없이 로컬 조회 OK
      → TodoScreen (features/todo/presentation/todo_screen.dart) — todosForDateProvider watch OK
      → DailyScheduleView, TodoListView — sortedTodosProvider/filteredTodosProvider watch OK
```
- **Cross-feature**: 투두 변경 시 `ref.invalidate(eventsForMonthProvider)` 호출 → 캘린더 갱신 OK
- **Cross-feature**: 투두 변경 시 `ref.invalidate(todayTodosProvider)` 호출 → 홈 대시보드 갱신 OK
- **Cross-feature**: 투두 삭제 시 연결된 타이머 로그 정리 OK (deleteTodoProvider)

### 2. Event(Calendar) 데이터 흐름 (정상)
```
Event Model (shared/models/event.dart)
  → EventRepository (features/calendar/services/event_repository.dart) — Hive eventsBox 직접 CRUD
    → EventProvider (features/calendar/providers/event_provider.dart) — userId 체크 없이 로컬 조회 OK
      → CalendarScreen → MonthlyView/WeeklyView/DailyView — eventsForMonthProvider watch OK
```
- **Cross-feature**: todosBox의 투두도 CalendarEvent로 변환하여 캘린더에 표시 OK
- **Cross-feature**: 루틴도 routinesForDayProvider로 캘린더 일간 뷰에 표시 OK
- **Cross-feature**: 이벤트 변경 시 `ref.invalidate(upcomingDdaysProvider)` 호출 → 홈 D-Day 갱신 OK

### 3. Tag 데이터 흐름 (정상)
```
Tag Model (shared/models/tag.dart)
  → TagRepository (shared/services/tag_repository.dart) — Hive tagsBox 직접 CRUD
    → TagProvider (shared/providers/tag_provider.dart) — userId 체크 없이 로컬 조회 OK
      → TagFilterBar, TagChipSelector, TagManagementScreen — userTagsProvider watch OK
```
- **Cross-feature**: 태그 삭제 시 todosBox/goalsBox에서 orphan tagId 정리 OK (deleteTagProvider)
- **Cross-feature**: filteredTodosProvider에서 selectedTagFilterProvider로 태그 필터링 OK

### 4. Timer 데이터 흐름 (정상)
```
TimerLog Model (features/timer/models/timer_log.dart)
  → TimerRepository (features/timer/services/timer_repository.dart) — Hive timerLogsBox 직접 CRUD
    → TimerProvider (features/timer/providers/timer_provider.dart) — userId 체크 없이 로컬 동작 OK
      → TimerScreen → TimerDisplay, TimerLogList, TimerSessionInfo — timerStateProvider watch OK
```
- **Cross-feature**: 타이머 완료 시 연결된 투두 자동 완료 OK (toggleTodoProvider 호출)
- **Cross-feature**: 타이머 로그 저장 후 todayTimerLogsProvider 갱신 OK

### 5. Achievement 데이터 흐름 (정상)
```
Achievement Model (features/achievement/models/achievement.dart)
  → AchievementRepository — Hive achievementsBox 직접 CRUD
    → AchievementProvider — userId 체크 없이 로컬 동작 OK
      → AchievementScreen, AchievementSummaryCard — userAchievementsProvider watch OK
```
- **Cross-feature**: 투두 완료/습관 체크/타이머 완료 시 checkAndUnlockAchievements 호출 OK
- **Cross-feature**: AchievementStatsCollector가 Hive에서 직접 통계 집계 OK

### 6. Home Dashboard 데이터 흐름 (정상 — 단, VIOLATION-002 참조)
```
홈 대시보드 Provider (home_provider.dart)
  → todayTodosProvider — Hive todosBox 직접 조회 (userId 체크 없음) OK
  → todayHabitsProvider — Hive habitsBox + habitLogsBox 직접 조회 (userId 체크 없음) OK
  → todayRoutinesProvider — Hive routinesBox 직접 조회 (userId 체크 없음) OK
  → upcomingDdaysProvider — Hive eventsBox 직접 조회 OK
  → weekSummaryProvider — todayTodosProvider + todayHabitsProvider 파생 OK
```

### 7. Hive Box 매핑 (정상)
| 모델 | Hive Box 이름 | AppConstants 상수 |
|---|---|---|
| UserProfile | userProfileBox | AppConstants.userProfileBox |
| Event | eventsBox | AppConstants.eventsBox |
| Todo | todosBox | AppConstants.todosBox |
| Habit | habitsBox | AppConstants.habitsBox |
| HabitLog | habitLogsBox | AppConstants.habitLogsBox |
| Routine | routinesBox | AppConstants.routinesBox |
| Goal | goalsBox | AppConstants.goalsBox |
| SubGoal | subGoalsBox | AppConstants.subGoalsBox |
| GoalTask | goalTasksBox | AppConstants.goalTasksBox |
| TimerLog | timerLogsBox | AppConstants.timerLogsBox |
| Achievement | achievementsBox | AppConstants.achievementsBox |
| Tag | tagsBox | AppConstants.tagsBox |
| Settings | settingsBox | AppConstants.settingsBox |
| SyncMeta | syncMetaBox | AppConstants.syncMetaBox |

모든 모델이 대응하는 Hive Box에 올바르게 매핑되어 있다.

### 8. MandalartMapper 데이터 흐름 (정상 — 단, VIOLATION-001로 인한 영향 있음)
```
MandalartMapper (features/goal/services/mandalart_mapper.dart)
  ← Goal + SubGoal + GoalTask 입력
  → MandalartGrid (뷰 전용 모델, Hive에 저장하지 않음)
    → MandalartProvider (features/goal/providers/mandalart_provider.dart)
      → MandalartGrid/MandalartWizard UI 위젯
```
- MandalartMapper가 Goal/SubGoal/GoalTask를 올바르게 9x9 그리드로 변환하는 구조 OK
- 단, VIOLATION-001로 인해 goalsStreamProvider/subGoalsStreamProvider가 빈 리스트를 반환하면 그리드가 표시되지 않음

---

## 위반 요약

| ID | Severity | 유형 | 상태 |
|---|---|---|---|
| VIOLATION-001 | P0 | 데이터 연결 단절 (userId null 가드) | OPEN |
| VIOLATION-002 | P1 | 교차 기능 데이터 비일관성 | OPEN |
| VIOLATION-003 | P1 | 초기 인증 상태 타이밍 문제 | OPEN |
| VIOLATION-004 | P2 | 파일 크기 규칙 위반 (24개 파일) | OPEN |
| VIOLATION-005 | P2 | 에러 삼킴 패턴 | OPEN |
| VIOLATION-006 | P2 | Todo.colorIndex 하드코딩 (항상 0) | OPEN |
| VIOLATION-007 | P2 | Habit.colorIndex 하드코딩 (항상 0) | OPEN |
| VIOLATION-008 | P1 | 만다라트 마법사 userId null 가드 | OPEN |
| VIOLATION-009 | P2 | 직렬화 키 형식 혼용 | OPEN |

**P0**: 1건 (즉시 수정 필요)
**P1**: 3건 (Phase 완료 전 수정 필요)
**P2**: 5건 (다음 Phase 진입 전 수정 권장)
