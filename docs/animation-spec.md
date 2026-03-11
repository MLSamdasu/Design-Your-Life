# Design Your Life - 애니메이션 사양서

> Design Team Motion Specialist 최종 사양
> 작성일: 2026-03-09
> 대상: Flutter Web + Android (단일 코드베이스)

---

## 1. 글로벌 애니메이션 원칙

### 1.1 핵심 규칙

| 원칙 | 설명 |
|------|------|
| 목적 기반 | 모든 애니메이션은 "상태 안내", "주의 유도", "피드백 제공" 중 하나의 명확한 목적을 가진다 |
| 60fps 보장 | 프레임 드롭 없이 부드럽게 동작한다. GPU 가속이 필요한 속성(`transform`, `opacity`)만 애니메이션한다 |
| 300ms 중심 | 대부분의 UI 전환은 200~400ms 범위에서 완료한다. 500ms 초과는 예외적 경우(차트 빌드업)만 허용한다 |
| 선형 금지 | `Curves.linear`를 사용하지 않는다(시머 효과 제외). 자연스러운 가감속을 적용한다 |
| Reduced Motion | `MediaQuery.disableAnimations`가 true이면 모든 Duration을 0ms로 설정한다 |

### 1.2 기본 이징 커브

| 커브 | Flutter Curve | 용도 |
|------|-------------|------|
| Standard Enter | `Curves.easeOutCubic` | 화면에 나타나는 요소 (fade-in, slide-in, scale-in) |
| Standard Exit | `Curves.easeInCubic` | 화면에서 사라지는 요소 (fade-out, slide-out) |
| Standard Move | `Curves.easeInOutCubic` | 위치 이동, 크기 변화, 도넛 차트 sweep |
| Bounce | `Curves.easeOutBack` | 완료 체크, 성공 피드백 등 강조 효과 |
| Spring | `SpringSimulation` / `BouncingScrollPhysics` | 물리 기반 스크롤, 드래그 해제 |

### 1.3 성능 예산

| 항목 | 제한 값 | 근거 |
|------|---------|------|
| 동시 애니메이션 최대 수 | 3개 | GPU 레이어 과부하 방지 |
| BackdropFilter 동시 렌더링 | 화면에 최대 5개 | Flutter Web CanvasKit 성능 한계 |
| 단일 애니메이션 최대 Duration | 1000ms | 시머 효과(1500ms)만 예외 |
| Staggered 딜레이 합계 | 400ms | 마지막 카드까지 대기 시간 제한 |
| AnimationController dispose | 필수 | 메모리 누수 방지 |

### 1.4 Reduced Motion 구현 패턴

```dart
/// 접근성 모션 감소 설정을 확인하는 유틸리티
extension AnimationContext on BuildContext {
  /// 사용자가 모션 감소를 요청했는지 확인한다
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// 모션 감소 시 Duration을 0으로 반환한다
  Duration animDuration(Duration normal) =>
    reduceMotion ? Duration.zero : normal;
}
```

---

## 2. 상세 애니메이션 사양

### AN-01: 페이지 전환 (탭 전환)

**목적**: 탭 전환 시 콘텐츠가 자연스럽게 교체됨을 시각적으로 안내한다.

| 속성 | 값 |
|------|------|
| 유형 | Fade + 미세 수직 이동 (Slide-up) |
| Duration | 250ms |
| Easing | `Curves.easeOutCubic` |
| Fade | opacity 0.0 -> 1.0 |
| Slide | translateY 8px -> 0px |
| 연속 전환 처리 | 이전 애니메이션 즉시 완료(forward) 후 새 전환 시작 |
| Flutter 구현 | `FadeTransition` + `SlideTransition` in `StatefulShellRoute` |

```dart
// GoRouter StatefulShellRoute에서 커스텀 페이지 전환
CustomTransitionPage(
  child: child,
  transitionDuration: const Duration(milliseconds: 250),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02), // 8px / 400px 근사값
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  },
);
```

**비평 결과**: 수직 이동 거리를 8px(약 2%)로 제한한다. 더 큰 이동은 탭 전환에 불필요한 시각적 무게를 추가한다. 수평 슬라이드는 페이지 전환과 혼동될 수 있어 사용하지 않는다.

