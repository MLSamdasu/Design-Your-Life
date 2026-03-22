# Guardian Violation Report v2 - 2nd Deep Investigation Pass

**조사 일시**: 2026-03-13
**조사 범위**: 전체 프로젝트 (models, providers, UI widgets, services, core)
**조사 목적**: 1차 수정 8건의 회귀 검증 + 미발견 엣지 케이스/데이터 불일치 탐색

---

## 요약 (Summary)

| 심각도 | 발견 건수 | 상태 |
|--------|----------|------|
| **P0** (핵심 기능 차단) | 2 | OPEN |
| **P1** (데이터 정합성) | 1 | OPEN |
| **P2** (코드 품질) | 1 | OPEN |
| **P3** (개선 권장) | 1 | OPEN |
| **검증 완료 (정상)** | 15 | RESOLVED |

---

## P0 위반 사항 (즉시 수정 필요)

### [VIOLATION-V2-001] AchievementStatsCollector: is_archived vs is_active 필드 불일치

- **심각도**: P0
- **발견 위치**: `lib/features/achievement/services/achievement_stats_collector.dart`
- **위반 유형**: 데이터 모델 불일치 (잘못된 필드명 참조)
- **위반 상세**:
  - **80번 줄** (`_calcLongestHabitStreak`): `data['is_archived'] != true`로 활성 습관을 필터링한다.
  - **204번 줄** (`_checkAllHabitsCompletedToday`): `data['is_archived'] != true`로 오늘 예정된 습관을 필터링한다.
  - 그러나 **Habit 모델**(habit.dart)은 `is_active` 필드를 사용하며, `is_archived` 필드는 모델에 존재하지 않는다.
  - Hive habitsBox에 저장되는 데이터에도 `is_archived` 키는 없고 `is_active` 키만 존재한다 (habit.dart의 toInsertMap/toUpdateMap 확인).
  - 결과적으로 `data['is_archived']`는 항상 `null`이므로 `null != true`는 항상 `true`가 된다.
  - 이로 인해 **비활성화된 습관(is_active=false)도 업적 통계에 포함**되어, 스트릭 계산과 "오늘 모든 습관 달성" 판단이 부정확해진다.
- **관련 파일**: 
  - `lib/features/achievement/services/achievement_stats_collector.dart:80,204`
  - `lib/shared/models/habit.dart:165` (toInsertMap에서 `is_active` 사용)
- **원래 요구사항**: 활성 습관만 대상으로 업적 달성 조건을 평가해야 한다
- **수정 지시**:
  ```
  // 80번 줄 변경:
  - if (id != null && data['is_archived'] != true) {
  + if (id != null && data['is_active'] != false) {
  
  // 204번 줄 변경:
  - if (data is Map && data['is_archived'] != true) {
  + if (data is Map && data['is_active'] != false) {
  ```
  `!= false` 패턴을 사용하는 이유: `is_active` 키가 누락된 레거시 데이터에서도 기본적으로 활성으로 간주하기 위함 (Habit.fromMap의 기본값 `true`와 일치).
- **상태**: OPEN

---

### [VIOLATION-V2-002] userId null 가드가 로컬 퍼스트 기능을 차단함 (5개 위치)

- **심각도**: P0
- **발견 위치**: 아래 5개 파일
- **위반 유형**: 아키텍처 위반 (로컬 퍼스트 원칙 위반)
- **위반 상세**:
  아래 코드 위치에서 `if (userId == null) return;` 패턴이 사용되어, **미로그인 사용자가 핵심 기능을 사용할 수 없다**. 프로젝트의 로컬 퍼스트 아키텍처에서는 로그인 없이도 모든 CRUD가 동작해야 한다.

  | 파일 | 줄 번호 | 차단되는 기능 |
  |------|---------|-------------|
  | `lib/features/todo/presentation/todo_screen.dart` | 42-43 | QuickInputBar를 통한 투두 빠른 생성 |
  | `lib/features/todo/presentation/todo_screen.dart` | 337-338 | FAB를 통한 투두 생성 |
  | `lib/shared/widgets/tag_chip_selector.dart` | 71-72 | 인라인 태그 생성 |
  | `lib/features/habit/presentation/widgets/habit_tracker_view.dart` | 103-104 | 프리셋에서 습관 생성 |
  | `lib/features/habit/presentation/widgets/routine_list_view.dart` | 200-201 | 루틴 생성 |
  | `lib/features/settings/presentation/widgets/tag_management_screen.dart` | 472-476 | 태그 저장 (생성/수정) |

  **참고: 이미 올바르게 처리된 곳들**:
  - `timer_provider.dart:211` -- `?? ''` 폴백 사용 (정상)
  - `mandalart_wizard.dart:74` -- `?? AppConstants.localUserId` 폴백 사용 (정상)
  - `achievement_provider.dart:70` -- `?? ''` 폴백 사용 (정상)
  - `event_create_dialog.dart:175` -- EventRepository 내부에서 처리 (정상)

