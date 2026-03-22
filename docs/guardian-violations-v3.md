# Guardian Violations Report v3 — 심층 분석

> 분석 일자: 2026-03-13
> 분석 범위: lib/ 전체 (features/, shared/, core/)
> 분석 방법: 모델 → 리포지토리 → 프로바이더 → UI 데이터 플로우 추적 + 패턴 스캔
> 이전 보고서: guardian-violations.md (v1), guardian-violations-v2.md (v2)

---

## 요약

| 심각도 | 건수 | 설명 |
|--------|------|------|
| **P0** | 0 | 핵심 기능 누락, 보안 취약점 없음 |
| **P1** | 5 | SRP/파일 크기 위반, 뷰 모델 혼재, StateNotifier 패턴 |
| **P2** | 7 | 에러 삼킴, debugPrint, catch(_) 패턴, 중복 로직 |
| **P3** | 4 | 네이밍 개선, 경미한 구조 권장 |
| **합계** | 16 | |

---

## P1 위반 (즉시 수정 권장)

### [V3-001] P1: SRP 위반 — 파일 크기 초과 (300줄 이상) 25개 파일

**위반 유형**: SRP / 파일 크기 규칙 위반
**규칙**: 파일 최대 200줄, 컴포넌트 최대 150줄

**300줄 이상 위반 파일 (긴급)**:

| # | 파일 경로 | 줄 수 | 권장 분리 방향 |
|---|-----------|-------|---------------|
| 1 | `lib/core/theme/theme_preset_registry.dart` | 954 | 프리셋별 파일 분리 (glassmorphism.dart, minimal.dart 등) |
| 2 | `lib/core/theme/layout_tokens.dart` | 757 | 도메인별 분리 (dialog_layout.dart, icon_layout.dart, timeline_layout.dart 등) |
| 3 | `lib/features/settings/presentation/widgets/tag_management_screen.dart` | 711 | _TagListItem, _TagFormSheet, _TagManagementHeader를 독립 파일로 분리 |
| 4 | `lib/features/todo/presentation/widgets/daily_schedule_view.dart` | 697 | 통계 패널(_StatsPanel), 타임라인(_Timeline), 블록 렌더러(_BlockRenderer) 분리 |
| 5 | `lib/features/habit/presentation/widgets/habit_tracker_view.dart` | 602 | _TodayHabitsSection, 프리셋 시트 연결 로직 분리 |
| 6 | `lib/features/settings/presentation/widgets/cloud_backup_card.dart` | 510 | 백업 진행 UI(_BackupProgress), 복원 확인 다이얼로그(_RestoreConfirm) 분리 |
| 7 | `lib/features/calendar/providers/event_provider.dart` | 506 | 뷰 모델(CalendarEvent, RoutineEntry)을 별도 파일로 분리 (V3-002 참조) |
| 8 | `lib/features/goal/presentation/widgets/goal_card.dart` | 494 | 확장 콘텐츠(_ExpandedContent), 액션 버튼(_ActionButtons) 분리 |
| 9 | `lib/features/goal/presentation/widgets/sub_goal_card.dart` | 476 | 수정 다이얼로그, 태스크 리스트 섹션 분리 |
| 10 | `lib/shared/widgets/tag_chip_selector.dart` | 458 | 태그 선택 시트(_TagSelectionSheet)를 독립 파일로 분리 |
| 11 | `lib/features/calendar/presentation/widgets/event_create_dialog.dart` | 441 | 폼 검증, 날짜/시간 피커 섹션 분리 |
| 12 | `lib/features/goal/providers/goal_provider.dart` | 407 | GoalNotifier를 독립 파일(goal_notifier.dart)로 분리 |
| 13 | `lib/features/todo/presentation/widgets/todo_create_dialog.dart` | 380 | NLP 프리필 로직, 태그 섹션 분리 |
| 14 | `lib/features/todo/presentation/todo_screen.dart` | 377 | NLP 파싱 로직을 별도 헬퍼로 분리 |
| 15 | `lib/features/habit/presentation/widgets/habit_preset_sheet.dart` | 350 | 프리셋 데이터를 상수 파일로, UI를 별도 위젯으로 분리 |