---

### AN-02: 카드 등장 (Staggered)

**목적**: 화면 진입 시 카드들이 순차적으로 나타나 콘텐츠 로딩 완료를 시각적으로 전달한다.

| 속성 | 값 |
|------|------|
| 유형 | Staggered Fade-in + Slide-up |
| 개별 카드 Duration | 350ms |
| 카드 간 딜레이 | 50ms |
| Easing | `Curves.easeOutCubic` |
| Fade | opacity 0.0 -> 1.0 |
| Slide | translateY 20px -> 0px |
| 최대 카드 수 | 8개 (총 딜레이 합계 350ms) |
| Flutter 구현 | `AnimationController` + `Interval` per card |

```dart
/// Staggered 카드 애니메이션 컨트롤러
class StaggeredCardAnimation {
  final AnimationController controller;
  final int index;
  final int totalCards;

  /// 각 카드의 애니메이션 시작/종료 비율을 계산한다
  Animation<double> get opacity {
    final start = (index * 0.05).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Animation<Offset> get slideUp {
    final start = (index * 0.05).clamp(0.0, 0.6);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }
}
```

**비평 결과**: 최초 진입 시에만 Staggered 애니메이션을 적용한다. 탭 재방문 시에는 단순 Fade-in(250ms)만 적용하여 반복 사용 시 지연감을 제거한다.

---

### AN-03: 도넛 차트 애니메이션

**목적**: 완료율/달성률 수치가 점진적으로 채워지며 진행 상황을 직관적으로 전달한다.

| 속성 | 값 |
|------|------|
| 유형 | Sweep (strokeDasharray 변화) |
| Duration | 800ms |
| Easing | `Curves.easeInOutCubic` |
| 시작 값 | 0% (strokeDasharray: 0, circumference) |
| 종료 값 | 목표 퍼센트 |
| 중앙 텍스트 | 0% -> 목표% 동시 카운팅 |
| 카운팅 Duration | 800ms (차트와 동기화) |
| Flutter 구현 | `AnimatedBuilder` + `fl_chart` PieChartData.animate |

```dart
/// 도넛 차트 애니메이션
class DonutChartAnimation extends StatefulWidget {
  final double targetPercentage;

  @override
  State<DonutChartAnimation> createState() => _DonutChartAnimationState();
}

class _DonutChartAnimationState extends State<DonutChartAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.targetPercentage,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ... build에서 _animation.value로 차트와 텍스트를 동시 갱신한다
}
```

**비평 결과**: 800ms는 차트 빌드업에 적절한 길이다. 다만 화면에 도넛 차트가 2개(투두 + 습관) 동시에 보일 때, 두 차트의 시작 시점을 100ms 간격으로 Stagger하여 동시 시작의 인공적 느낌을 피한다.

---

### AN-04: 체크박스/습관 완료 애니메이션

**목적**: 항목 완료 시 만족감을 주는 촉감적(tactile) 피드백을 제공한다.

| 속성 | 값 |
|------|------|
| 유형 | Scale Bounce + 체크마크 Draw |
| Duration | 300ms |
| Easing | `Curves.easeOutBack` (overshoot 1.3) |
| Scale 시퀀스 | 1.0 -> 0.85 -> 1.15 -> 1.0 |
| 체크마크 | Stroke draw animation (path 0% -> 100%) |
| 완료 텍스트 | opacity 1.0 -> 0.5 + strikethrough 추가 |
| 텍스트 전환 Duration | 200ms (체크 이후) |
| Flutter 구현 | `AnimatedScale` + `CustomPainter` for checkmark |

```dart
/// 체크박스 완료 애니메이션
/// Scale: 1.0 -> 0.85 (50ms) -> 1.15 (100ms) -> 1.0 (150ms)
class CheckboxBounce extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: isChecked ? 1 : 0),
        duration: context.animDuration(
          const Duration(milliseconds: 300),
        ),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final scale = 1.0 + (value > 0.5 ? (1 - value) * 0.3 : -value * 0.15);
          return Transform.scale(
            scale: scale,
            child: _buildCheckbox(value),
          );
        },
      ),
    );
  }
}
```