- **원래 요구사항**: "앱 시작 시 로그인 없이 바로 홈 화면 진입", "로컬 퍼스트: 모든 CRUD는 Hive에서 수행, 인터넷 없이 완전 동작"
- **수정 지시**:
  각 위치에서 `if (userId == null) return;` 패턴을 `?? AppConstants.localUserId` 폴백 패턴으로 변경한다.
  ```dart
  // 변경 전:
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return;
  
  // 변경 후:
  final userId = ref.read(currentUserIdProvider) ?? AppConstants.localUserId;
  ```
  userId를 실제 Hive 저장에 넘기는 곳에서는 빈 문자열(`''`)이 아닌 `AppConstants.localUserId`를 사용하여 만다라트 위저드, 타이머 로그 등과 일관성을 유지한다.
- **상태**: OPEN

---

## P1 위반 사항 (Phase 완료 전 수정 필요)

### [VIOLATION-V2-003] updateTodoProvider에서 todayTodosProvider 무효화 누락

- **심각도**: P1
- **발견 위치**: `lib/features/todo/providers/todo_provider.dart:180-196`
- **위반 유형**: Provider 무효화 체인 불완전
- **위반 상세**:
  `updateTodoProvider`(180번 줄)에서 투두 수정 후 아래 2개만 무효화한다:
  ```dart
  ref.invalidate(todosForDateProvider);
  ref.invalidate(eventsForMonthProvider);
  ```
  그러나 `todayTodosProvider`를 무효화하지 않는다.
  
  **비교**: 동일 파일의 다른 CRUD Provider들은 모두 `todayTodosProvider`를 무효화한다:
  - `createTodoProvider` (127번 줄): `ref.invalidate(todayTodosProvider);` -- 있음
  - `toggleTodoProvider` (150번 줄): `ref.invalidate(todayTodosProvider);` -- 있음
  - `deleteTodoProvider` (224번 줄): `ref.invalidate(todayTodosProvider);` -- 있음
  - `updateTodoProvider` (180~196번 줄): **누락**

  **영향**: 투두 제목/시간/태그/색상을 수정한 후 홈 대시보드의 "오늘의 할 일" 요약 카드가 갱신되지 않는다. 사용자가 홈 화면으로 돌아가면 수정 전 데이터가 계속 표시된다.
- **관련 파일**: `lib/features/todo/providers/todo_provider.dart:190` (eventsForMonthProvider 무효화 다음 줄에 추가 필요)
- **원래 요구사항**: 투두 변경 시 홈 대시보드가 실시간으로 갱신되어야 한다
- **수정 지시**:
  ```dart
  // 190번 줄 (ref.invalidate(eventsForMonthProvider);) 다음에 추가:
  ref.invalidate(todayTodosProvider);
  ```
- **상태**: OPEN

---

## P2 위반 사항 (다음 Phase 전 수정 필요)

### [VIOLATION-V2-004] AchievementStatsCollector가 HiveCacheService를 우회하여 Hive.box 직접 접근

- **심각도**: P2
- **발견 위치**: `lib/features/achievement/services/achievement_stats_collector.dart:56,70-71,141,151,165-166,193-194`
- **위반 유형**: 아키텍처 계층 위반 (인프라 직접 접근)
- **위반 상세**:
  프로젝트의 모든 Hive 접근은 `HiveCacheService`를 통해 이루어져야 한다 (core/cache/ 계층 분리 원칙). 그러나 `AchievementStatsCollector`는 `Hive.box<dynamic>()`를 직접 호출하여 DI 원칙과 캐시 서비스 추상화를 우회한다.
  
  ```dart
  // 현재 (직접 접근):
  final box = Hive.box<dynamic>(AppConstants.todosBox);
  
  // 권장 (DI 패턴):
  // AchievementStatsCollector.collect(cache: HiveCacheService) 형태로 주입
  ```
  
  **영향**: 
  - 테스트 시 Hive 박스 모킹이 불가능하다 (static 메서드 + 글로벌 Hive 접근).
  - 향후 저장소를 변경할 때 이 파일도 별도 수정이 필요하다.
  - 현재 기능적으로는 동작하지만, SRP/DI 원칙에 위배된다.
- **수정 지시**:
  `collect()` 메서드에 `HiveCacheService` 파라미터를 추가하고, 내부에서 `cache.getAll(boxName)` 패턴으로 변경한다. 호출부(todo_provider, habit_provider, timer_provider, goal_provider)에서 `ref.read(hiveCacheServiceProvider)`를 전달한다.
- **상태**: OPEN

---

## P3 위반 사항 (개선 권장)