**200~300줄 위반 파일 (개선 권장)**: 추가 10개 파일 존재
- `todo_item_tile.dart` (349), `goal_create_dialog.dart` (323), `event_overlap_layout.dart` (321), `daily_view.dart` (317), `settings_screen.dart` (316), `backup_service.dart` (312), `main_shell.dart` (309), `habit_provider.dart` (309), `habit_card.dart` (308), `theme_preview_card.dart` (304)

---

### [V3-002] P1: SRP 위반 — event_provider.dart에 뷰 모델 클래스 혼재

**위반 파일**: `lib/features/calendar/providers/event_provider.dart:105, :160`
**위반 내용**: CalendarEvent 뷰 모델(105줄)과 RoutineEntry 뷰 모델(160줄)이 Provider 파일 내부에 정의됨
**문제**: Provider 파일은 상태 관리 로직만 담당해야 하나, 뷰 모델 정의(데이터 구조)가 혼재되어 단일 책임 원칙 위반
**권장 수정**:
1. `lib/features/calendar/models/calendar_event.dart` 생성 → CalendarEvent 클래스 이동
2. `lib/features/calendar/models/routine_entry.dart` 생성 → RoutineEntry 클래스 이동
3. event_provider.dart에서 import하여 사용

---

### [V3-003] P1: GoalNotifier에서 Ref 직접 저장

**위반 파일**: `lib/features/goal/providers/goal_provider.dart:193`
**위반 내용**: `GoalNotifier extends StateNotifier`에서 `final Ref _ref` 필드를 직접 보관
**문제**: Riverpod 공식 문서에서 StateNotifier에 Ref를 직접 전달하는 것은 deprecated 패턴이며, Notifier/AsyncNotifier 마이그레이션이 권장됨. 현재 동작에는 문제가 없으나 향후 Riverpod 3.x에서 호환성 문제 발생 가능
**권장 수정**: Riverpod 2.6 기준 당장 필수는 아니나, 신규 Notifier에는 AsyncNotifier 패턴 사용 권장. 기존 StateNotifier는 현행 유지 가능하되, 마이그레이션 계획을 docs에 기록

---

### [V3-004] P1: TimerStateNotifier에서 Ref 직접 저장

**위반 파일**: `lib/features/timer/providers/timer_provider.dart:88`
**위반 내용**: `TimerStateNotifier extends StateNotifier`에서 `final Ref _ref` 필드를 직접 보관
**문제**: V3-003과 동일한 패턴. _ref를 통해 다수의 Provider를 read/invalidate하고 있어 의존 범위가 넓음
**권장 수정**: V3-003과 동일

---

### [V3-005] P1: AuthStateNotifier에서도 동일한 Ref 패턴

**위반 파일**: `lib/core/auth/auth_provider.dart:21-25`
**위반 내용**: AuthStateNotifier도 StateNotifier + 직접 서비스 주입 패턴
**문제**: V3-003과 동일하나 Auth는 core 영역이므로 영향 범위가 더 넓음
**권장 수정**: V3-003과 동일

---

## P2 위반 (다음 Phase 전 수정 권장)

### [V3-006] P2: debugPrint 사용 — ErrorHandler.logServiceError로 교체 필요

**위반 파일**: `lib/features/timer/providers/timer_provider.dart:244`
**위반 내용**: `debugPrint('[TimerProvider] 투두 자동완료 실패: $e');`
**문제**: 프로젝트 전체에서 ErrorHandler.logServiceError를 에러 로깅 표준으로 사용하나, 이 한 곳만 debugPrint를 사용. debugPrint는 릴리스 빌드에서도 출력되나 구조화된 로깅이 아님
**권장 수정**:
```dart
ErrorHandler.logServiceError('TimerProvider:TodoAutoComplete', e);
```

---

### [V3-007] P2: 홈 Provider에서 에러 삼킴 (catch (_) → 빈 값 반환)