**비평 결과**: 300ms 이내로 빠르게 완료하여, 연속 체크(5개 습관을 빠르게 탭) 시에도 자연스럽게 작동한다. Scale overshoot을 1.15로 제한하여 과도한 bounce를 방지한다.

---

### AN-05: Bottom Nav 탭 전환

**목적**: 현재 활성 탭을 시각적으로 명확히 표시하고, 탭 전환을 부드럽게 안내한다.

| 속성 | 값 |
|------|------|
| 유형 | Active Pill Width 변화 + Icon Opacity 전환 |
| Duration | 250ms |
| Easing | `Curves.easeInOutCubic` |
| Active Pill | 배경 rgba(255,255,255,0.25) fade-in + 너비 확장 (라벨 표시) |
| Icon Opacity | Inactive 0.45 -> Active 1.0 |
| Label | Inactive 숨김 -> Active 표시 (fade + slide) |
| Flutter 구현 | `AnimatedContainer` + `AnimatedOpacity` |

```dart
/// Bottom Nav Item 애니메이션
AnimatedContainer(
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeInOutCubic,
  padding: EdgeInsets.symmetric(
    horizontal: isActive ? 14 : 10,
    vertical: 6,
  ),
  decoration: BoxDecoration(
    color: isActive
      ? Colors.white.withValues(alpha: 0.25)
      : Colors.transparent,
    borderRadius: BorderRadius.circular(100),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Icon(icon, size: 20),
      ),
      if (isActive) ...[
        const SizedBox(width: 5),
        AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(label, style: captionLgBold),
        ),
      ],
    ],
  ),
);
```

---

### AN-06: 모달/다이얼로그 열기/닫기

**목적**: 모달이 배경 위로 떠오르는 물리적 인상을 부여하고, 컨텍스트 전환을 명확히 한다.

#### 열기 (Enter)

| 속성 | 값 |
|------|------|
| Duration | 250ms |
| Easing | `Curves.easeOutCubic` |
| Scale | 0.9 -> 1.0 |
| Opacity | 0.0 -> 1.0 |
| Scrim | opacity 0.0 -> 0.4 (동시) |

#### 닫기 (Exit)

| 속성 | 값 |
|------|------|
| Duration | 200ms |
| Easing | `Curves.easeInCubic` |
| Scale | 1.0 -> 0.95 |
| Opacity | 1.0 -> 0.0 |
| Scrim | opacity 0.4 -> 0.0 (동시) |

```dart
/// 모달 표시 유틸리티
Future<T?> showGlassModal<T>(BuildContext context, Widget child) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => child,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0)
          .animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
  );
}
```

**비평 결과**: 닫기 애니메이션(200ms)이 열기(250ms)보다 짧다. 사용자가 "닫기"를 의도한 순간에 빠르게 반응하여 대기감을 줄인다.

---

### AN-07: 리스트 아이템 추가

**목적**: 새로 추가된 항목이 어디에 삽입되었는지 시각적으로 안내한다.

| 속성 | 값 |
|------|------|
| 유형 | Slide-down + Fade-in |
| Duration | 300ms |
| Easing | `Curves.easeOutCubic` |
| Slide | 삽입 위치에서 아래로 밀림 (기존 아이템들이 아래로 이동) |
| 새 아이템 | opacity 0 -> 1, translateY -10px -> 0px |
| Flutter 구현 | `AnimatedList` + `SlideTransition` |

```dart
/// AnimatedList 삽입 빌더
Widget _buildInsertAnimation(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) {
  final slideAnimation = Tween<Offset>(
    begin: const Offset(0, -0.3),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  ));

  return SizeTransition(
    sizeFactor: animation,
    child: SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
  );
}
```

---

### AN-08: 리스트 아이템 제거

**목적**: 제거되는 항목이 화면에서 사라짐을 명확히 전달한다.

| 속성 | 값 |
|------|------|
| 유형 | Slide-left + Fade-out |
| Duration | 250ms |
| Easing | `Curves.easeInCubic` |
| Slide | translateX 0 -> -50px |
| Opacity | 1.0 -> 0.0 |
| 높이 축소 | SizeTransition으로 빈 공간 제거 |
| Flutter 구현 | `AnimatedList.removeItem` + `SlideTransition` |