### [VIOLATION-V2-005] Routine 모델의 userId 필드가 로컬 퍼스트에서 필수 값으로 처리됨

- **심각도**: P3
- **발견 위치**: `lib/features/habit/presentation/widgets/routine_list_view.dart:200-207`
- **위반 유형**: 불필요한 제약 조건
- **위반 상세**:
  `_showDialog`에서 `Routine` 객체 생성 시 `userId: userId`를 전달한다. userId null 가드(P0-002)가 수정되면 이 부분은 해결되지만, 근본적으로 Routine 모델의 `userId`가 `required`인지, 빈 문자열 허용인지 확인이 필요하다. MandalartWizard(goal)는 `AppConstants.localUserId` 폴백을 사용하고, Timer는 빈 문자열을 사용하는 등 userId 폴백 전략이 일관되지 않다.
- **수정 지시**: 
  프로젝트 전체에서 미인증 상태의 userId 폴백 값을 `AppConstants.localUserId`로 통일한다. 현재 사용되는 패턴:
  - `AppConstants.localUserId` (mandalart_wizard) 
  - `''` 빈 문자열 (timer_provider, achievement_provider)
  
  하나의 패턴으로 통일할 것을 권장한다.
- **상태**: OPEN

---

## 검증 완료 항목 (1차 수정 회귀 검증)

아래 항목들은 1차 수정이 올바르게 적용되었으며, 회귀가 발견되지 않았다.

### 1. Todo colorIndex 파싱 (정상)
- **파일**: `lib/shared/models/todo.dart:51-79`
- **검증**: `colorIndex` getter가 문자열 → int 파싱, hex → 팔레트 인덱스 매칭, RGB 거리 기반 매칭을 올바르게 수행한다.
- **결과**: PASS

### 2. Todo 생성/수정 시 색상 저장 (정상)
- **파일**: `lib/features/todo/presentation/todo_screen.dart:365`, `lib/features/todo/presentation/widgets/todo_list_view.dart`
- **검증**: `color: result.colorIndex.toString()`로 색상 인덱스를 문자열로 저장한다. 수정 시 `clearColor: true`와 함께 새 color 값을 설정한다.
- **결과**: PASS

### 3. Todo 생성/수정 시 태그 저장 (정상)
- **파일**: `lib/features/todo/presentation/todo_screen.dart:345-368`, `lib/features/todo/presentation/widgets/todo_list_view.dart`
- **검증**: tagIds를 Tag 객체 Map으로 변환하여 `tags: tagMaps`로 전달한다. 수정 시 `clearTags: true`와 함께 새 tags 값을 설정한다.
- **결과**: PASS

### 4. Achievement 언락 다이얼로그 자동 표시 (정상)
- **파일**: `lib/shared/widgets/main_shell.dart`
- **검증**: `ref.listen(pendingAchievementProvider, ...)`로 업적 달성 시 `AchievementUnlockDialog.show()`를 호출하고, 즉시 `ref.read(pendingAchievementProvider.notifier).state = null`로 초기화한다.
- **결과**: PASS

### 5. Goal 태그 UI (정상)
- **파일**: `lib/features/goal/presentation/widgets/goal_create_dialog.dart`, `lib/features/goal/presentation/widgets/goal_card.dart`
- **검증**: GoalCreateDialog에서 `TagChipSelector`가 `selectedTagIds`와 연동된다. GoalCard에서 `tagByIdProvider`로 태그 정보를 조회하여 표시한다.
- **결과**: PASS

### 6. weekSummary -> todaySummary 이름 변경 (정상)
- **파일**: 프로젝트 전체 grep 확인
- **검증**: 삭제된 파일(week_summary_section, week_stat_card)에 대한 잔존 import가 없다.
- **결과**: PASS

### 7. Habit colorIndex hex -> int 변환 (정상)
- **파일**: `lib/shared/models/habit.dart:51-79`
- **검증**: Todo와 동일한 패턴으로 hex/int 문자열을 팔레트 인덱스로 올바르게 변환한다.
- **결과**: PASS

### 8. MandalartWizard userId 폴백 (정상)
- **파일**: `lib/features/goal/presentation/widgets/mandalart_wizard.dart:74`
- **검증**: `ref.read(currentUserIdProvider) ?? AppConstants.localUserId`로 미인증 사용자도 만다라트를 생성할 수 있다.
- **결과**: PASS

### 9. Cross-Feature 무효화: 습관 체크 -> 홈 대시보드 (정상)
- **파일**: `lib/features/habit/providers/habit_provider.dart:218-223`
- **검증**: `toggleHabitProvider`에서 `todayHabitsProvider`를 무효화하여 홈 대시보드의 습관 요약이 갱신된다.
- **결과**: PASS