**위반 파일 및 줄 번호**:
- `lib/features/home/providers/home_provider.dart:68` (todayTodosProvider)
- `lib/features/home/providers/home_provider.dart:171` (todayHabitsProvider)
- `lib/features/home/providers/home_provider.dart:229` (todayRoutinesProvider)
- `lib/features/home/providers/home_dday_provider.dart:69` (upcomingDdaysProvider)

**위반 내용**: `catch (_) { return XxxSummary.empty; }` 패턴으로 모든 에러를 삼킴
**문제**: Hive 데이터 파싱 실패, 타입 불일치, 박스 미초기화 등의 에러가 발생해도 사용자에게 빈 화면만 표시됨. 에러 원인 추적이 불가능함
**권장 수정**:
```dart
} catch (e, stack) {
  ErrorHandler.logServiceError('HomeProvider:todayTodos', e, stack);
  return TodoSummary.empty;
}
```
에러를 로깅한 후 빈 값을 반환하는 graceful degradation 패턴으로 변경

---

### [V3-008] P2: TimerRepository에서 에러 삼킴 (catch (_) → continue)

**위반 파일 및 줄 번호**:
- `lib/features/timer/services/timer_repository.dart:47` (getTodayLogs)
- `lib/features/timer/services/timer_repository.dart:73` (getLogsForPeriod)
- `lib/features/timer/services/timer_repository.dart:98` (getTotalFocusSeconds)

**위반 내용**: TimerLog.fromMap 파싱 실패 시 `catch (_) { continue; }`로 삼김
**문제**: 손상된 데이터가 무시되어 사용자에게 집중 시간이 실제보다 적게 표시될 수 있음. 파싱 실패 원인 추적 불가
**권장 수정**: 최소한 ErrorHandler.logServiceError로 로깅 추가. 빈번한 파싱 실패는 데이터 마이그레이션 문제를 시사할 수 있음

---

### [V3-009] P2: 모델 fromMap에서 TypeError catch 후 AppException 변환 — stack trace 누락

**위반 파일**:
- `lib/shared/models/goal.dart:82`
- `lib/shared/models/routine.dart:196`
- `lib/shared/models/sub_goal.dart:52`
- `lib/shared/models/todo.dart:131`
- `lib/shared/models/habit_log.dart:46`
- `lib/shared/models/event.dart:174`
- `lib/shared/models/goal_task.dart:52`
- `lib/shared/models/tag.dart:51`
- `lib/shared/models/habit.dart:151`
- `lib/shared/models/user_profile.dart:62`
- `lib/features/timer/models/timer_log.dart:124`
- `lib/features/achievement/models/achievement.dart:61`

**위반 내용**: `} on TypeError catch (e) {` 패턴에서 stack trace를 캡처하지 않음
**문제**: AppException.validation으로 변환 시 원본 stack trace가 소실됨. 프로덕션에서 파싱 에러 발생 위치 추적이 어려움
**권장 수정**:
```dart
} on TypeError catch (e, stack) {
  ErrorHandler.logServiceError('Goal.fromMap', e, stack);
  throw AppException.validation(...);
}
```

---

### [V3-010] P2: 투두 삭제 시 타이머 로그 정리 로직 중복

**위반 파일**:
- `lib/features/todo/providers/todo_provider.dart:208-218` (deleteTodoProvider 내부)
- `lib/features/timer/services/timer_repository.dart:114-125` (deleteLogsByTodoId 메서드)

**위반 내용**: todo_provider.dart의 deleteTodoProvider가 타이머 로그를 직접 HiveCacheService로 정리하는 로직을 인라인으로 구현함. 동일한 로직이 TimerRepository.deleteLogsByTodoId에 이미 존재
**문제**: 투두 삭제 시 고아 타이머 로그 정리는 TimerRepository에 위임해야 하나, Provider에서 cache를 직접 조작하여 Repository 계층을 우회함. 로직이 두 곳에 존재하여 향후 변경 시 불일치 위험
**권장 수정**: deleteTodoProvider에서 직접 cache를 조작하지 말고 TimerRepository.deleteLogsByTodoId를 호출

---

### [V3-011] P2: 습관 삭제 시 로그 정리 로직이 Provider에 인라인