```dart
/// AnimatedList 제거 빌더
Widget _buildRemoveAnimation(
  BuildContext context,
  Animation<double> animation,
  Widget child,
) {
  final slideAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-0.3, 0),
  ).animate(CurvedAnimation(
    parent: animation,
    curve: Curves.easeInCubic,
  ));

  return SizeTransition(
    sizeFactor: animation,
    child: SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    ),
  );
}
```

---

### AN-09: 캘린더 뷰 전환 (월간/주간/일간)

**목적**: 캘린더 뷰 변경 시 콘텐츠가 부드럽게 교체됨을 전달한다.

| 속성 | 값 |
|------|------|
| 유형 | CrossFade |
| Duration | 300ms |
| Easing | `Curves.easeInOutCubic` |
| Flutter 구현 | `AnimatedCrossFade` 또는 `AnimatedSwitcher` |

```dart
/// 캘린더 뷰 전환
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  switchInCurve: Curves.easeOutCubic,
  switchOutCurve: Curves.easeInCubic,
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
  child: _buildCalendarView(currentViewType),
);
```

**비평 결과**: 캘린더 뷰 전환에 수평 슬라이드를 사용하면 월->주->일의 계층 관계를 오해할 수 있다. 단순 CrossFade가 뷰 타입 전환에 가장 중립적이다.

---

### AN-10: D-day 수평 스크롤 스냅

**목적**: D-day 카드를 자연스러운 물리 기반 스크롤로 탐색한다.

| 속성 | 값 |
|------|------|
| 유형 | Physics-based Scroll |
| 물리 | `ClampingScrollPhysics` (Android 기본) |
| 스냅 | 카드 너비(140px) + 간격(12px) 단위 스냅 |
| 오버스크롤 | Glow 효과 (Android), Bounce (iOS) |
| Flutter 구현 | `ListView.builder` + `PageSnapping` 또는 `FixedExtentScrollController` |

```dart
/// D-day 수평 스크롤
ListView.builder(
  scrollDirection: Axis.horizontal,
  physics: const BouncingScrollPhysics(),
  padding: const EdgeInsets.symmetric(horizontal: 20),
  itemCount: ddayItems.length,
  itemBuilder: (context, index) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: DdayCard(item: ddayItems[index]),
    );
  },
);
```

---

### AN-11: 만다라트 그리드 줌

**목적**: 만다라트 전체 뷰에서 특정 세부목표 영역으로 포커스 전환을 시각적으로 안내한다.

| 속성 | 값 |
|------|------|
| 유형 | Scale + Fade |
| Duration | 400ms |
| Easing | `Curves.easeOutCubic` |
| 줌 인 | 전체 뷰(9x9) -> 세부 뷰(3x3), scale 1.0 -> 3.0, 선택 영역 중심 |
| 줌 아웃 | 세부 뷰 -> 전체 뷰, scale 3.0 -> 1.0 |
| 비선택 영역 | opacity 1.0 -> 0.3 (줌 인 시) |
| Flutter 구현 | `AnimatedScale` + `AnimatedOpacity` + `InteractiveViewer` |

```dart
/// 만다라트 줌 전환
AnimatedScale(
  scale: isZoomed ? 3.0 : 1.0,
  alignment: _selectedCellAlignment,
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeOutCubic,
  child: MandalartGridView(
    cells: cells,
    focusedSection: isZoomed ? selectedSection : null,
  ),
);
```

**비평 결과**: 400ms는 줌 전환에 적절하다. 9x9 그리드에서 3x3으로의 전환은 충분한 시간을 주어 사용자가 공간적 맥락을 잃지 않도록 한다.

---

### AN-12: 스트릭 카운터 증가

**목적**: 연속 달성 일수 증가를 축하하는 시각적 피드백을 제공한다.