### 10. Cross-Feature 무효화: 투두 변경 -> 캘린더 (정상)
- **파일**: `lib/features/todo/providers/todo_provider.dart:124-127, 147-150, 221-224`
- **검증**: create/toggle/delete 모두 `eventsForMonthProvider`를 무효화하여 캘린더에 투두 변경이 반영된다.
- **결과**: PASS

### 11. Cross-Feature 무효화: 루틴 변경 -> 캘린더/홈 (정상)
- **파일**: `lib/features/habit/providers/routine_provider.dart:50-56, 68-73, 85-90, 101-107`
- **검증**: 모든 루틴 CRUD에서 `todayRoutinesProvider`, `eventsForMonthProvider`를 무효화한다.
- **결과**: PASS

### 12. Backup/Restore 태그 직렬화 (정상)
- **파일**: `lib/core/backup/backup_service.dart`
- **검증**: `tagsBox`가 백업/복원 대상에 포함되어 있다. Todo의 tags(List<Map>)와 Goal의 tag_ids(List<String>)가 Hive Map 형태로 저장되므로 getAll/put 패턴으로 올바르게 직렬/역직렬화된다.
- **결과**: PASS

### 13. 삭제된 파일 잔존 import 없음 (정상)
- **검증**: `week_summary_section`, `week_stat_card` 등 삭제된 파일에 대한 import 문이 프로젝트 전체에서 발견되지 않았다.
- **결과**: PASS

### 14. Workaround 패턴 미발견 (정상)
- **검증**: `@ts-ignore`, `@ts-expect-error`, `eslint-disable`, `noqa`, `as any` 등의 우회 패턴이 Dart 코드에서 발견되지 않았다.
- **결과**: PASS

### 15. Timer Provider userId 처리 (정상)
- **파일**: `lib/features/timer/providers/timer_provider.dart:211`
- **검증**: `_ref.read(currentUserIdProvider) ?? ''`로 미인증 사용자도 타이머 로그를 저장할 수 있다.
- **결과**: PASS

---

## 추가 엣지 케이스 분석

### Hive 데이터 타입 안전성
- **Todo.fromMap**: `is_completed`를 `as bool?`로 캐스팅하며 null일 때 `false` 기본값을 사용한다. Hive에서 동적 타입으로 저장되므로 타입 불일치 시 `TypeError`가 발생할 수 있으나 `try-catch`로 `AppException.validation`을 던진다. (정상)
- **Habit.fromMap**: 동일한 패턴으로 안전하게 처리한다. (정상)
- **Event.fromMap**: colorIndex를 `(map['colorIndex'] as num?)?.toInt() ?? 0`으로 처리한다. (정상)
- **Routine.fromMap**: days를 MON/TUE 문자열에서 ISO weekday int로 변환한다. 알 수 없는 문자열은 무시한다. (정상)

### copyWith() 필드 전파 검증
- **Todo.copyWith**: `clear*` 파라미터(clearMemo, clearColor, clearTags, clearStartTime, clearEndTime)를 제공하여 nullable 필드를 명시적으로 null로 설정할 수 있다. (정상)
- **Habit.copyWith**: 모든 필드(name, icon, color, isActive, currentStreak, longestStreak, frequency, repeatDays)를 올바르게 전파한다. (정상)
- **Routine.copyWith**: name, repeatDays, startTime, endTime, colorIndex, isActive를 올바르게 전파한다. (정상)

### 날짜/시간 엣지 케이스
- **todayTodosProvider** (home_provider.dart): `padLeft(2, '0')`으로 날짜를 포맷하여 '2026-03-09' 형태로 비교한다. 1~9월/1~9일도 올바르게 처리된다. (정상)
- **AchievementStatsCollector._formatDate**: 동일한 padLeft 패턴을 사용한다. (정상)
- **HabitLog 날짜 비교**: `DateTime(year, month, day)`로 정규화하여 시간 부분을 제거한다. (정상)

---

## 수정 우선순위 정리

| 순위 | 위반 ID | 심각도 | 요약 | 예상 작업량 |
|------|---------|--------|------|------------|
| 1 | V2-001 | P0 | AchievementStatsCollector is_archived -> is_active | 2줄 변경 |
| 2 | V2-002 | P0 | userId null 가드 -> 폴백 패턴 (6곳) | 6곳 각 1~2줄 변경 |
| 3 | V2-003 | P1 | updateTodoProvider todayTodosProvider 무효화 추가 | 1줄 추가 |
| 4 | V2-004 | P2 | AchievementStatsCollector DI 패턴으로 리팩터링 | 중간 규모 |
| 5 | V2-005 | P3 | userId 폴백 전략 통일 | 소규모 |

---

## Guardian 판정

**P0 위반 2건, P1 위반 1건이 미해결 상태이므로, 이 Phase를 완료할 수 없다.**
V2-001, V2-002, V2-003이 수정되기 전까지 다음 Phase 진행을 차단한다.