**위반 파일**: `lib/features/habit/providers/habit_provider.dart:279-289` (deleteHabitProvider 내부)
**위반 내용**: HabitRepository.deleteHabit 내부에서도 고아 로그를 정리하는 로직이 있을 수 있으나, Provider에서 cache를 직접 조작하여 별도로 로그 정리를 수행
**문제**: V3-010과 동일한 패턴 — Repository 계층 우회
**권장 수정**: HabitLogRepository에 deleteLogsByHabitId 메서드를 추가하고 Provider에서는 해당 메서드를 호출

---

### [V3-012] P2: main.dart에서 에러 삼킴

**위반 파일**: `lib/main.dart:65, :73`
**위반 내용**: AdMob 초기화 및 광고 프리로드 실패 시 `catch (_) {}` 로 완전 삼김
**문제**: 광고 수익이 비즈니스 모델의 핵심이므로 광고 초기화 실패는 최소한 로깅되어야 함
**권장 수정**: ErrorHandler.logServiceError로 로깅 추가

---

## P3 위반 (개선 권장, 배치 처리 가능)

### [V3-013] P3: Event.toInsertMap/toUpdateMap에서 endDate 조건부 포함

**위반 파일**: `lib/shared/models/event.dart:189, :207`
**위반 내용**: `if (endDate != null) 'end_date': DateParser.toIso8601(endDate!)` 패턴
**분석 결과**: EventRepository.updateEvent는 `_cache.put`(전체 덮어쓰기)을 사용하므로 실제로는 문제가 없음 — endDate가 null이면 key가 누락되고, put은 전체 교체이므로 이전 값이 남지 않음
**권장 개선**: 의도가 명확하도록 `'end_date': endDate != null ? DateParser.toIso8601(endDate!) : null` 형식으로 항상 key를 포함시키되 값을 null로 설정하는 것이 더 명시적임. 현재 동작에는 문제 없음

---

### [V3-014] P3: Routine 모델의 fromMap에서 catch(_) 사용

**위반 파일**: `lib/shared/models/routine.dart:97`
**위반 내용**: `catch (_) { return 0; }` — 시간 파싱 실패 시 0을 반환
**문제**: 경미함. 시간 문자열 파싱 실패 시 0:00으로 표시됨. 로깅은 권장되나 UX 영향은 제한적

---

### [V3-015] P3: tag_provider.dart에서 firstWhere 대신 try-catch

**위반 파일**: `lib/shared/providers/tag_provider.dart:53`
**위반 내용**: `tags.firstWhere((t) => t.id == tagId)` 실패를 catch로 처리
**권장 개선**: Dart의 `firstWhereOrNull` 확장 사용이 더 관용적
```dart
return tags.cast<Tag?>().firstWhere((t) => t?.id == tagId, orElse: () => null);
```

---

### [V3-016] P3: auth_service.dart, auth_provider.dart에서 catch(_) 사용

**위반 파일**:
- `lib/core/auth/auth_service.dart:109`
- `lib/core/auth/auth_provider.dart:52`
**위반 내용**: Google Sign-In 관련 에러를 catch(_)로 삼김
**문제**: 인증 실패 원인 추적 어려움. 사용자에게 "로그인 실패" 만 표시되고 원인(네트워크, 토큰 만료, 사용자 취소 등) 구분 불가
**권장 수정**: ErrorHandler.logServiceError로 로깅 추가

---

## 데이터 플로우 검증 결과

### 1. Todo 데이터 플로우 (정상)
```
Todo.fromMap (snake_case + camelCase 폴백)
  → TodoRepository (HiveCacheService DI)
    → todosForDateProvider (selectedDateProvider watch)
      → sortedTodosProvider → filteredTodosProvider
        → TodoListView / DailyScheduleView (UI)

CRUD 무효화 체인:
  create/update/delete → todosForDateProvider + eventsForMonthProvider + todayTodosProvider
  delete → + todayTimerLogsProvider (타이머 로그 연쇄 정리)
  toggle → + achievement check (AchievementStatsCollector)
```
**결과**: 정상. 모든 CRUD에서 관련 Provider가 올바르게 무효화됨.