| 속성 | 값 |
|------|------|
| 유형 | Counting Up + Scale Pulse |
| 숫자 카운팅 | 이전 값 -> 새 값 (예: 6 -> 7) |
| Counting Duration | 600ms |
| Easing | `Curves.easeOutCubic` |
| Scale Pulse | 1.0 -> 1.2 -> 1.0 (카운팅 완료 시점) |
| Pulse Duration | 200ms |
| Flutter 구현 | `TweenAnimationBuilder<int>` + `AnimatedScale` |

```dart
/// 스트릭 카운터 애니메이션
TweenAnimationBuilder<int>(
  tween: IntTween(begin: previousStreak, end: currentStreak),
  duration: const Duration(milliseconds: 600),
  curve: Curves.easeOutCubic,
  builder: (context, value, child) {
    return Text(
      '$value일 연속',
      style: captionLgStyle,
    );
  },
);
```

---

### AN-13: 빈 상태 -> 콘텐츠 전환

**목적**: 데이터가 로딩되거나 첫 항목이 추가될 때 빈 상태에서 콘텐츠로의 자연스러운 전환을 제공한다.

| 속성 | 값 |
|------|------|
| 유형 | CrossFade (Fade 전환) |
| Duration | 300ms |
| Easing | `Curves.easeInOutCubic` |
| 빈 상태 퇴장 | opacity 1.0 -> 0.0 |
| 콘텐츠 등장 | opacity 0.0 -> 1.0 (동시) |
| Flutter 구현 | `AnimatedSwitcher` with key change |

```dart
/// 빈 상태 <-> 콘텐츠 전환
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  switchInCurve: Curves.easeOutCubic,
  switchOutCurve: Curves.easeInCubic,
  child: items.isEmpty
    ? EmptyStateWidget(key: const ValueKey('empty'))
    : ContentListWidget(key: const ValueKey('content'), items: items),
);
```

---

### AN-14: 로딩 스켈레톤 시머

**목적**: 데이터 로딩 중 콘텐츠 영역의 형태를 미리 보여주어 인지적 대기 시간을 줄인다.

| 속성 | 값 |
|------|------|
| 유형 | Gradient Sweep (좌->우 반복) |
| Duration | 1500ms (1회 sweep) |
| 반복 | 무한 반복 |
| Easing | `Curves.linear` (예외 허용: 시머는 균일한 속도가 자연스럽다) |
| 기본 색상 | `rgba(255, 255, 255, 0.06)` |
| 하이라이트 색상 | `rgba(255, 255, 255, 0.15)` |
| Gradient 폭 | 전체 너비의 40% |
| Border Radius | 실제 컴포넌트와 동일한 radius 사용 |
| Flutter 구현 | `shimmer` 패키지 또는 커스텀 `ShaderMask` |

```dart
/// Glass Card 스켈레톤 시머
class GlassShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.06),
          highlightColor: Colors.white.withValues(alpha: 0.15),
          period: const Duration(milliseconds: 1500),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
```

**비평 결과**: 스켈레톤은 실제 카드와 동일한 크기/형태를 가져야 한다. 제너릭한 직사각형 블록이 아닌, 도넛 차트 영역은 원형, 텍스트 영역은 가로 바 형태로 실제 레이아웃을 반영한다.

---

### AN-15: Pull-to-refresh

**목적**: 수동 새로고침을 요청하는 제스처에 대한 물리적 피드백을 제공한다.

| 속성 | 값 |
|------|------|
| 유형 | Overscroll + Spinner |
| 물리 | `BouncingScrollPhysics` (당기면 스프링 저항) |
| 트리거 거리 | 80px 이상 당겨야 새로고침 시작 |
| 스피너 | 원형 Progress Indicator (white, 24px) |
| 스피너 등장 | 당김 거리에 비례하여 opacity + scale 증가 |
| 완료 후 | 스피너 fade-out + 콘텐츠 snap-back |
| Flutter 구현 | `RefreshIndicator` (커스텀 스타일) |

```dart
/// 커스텀 Pull-to-refresh
RefreshIndicator(
  onRefresh: _handleRefresh,
  color: Colors.white,
  backgroundColor: Colors.white.withValues(alpha: 0.2),
  displacement: 40,
  strokeWidth: 2.5,
  child: scrollableContent,
);
```

---

