# Guardian Requirements Log

## User Original Requirements (전문)

### 요구사항 전체 목록
1. 기존 모든 기능 (5탭, 서브탭, 기능) 100% 유지
2. 테마 6개→3개 축소: 기본(Refined Glass), 깔끔함(Clean Minimal), 다크(Dark Glass)
3. Refined Glass 디자인 적용 (밝은 배경 + 미묘한 글라스 효과)
4. 캘린더 탭: 동적 리사이즈 드래그 핸들 (30%~70%), 루틴 편집 다이얼로그, 루틴 완료 체크박스
5. RoutineLog 모델 생성 (루틴 일별 완료 기록)
6. 투두 탭: 서브탭 2→3 (일정표/주간루틴/할일), RoutineWeeklyView 신규, 카테고리 그룹화
7. 습관/목표 서브탭 → SegmentedControl 통일
8. 전체 화면 디자인 리파인

## Current Phase: Implementation (Chunk 1-6, 16 Tasks)
## Phase Goal: 16개 태스크를 순차 구현하여 기능 확장 + 디자인 리파인 완료
## Active Agents: implementer subagents (sequential), spec-reviewer, code-quality-reviewer

## Critical Requirements (즉시 개입 — 위반 시 P0)
- [CRITICAL] 기존 기능 100% 유지 필수 — 기능 삭제/변경 금지
- [CRITICAL] 5탭 구조 유지 (홈/캘린더/투두/습관/목표 + 풀스크린 라우트)
- [CRITICAL] HabitLog 패턴을 따라 RoutineLog 구현 (toInsertMap에 'id' 제외)
- [CRITICAL] ThemePreset 마이그레이션: 기존 Hive 저장 문자열 → 신규 enum 매핑 필수
- [CRITICAL] 한국어 주석 필수, Co-Authored-By 금지
- [CRITICAL] 우회(workaround) 금지

## Standard Requirements (Phase 완료 전 확인)
- SRP 기반 모듈 설계 준수 (파일 200줄, 컴포넌트 150줄 max)
- 순환 참조 금지
- 300줄 초과 단일 파일 금지
- routineLogsBox Hive 암호화 박스 등록
- BackupService에 routineLogsBox 포함
- 투두 서브탭 정확히 3개: 일정표 / 주간 루틴 / 할 일
- 캘린더 드래그 핸들: 30%~70% 리사이즈
- 습관/목표 서브탭 → SegmentedControl 위젯 교체
- 설정 화면 3테마 프리뷰

## 프로젝트 컨텍스트
- Flutter 3.29 (Dart) — Android + iOS + macOS 타겟
- 로컬 저장소: Hive (AES-256 암호화)
- 상태관리: Riverpod 2.6 + GoRouter 14.x
- 인증: google_sign_in (선택적, 백업용)
- 광고: Google AdMob

## 구현 상태 추적

### Chunk 1: Foundation (RoutineLog + 데이터 스토어)
- [ ] Task 1: RoutineLog 모델 생성
- [ ] Task 2: Hive 박스 + 데이터 스토어 등록
- [ ] Task 3: RoutineLog Provider 체인

### Chunk 2: Theme System (6개→3개 축소)
- [ ] Task 4: ThemePreset enum 축소
- [ ] Task 5: ThemePresetRegistry 3개 프리셋 재정의
- [ ] Task 6: 테마 마이그레이션 (global_providers.dart)
- [ ] Task 7: ColorTokens + 설정 화면 정리

### Chunk 3: Shared Widget (SegmentedControl)
- [ ] Task 8: 공유 SegmentedControl 위젯

### Chunk 4: Calendar (드래그 핸들 + 루틴 편집/완료)
- [ ] Task 9: MonthlyView 드래그 핸들 리사이즈
- [ ] Task 10: 루틴 편집 다이얼로그
- [ ] Task 11: 루틴 완료 체크박스

### Chunk 5: Todo Tab (3서브탭 확장)
- [ ] Task 12: TodoSubTab enum + todo_screen.dart 3서브탭
- [ ] Task 13: RoutineWeeklyView 생성
- [ ] Task 14: TodoListView 카테고리 그룹화

### Chunk 6: Screen Integration (서브탭 교체 + 정리)
- [ ] Task 15: 습관/목표 탭 서브탭 → SegmentedControl 교체
- [ ] Task 16: 최종 빌드 검증 + 정리