### 2. Event 데이터 플로우 (정상)
```
Event.fromMap (snake_case + camelCase 폴백)
  → EventRepository (HiveCacheService DI)
    → eventsForMonthProvider (반복 이벤트 RRULE 확장 포함)
      → CalendarEvent 뷰 모델 변환
        → MonthlyView / WeeklyView / DailyView (UI)

CRUD 무효화 체인:
  create/update/delete → eventsForMonthProvider + upcomingDdaysProvider
```
**결과**: 정상. 반복 이벤트 확장 로직도 월 범위 내에서 올바르게 동작.

### 3. Habit 데이터 플로우 (정상)
```
Habit.fromMap → HabitRepository → activeHabitsProvider
HabitLog.fromMap → HabitLogRepository → habitLogsForDateProvider / habitLogsForMonthProvider
  → todayScheduledHabitsProvider (빈도 기반 필터링)
    → todayHabitCompletionRateProvider (달성률 계산)
      → HabitTrackerView (UI)
  → streakForHabitProvider (StreakCalculator)
    → HabitCard (스트릭 배지)
  → habitCalendarDataProvider (날짜별 달성률 맵)
    → HabitCalendarSection (UI)
```
**결과**: 정상. 빈도(daily/weekly/custom) 기반 필터링과 스트릭 계산이 올바르게 연결됨.

### 4. Timer 데이터 플로우 (정상, P2 주의)
```
TimerLog.fromMap (snake_case + camelCase 폴백)
  → TimerRepository (camelCase 키로 Hive 저장)
    → todayTimerLogsProvider (날짜별 필터링)
      → todayFocusMinutesProvider (분 단위 변환)
        → TimerSessionInfo / TimerLogList (UI)
    → todoFocusMinutesProvider (투두별 집중 시간)
      → TodoItemTile (투두에 표시)

타이머 완료 시:
  → _saveLog → repository.createLog
    → todayTimerLogsProvider 무효화
    → toggleTodoProvider (연결 투두 자동 완료)
    → AchievementStatsCollector.collect → 업적 체크
```
**결과**: 기능적으로 정상. 단, TimerRepository는 camelCase로 저장하고 fromMap은 양쪽을 읽으므로 백업/복원 시 키 포맷 불일치 주의 필요 (현재는 복원 시 원본 포맷 유지하므로 문제 없음).

### 5. Goal → SubGoal → GoalTask 데이터 플로우 (정상)
```
Goal.fromMap → GoalRepository → goalsStreamProvider
SubGoal.fromMap → SubGoalRepository → subGoalsStreamProvider(goalId)
GoalTask.fromMap → TaskRepository → tasksByGoalStreamProvider(goalId)
  → GoalNotifier (cascade CRUD)
    → ProgressCalculator (진행률 계산)
      → GoalCard → SubGoalCard → GoalTaskItem (UI)
  → MandalartProvider (Goal + SubGoal + GoalTask 결합)
    → MandalartGrid (UI)
```
**결과**: 정상. cascade 삭제(goal → subgoals → tasks)와 무효화 체인이 올바르게 구현됨.

### 6. Tag 데이터 플로우 (정상)
```
Tag.fromMap → TagRepository → userTagsProvider
  → tagByIdProvider(tagId) (단건 조회)
  → selectedTagFilterProvider (필터 상태)
    → filteredTodosProvider (태그 필터링 적용)

삭제 시 고아 정리:
  deleteTagProvider → todosBox orphan tagId 정리 + goalsBox orphan tagId 정리
    → selectedTagFilterProvider에서 삭제된 태그 제거
```
**결과**: 정상. 고아 태그 정리와 필터 상태 동기화가 올바르게 구현됨.

### 7. Home Dashboard 데이터 플로우 (정상, P2 주의)
```
todayTodosProvider → Hive todosBox 직접 조회 → TodoSummary
todayHabitsProvider → Hive habitsBox + habitLogsBox 직접 조회 → HabitSummary
todayRoutinesProvider → Hive routinesBox 직접 조회 → RoutineSummary
upcomingDdaysProvider → Hive eventsBox 직접 조회 → DDay 목록
```
**결과**: 기능적으로 정상. 단, 모든 Provider에서 catch(_) 패턴으로 에러를 삼키고 있어 디버깅 어려움 (V3-007 참조).