## 3. 컴포넌트별 애니메이션 매핑

### 3.1 홈 대시보드 (F1)

| 컴포넌트 | 진입 | 인터랙션 | 퇴장 |
|----------|------|---------|------|
| 인사 메시지 | Fade-in 300ms | - | - |
| 투두 Glass Card | Staggered AN-02 (index 0) | - | - |
| 투두 도넛차트 | AN-03 (800ms, 100ms 딜레이) | 값 변경 시 AN-03 재실행 | - |
| 체크리스트 아이템 | Staggered fade-in (카드 내부) | AN-04 체크 | AN-08 제거 |
| 습관 Glass Card | Staggered AN-02 (index 1) | - | - |
| 습관 도넛차트 | AN-03 (800ms, 200ms 딜레이) | 값 변경 시 AN-03 재실행 | - |
| 습관 필 | Staggered fade-in (카드 내부) | AN-04 체크 | - |
| D-day 섹션 타이틀 | Fade-in | - | - |
| D-day 카드들 | Staggered slide-right | AN-10 스크롤 | - |
| 주간 요약 카드 | Staggered AN-02 (마지막) | 값 변경 시 카운팅 | - |

### 3.2 캘린더 (F2)

| 컴포넌트 | 진입 | 인터랙션 | 퇴장 |
|----------|------|---------|------|
| 뷰 타입 탭 | - | 탭 전환 underline slide | - |
| 캘린더 그리드 | AN-09 CrossFade | 날짜 탭: 선택 원 scale-in | 뷰 전환 시 fade-out |
| 날짜별 일정 dot | Fade-in 200ms | - | - |
| 일정 리스트 | Staggered fade-in | 탭: 모달 열기 AN-06 | 삭제 AN-08 |
| 현재시간선 | Slide-right 300ms | - | - |
| 일정 생성 모달 | AN-06 Enter | 탭/입력 | AN-06 Exit |

### 3.3 투두 (F3)

| 컴포넌트 | 진입 | 인터랙션 | 퇴장 |
|----------|------|---------|------|
| 주간 슬라이더 | - | 스와이프: physics scroll | - |
| 서브탭 전환 | AN-09 CrossFade | - | - |
| 도넛차트 | AN-03 | 체크 시 값 변경 애니메이션 | - |
| 타임라인 | Staggered slide-right | - | - |
| 할 일 리스트 | Staggered fade-in | AN-04 체크 | AN-08 삭제 |
| FAB (+) | Scale-in 200ms | 탭: 모달 AN-06 | - |

### 3.4 습관/루틴 (F4)

| 컴포넌트 | 진입 | 인터랙션 | 퇴장 |
|----------|------|---------|------|
| 습관 달성률 차트 | AN-03 | 체크 시 재계산 | - |
| 습관 카드 | Staggered AN-02 | AN-04 체크 + AN-12 스트릭 | 삭제 AN-08 |
| 습관 캘린더 | Fade-in 300ms | 날짜 탭: 하단 상세 슬라이드 | - |
| 미니 도넛차트 | 각 날짜 fade-in | - | - |
| 루틴 카드 | Staggered AN-02 | 토글: slide + color | 삭제 AN-08 |
| 프리셋 카드 | Fade-in | 탭: scale bounce + 등록 | 등록 완료 시 slide-up 퇴장 |

### 3.5 목표/만다라트 (F5)

| 컴포넌트 | 진입 | 인터랙션 | 퇴장 |
|----------|------|---------|------|
| 상단 통계 | Counting up AN-12 | 변경 시 재카운팅 | - |
| 목표 카드 | Staggered AN-02 | 체크: AN-04 + 진행률 바 | 삭제 AN-08 |
| 진행률 바 | Width 0% -> 목표% (600ms) | 변경 시 width 전환 | - |
| 만다라트 그리드 | Scale-in 0.8->1.0 (400ms) | AN-11 줌 | - |
| 위저드 단계 | Slide-left (이전->다음) | - | Slide-right (다음->이전) |

---

## 4. 제스처 사양