---

## DI 원칙 준수 검증

| 검증 항목 | 결과 | 비고 |
|-----------|------|------|
| Hive.box 직접 접근 (core/ 외부) | PASS | core/cache/ 내부에서만 Hive.box 사용 확인 |
| HiveCacheService DI 주입 | PASS | 모든 Repository가 생성자 주입 사용 |
| AchievementStatsCollector DI | PASS | HiveCacheService를 파라미터로 주입받음 (이전 v2에서 수정 완료) |
| Feature 간 직접 참조 | PASS | Provider를 통한 간접 참조 사용 |

---

## Workaround 패턴 스캔 결과

| 패턴 | 검출 수 | 상태 |
|-------|---------|------|
| `@ts-ignore` / `@ts-expect-error` | 0 | PASS (Dart 프로젝트이므로 해당 없음) |
| `eslint-disable` / `noqa` | 0 | PASS |
| `as dynamic` / `// ignore:` | 0 | PASS |
| `!important` | 0 | PASS |
| `debugPrint` / `print()` | 1 | V3-006에 기록 |
| 순수 무채색 (#000000 등) | 0 | PASS (color_tokens.dart에 #000000 언급은 주석에서 "대신 Tinted Grey 사용" 설명) |

---

## 이전 수정사항(v1, v2) 회귀 검증

| 이전 위반 | 현재 상태 | 비고 |
|-----------|----------|------|
| AchievementStatsCollector 직접 Hive.box 접근 | **수정 완료** | HiveCacheService DI 주입으로 전환됨 |
| Todo toggleTodoProvider 업적 체크 누락 | **수정 완료** | AchievementStatsCollector.collect 호출 확인 |
| Habit toggleHabitProvider 업적 체크 누락 | **수정 완료** | AchievementStatsCollector.collect 호출 확인 |
| Timer _saveLog 업적 체크 누락 | **수정 완료** | AchievementStatsCollector.collect 호출 확인 |
| Goal toggleGoalCompletion 업적 체크 누락 | **수정 완료** | AchievementStatsCollector.collect 호출 확인 |
| Home dashboard Provider 무효화 누락 | **수정 완료** | todayTodosProvider, todayHabitsProvider 무효화 확인 |
| deleteTodoProvider 타이머 로그 정리 누락 | **수정 완료** | timerLogsBox 고아 로그 정리 + todayTimerLogsProvider 무효화 확인 |
| deleteHabitProvider 고아 로그 정리 누락 | **수정 완료** | habitLogsBox 고아 로그 정리 + Provider 무효화 확인 |
| deleteTagProvider 고아 태그 참조 정리 누락 | **수정 완료** | todosBox + goalsBox 양쪽 고아 정리 확인 |
| Routine CRUD eventsForMonthProvider 무효화 누락 | **수정 완료** | routineNotifierProvider에서 무효화 확인 |

---

## 수정 우선순위 로드맵

### 즉시 (P1)
1. **V3-001**: 300줄 초과 파일 최소 상위 5개(theme_preset_registry, layout_tokens, tag_management_screen, daily_schedule_view, habit_tracker_view) 분리
2. **V3-002**: CalendarEvent, RoutineEntry를 별도 모델 파일로 이동

### 단기 (P2)
3. **V3-006**: debugPrint → ErrorHandler.logServiceError 교체
4. **V3-007, V3-008, V3-012**: catch(_) 패턴에 ErrorHandler 로깅 추가
5. **V3-009**: fromMap catch 블록에 stack trace 캡처 추가
6. **V3-010, V3-011**: 고아 정리 로직을 Repository 계층으로 이동

### 장기 (P3)
7. **V3-013~V3-016**: 코드 스타일 개선 사항 일괄 적용
8. **V3-003~V3-005**: StateNotifier → AsyncNotifier 마이그레이션 계획 수립 (Riverpod 3.x 대비)