| 제스처 | 대상 | 동작 |
|--------|------|------|
| 탭 | 체크박스, 버튼, 카드, 네비게이션 | 즉시 반응 (AN-04/05/06) |
| 롱프레스 | 투두/습관/일정 카드 | 300ms 후 컨텍스트 메뉴 (scale 0.98 피드백) |
| 수평 스와이프 | 주간 슬라이더, D-day 카드 | 물리 기반 스크롤 |
| 수직 스와이프 | 전체 페이지 스크롤 | `BouncingScrollPhysics` |
| 풀다운 | 페이지 상단 | AN-15 Pull-to-refresh |
| 핀치 줌 | 만다라트 그리드 | AN-11 줌 인/아웃 |

---

## 5. 플랫폼별 고려 사항

### 5.1 Flutter Web (CanvasKit)

| 항목 | 고려 사항 |
|------|---------|
| BackdropFilter 성능 | CanvasKit WASM에서 blur 렌더링 비용이 높다. 화면에 5개 이상 동시 렌더링을 피한다 |
| 마우스 hover 효과 | 웹에서 hover 상태를 추가한다 (모바일에는 없음) |
| 키보드 포커스 | Tab 키로 네비게이션 가능하도록 `FocusNode` 관리 |
| 초기 로딩 | WASM 2~3MB 로딩 중 스피너/스플래시 표시 |

### 5.2 Flutter Android

| 항목 | 고려 사항 |
|------|---------|
| 60fps | Skia 네이티브 렌더링으로 웹보다 성능 우수. 추가 최적화 불필요 |
| 햅틱 피드백 | 체크박스 완료 시 `HapticFeedback.lightImpact()` 추가 |
| 시스템 애니메이션 스케일 | `MediaQuery.disableAnimationsOf(context)` + 시스템 설정 반영 |
| 백 제스처 | Android 13+ 예측형 뒤로가기 지원 확인 |

### 5.3 Hover 상태 (Web 전용)

| 컴포넌트 | Hover 효과 |
|----------|-----------|
| Glass Card | border opacity 0.25 -> 0.35 (200ms) |
| Button (Primary) | 배경색 MAIN -> MAIN Hover (200ms) |
| Button (Secondary) | 배경 opacity 0.20 -> 0.30 (200ms) |
| Nav Item | 배경 rgba(255,255,255,0.08) (200ms) |
| Checkbox | border opacity 0.4 -> 0.6 (150ms) |
| D-day Card | translateY 0 -> -2px + shadow 강화 (200ms) |

---

## 6. 애니메이션 코드 구조

### 6.1 권장 파일 구조

```
lib/shared/
├── animations/
│   ├── staggered_list_animation.dart    # AN-02 Staggered 카드 등장
│   ├── donut_chart_animation.dart       # AN-03 도넛 차트 sweep
│   ├── checkbox_animation.dart          # AN-04 체크박스 bounce
│   ├── glass_modal_transition.dart      # AN-06 모달 열기/닫기
│   ├── list_item_animation.dart         # AN-07/08 리스트 추가/제거
│   ├── shimmer_loading.dart             # AN-14 스켈레톤 시머
│   └── counting_animation.dart          # AN-12 숫자 카운팅
├── widgets/
│   ├── glass_card.dart                  # Glass Card 공용 위젯
│   ├── glass_bottom_nav.dart            # Bottom Nav 위젯
│   ├── glass_modal.dart                 # Modal 위젯
│   └── animated_empty_state.dart        # 빈 상태 위젯
```

### 6.2 AnimationController 관리 규칙

1. **dispose 필수**: 모든 `AnimationController`는 `State.dispose()`에서 반드시 해제한다.
2. **TickerProvider**: `SingleTickerProviderStateMixin` (1개 컨트롤러) 또는 `TickerProviderStateMixin` (2개 이상)을 사용한다.
3. **Implicit 우선**: 가능하면 `AnimatedContainer`, `TweenAnimationBuilder` 등 Implicit 애니메이션을 우선한다. Explicit `AnimationController`는 복잡한 시퀀스에만 사용한다.
4. **forward/reverse 패턴**: 토글 가능한 애니메이션은 `controller.forward()` / `controller.reverse()` 패턴을 사용한다. 새 컨트롤러를 생성하지 않는다.
