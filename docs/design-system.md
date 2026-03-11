# Design Your Life - 디자인 시스템

> Design Team 최종 합의 결과 (design-trend-researcher, design-motion-specialist, design-critic)
> 작성일: 2026-03-09
> 디자인 방향: Glassmorphism + Floating Capsule Bottom Nav

---

## 1. 디자인 컨셉 선언

Design Your Life는 "유리 위의 명징한 삶"을 시각적 정체성으로 삼는다. 보라색 그라디언트 위에 떠 있는 반투명 유리 카드는 사용자의 일상 데이터를 정돈된 아름다움으로 표현한다. 모든 인터랙션은 부드럽고 자연스러운 물리 기반 모션으로 설계하여, 생산성 앱임에도 사용할 때마다 감각적 만족을 느낄 수 있도록 한다. 2025-2026 Glassmorphism 트렌드의 핵심인 "과도한 투명도를 지양하고, 정보 가독성을 최우선으로 확보하는 기능적 유리 효과"를 따른다. 장식을 위한 애니메이션은 배제하고, 상태 변화를 안내하거나 사용자의 주의를 유도하는 목적의 모션만 허용한다.

---

## 2. 타이포그래피 시스템

### 2.1 폰트 패밀리

| 우선순위 | 폰트 | 용도 |
|----------|-------|------|
| 1순위 | Pretendard | 기본 본문, 제목, UI 전체 |
| Fallback 1 | -apple-system | macOS/iOS |
| Fallback 2 | BlinkMacSystemFont | Chrome macOS |
| Fallback 3 | system-ui | 시스템 기본 |
| Fallback 4 | sans-serif | 최종 대비 |

**Flutter 적용**: `GoogleFonts.notoSansKr()` 또는 로컬 번들 `Pretendard` 폰트를 사용한다. CanvasKit 렌더러에서 한글 렌더링 품질이 가장 높은 폰트를 선택한다.

### 2.2 타이포그래피 스케일

| 토큰명 | 크기 | 두께 | 행간 | 자간 | 용도 |
|--------|------|------|------|------|------|
| `display-lg` | 34px | ExtraBold (800) | 1.2 | -0.8px | 스플래시 타이틀, 만다라트 핵심 목표 |
| `display-md` | 28px | ExtraBold (800) | 1.2 | -0.5px | D-day 숫자, 통계 수치 |
| `heading-lg` | 26px | Bold (700) | 1.3 | -0.5px | 인사 메시지 (이름) |
| `heading-md` | 22px | ExtraBold (800) | 1.3 | -0.3px | 도넛차트 퍼센트 |
| `heading-sm` | 18px | Bold (700) | 1.3 | -0.2px | 섹션 제목 |
| `title-lg` | 16px | Bold (700) | 1.4 | 0px | 카드 타이틀 |
| `title-md` | 15px | SemiBold (600) | 1.4 | 0px | 모달 타이틀, 서브 헤딩 |
| `body-lg` | 14px | Regular (400) | 1.5 | 0px | 기본 본문, 체크리스트 항목 |
| `body-md` | 13px | Medium (500) | 1.5 | 0px | D-day 타이틀, 습관 이름 |
| `body-sm` | 13px | Regular (400) | 1.5 | 0px | 보조 본문 |
| `caption-lg` | 12px | SemiBold (600) | 1.4 | 0px | 뱃지 텍스트, 네비게이션 라벨 |
| `caption-md` | 11px | Regular (400) | 1.4 | 0px | 습관 상태, D-day 날짜, 타임스탬프 |
| `caption-sm` | 10px | Regular (400) | 1.4 | 0px | 도넛차트 레이블, 미니 주석 |
| `overline` | 13px | SemiBold (600) | 1.3 | 1.0px | 섹션 분류 (uppercase) |

### 2.3 Glassmorphism 텍스트 색상 규칙

| 계층 | 색상 | 대비비 (gradient-mid 기준) |
|------|------|--------------------------|
| Primary (제목, 주요 텍스트) | `#FFFFFF` | 6.37:1 (AA PASS) |
| Secondary (보조 텍스트) | `rgba(255, 255, 255, 0.7)` | 4.46:1 (AA PASS) |
| Tertiary (캡션, 힌트) | `rgba(255, 255, 255, 0.5)` | 3.18:1 (AA-Large PASS) |
| Disabled | `rgba(255, 255, 255, 0.3)` | 1.91:1 (장식용만 허용) |

**비판적 검증 결과**: `rgba(255,255,255,0.5)` 텍스트는 caption 크기(12px 미만)에서 가독성이 떨어질 수 있다. caption 텍스트는 최소 `rgba(255,255,255,0.6)`을 사용하며, 12px 미만 텍스트에서는 `rgba(255,255,255,0.7)` 이상을 적용한다.

### 2.4 Flutter TextTheme 매핑

```dart
// core/theme/typography_tokens.dart
abstract class AppTypography {
  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Pretendard',
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.8,
  );
  // ... 위 표의 모든 토큰을 동일 패턴으로 정의한다
}
```

---

## 3. 스페이싱 시스템

### 3.1 기본 그리드

4px 기준 그리드를 사용한다. 모든 여백, 패딩, 간격은 4의 배수로 설정한다.

| 토큰명 | 값 | 용도 |
|--------|------|------|
| `space-1` | 4px | 아이콘과 텍스트 사이 미세 간격 |
| `space-2` | 8px | 리스트 아이템 내부 간격, 체크박스-텍스트 간격 |
| `space-3` | 12px | 카드 내부 요소 간 간격, 습관 필 내부 패딩 (수직) |
| `space-4` | 16px | 카드 섹션 간 간격, 콘텐츠 영역 기본 패딩 |
| `space-5` | 20px | 카드 내부 패딩, 콘텐츠 좌우 패딩 |
| `space-6` | 24px | 화면 좌우 패딩, 헤더 패딩 |
| `space-8` | 32px | 섹션 간 간격, 대형 여백 |
| `space-10` | 40px | 화면 상하단 대형 여백 |
| `space-12` | 48px | 최대 여백, 모달 내부 패딩 |

### 3.2 컴포넌트별 스페이싱 가이드

| 컴포넌트 | 내부 패딩 | 외부 간격 |
|----------|----------|----------|
| Glass Card | 20px (space-5) | 16px (space-4) 카드 간 |
| Bottom Nav | 6px 24px (수직 수평) | 12px (하단 여백) |
| Nav Item | 6px 10px (기본) / 6px 14px (활성) | 10px (아이템 간) |
| Header | 20px 24px 8px (상 좌우 하) | - |
| Content Area | 16px 20px (상 좌우) | - |
| Check Item | - | 8px (아이템 간) |
| Habit Pill | 10px 14px | 10px (필 간) |
| D-day Card | 16px | 12px (카드 간) |
| Section Title | 0 0 -4px 4px (상 우 하 좌) | 16px (이전 섹션과) |

---

## 4. 글래스모피즘 컴포넌트 스펙

### 4.1 Glass Card

3가지 변형(variant)을 정의한다.

#### Default Glass Card

| 속성 | 값 |
|------|------|
| 배경 | `rgba(255, 255, 255, 0.15)` |
| Backdrop Blur | `blur(20px)` |
| Border | `1px solid rgba(255, 255, 255, 0.25)` |
| Border Radius | 20px |
| Shadow | `0 8px 32px rgba(0, 0, 0, 0.1)` |
| Padding | 20px |

#### Elevated Glass Card

정보 카드, 모달, 강조 컨텐츠에 사용한다.

| 속성 | 값 |
|------|------|
| 배경 | `rgba(255, 255, 255, 0.20)` |
| Backdrop Blur | `blur(24px)` |
| Border | `1px solid rgba(255, 255, 255, 0.30)` |
| Border Radius | 24px |
| Shadow | `0 12px 40px rgba(0, 0, 0, 0.15)` |
| Padding | 24px |

#### Subtle Glass Card

내부 섹션 카드, 습관 필, D-day 카드 등 보조 카드에 사용한다.

| 속성 | 값 |
|------|------|
| 배경 | `rgba(255, 255, 255, 0.12)` |
| Backdrop Blur | `blur(16px)` |
| Border | 없음 |
| Border Radius | 12~16px |
| Shadow | 없음 |
| Padding | 10~16px (컴포넌트에 따라) |

#### Flutter 구현 참조

```dart
// core/theme/glassmorphism.dart
class GlassDecoration {
  /// 기본 유리 카드 데코레이션
  static BoxDecoration defaultCard() => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.25),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// 강조 유리 카드 데코레이션
  static BoxDecoration elevatedCard() => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.20),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.30),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 40,
        offset: const Offset(0, 12),
      ),
    ],
  );

  /// 보조 유리 카드 데코레이션
  static BoxDecoration subtleCard({double radius = 12}) => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(radius),
  );
}
```

**ClipRRect + BackdropFilter 패턴**: Flutter에서 Glassmorphism을 구현할 때 반드시 `ClipRRect`로 영역을 클리핑한 후 `BackdropFilter`를 적용한다. 클리핑 없이 `BackdropFilter`를 사용하면 블러가 전체 화면에 적용되어 성능이 급격히 저하된다.

```dart
// 올바른 Glassmorphism 위젯 패턴
class GlassCard extends StatelessWidget {
  final Widget child;
  final GlassVariant variant;

  const GlassCard({
    required this.child,
    this.variant = GlassVariant.defaultCard,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          decoration: _decoration,
          padding: EdgeInsets.all(_padding),
          child: child,
        ),
      ),
    );
  }
}
```

### 4.2 Glass Bottom Nav (Floating Capsule)

| 속성 | 값 |
|------|------|
| 배경 | `rgba(255, 255, 255, 0.18)` |
| Backdrop Blur | `blur(30px)` |
| Border | `1px solid rgba(255, 255, 255, 0.2)` |
| Border Radius | 100px (완전한 캡슐) |
| Shadow | `0 8px 32px rgba(0, 0, 0, 0.15)` |
| Padding | 6px 24px (수직 수평) |
| Position | 화면 하단 12px, 가로 중앙 정렬 |
| Z-index | 100 |

#### Nav Item 상태

| 상태 | 배경 | 패딩 | 아이콘 투명도 | 라벨 |
|------|------|------|-------------|------|
| Inactive | 투명 | 6px 10px | 0.45 | 숨김 |
| Active | `rgba(255, 255, 255, 0.25)` | 6px 14px | 1.0 | 표시 (white, Bold) |
| Pressed | `rgba(255, 255, 255, 0.35)` | 6px 14px | 1.0 | 표시 |

#### 5탭 아이콘 매핑

| 탭 | 아이콘 (Inactive) | 아이콘 (Active) | 라벨 |
|----|-------------------|-----------------|------|
| 홈 | `Icons.home_outlined` | `Icons.home_rounded` | 홈 |
| 캘린더 | `Icons.calendar_today_outlined` | `Icons.calendar_today_rounded` | 캘린더 |
| 투두 | `Icons.check_circle_outline` | `Icons.check_circle_rounded` | 투두 |
| 습관/루틴 | `Icons.loop_outlined` | `Icons.loop_rounded` | 습관 |
| 목표 | `Icons.flag_outlined` | `Icons.flag_rounded` | 목표 |

### 4.3 Glass Dialog / Modal

| 속성 | 값 |
|------|------|
| 배경 | `rgba(255, 255, 255, 0.20)` |
| Backdrop Blur | `blur(24px)` |
| Border | `1px solid rgba(255, 255, 255, 0.30)` |
| Border Radius | 28px |
| Shadow | `0 16px 48px rgba(0, 0, 0, 0.2)` |
| 최대 너비 | 360px (모바일), 480px (태블릿/데스크톱) |
| 내부 패딩 | 24px |
| Scrim (배경 딤) | `rgba(0, 0, 0, 0.4)` |

### 4.4 Glass Button

#### Primary Button (CTA)

| 속성 | 값 |
|------|------|
| 배경 | `#7C3AED` (MAIN) 단색 |
| 텍스트 색상 | `#FFFFFF` |
| Border Radius | 12px |
| Padding | 14px 24px |
| Font | 15px, SemiBold (600) |
| Shadow | `0 4px 16px rgba(124, 58, 237, 0.3)` |
| Hover | `#6A2DD3` |
| Pressed | `#5B24BA` |
| Disabled | MAIN at 40% opacity |

#### Secondary Button

| 속성 | 값 |
|------|------|
| 배경 | `rgba(255, 255, 255, 0.20)` |
| 텍스트 색상 | `#FFFFFF` |
| Border | `1px solid rgba(255, 255, 255, 0.30)` |
| Border Radius | 12px |
| Padding | 14px 24px |
| Font | 15px, SemiBold (600) |
| Hover | `rgba(255, 255, 255, 0.30)` |

#### Ghost Button

| 속성 | 값 |
|------|------|
| 배경 | 투명 |
| 텍스트 색상 | `rgba(255, 255, 255, 0.7)` |
| Border | 없음 |
| Border Radius | 8px |
| Padding | 8px 16px |
| Font | 14px, Medium (500) |
| Hover | `rgba(255, 255, 255, 0.08)` |

### 4.5 Glass Input Field

| 속성 | 값 |
|------|------|
| 배경 | `rgba(255, 255, 255, 0.10)` |
| Border | `1px solid rgba(255, 255, 255, 0.20)` |
| Border (Focus) | `1px solid rgba(255, 255, 255, 0.50)` |
| Border Radius | 12px |
| Padding | 14px 16px |
| 텍스트 색상 | `#FFFFFF` |
| Placeholder | `rgba(255, 255, 255, 0.4)` |
| Font | 14px, Regular (400) |
| Cursor 색상 | `#FFFFFF` |
| Error Border | `rgba(239, 68, 68, 0.6)` |

### 4.6 Glass Chip / Tag

| 속성 | 값 |
|------|------|
| 배경 | `rgba(255, 255, 255, 0.20)` |
| Border Radius | 20px (완전한 캡슐) |
| Padding | 4px 10px |
| 텍스트 색상 | `#FFFFFF` |
| Font | 12px, SemiBold (600) |
| 선택 상태 배경 | `rgba(255, 255, 255, 0.35)` |

---

## 5. 그림자 시스템

Glassmorphism에서 그림자는 깊이감(depth)을 표현하는 핵심 요소다. 과도한 그림자는 유리 효과를 상쇄하므로 제한적으로 사용한다.

| 레벨 | 값 | 용도 |
|------|------|------|
| `shadow-none` | 없음 | Subtle 카드, 내부 컴포넌트 |
| `shadow-sm` | `0 4px 16px rgba(0, 0, 0, 0.08)` | 버튼, 칩, 작은 요소 |
| `shadow-md` | `0 8px 32px rgba(0, 0, 0, 0.10)` | 기본 Glass Card |
| `shadow-lg` | `0 12px 40px rgba(0, 0, 0, 0.15)` | Elevated Card, 떠오른 요소 |
| `shadow-xl` | `0 16px 48px rgba(0, 0, 0, 0.20)` | Modal, Dialog |
| `shadow-cta` | `0 4px 16px rgba(124, 58, 237, 0.30)` | CTA 버튼 전용 (MAIN 컬러 그림자) |

**규칙**: 그림자 색상에 순수 검정(`#000000`)만 사용한다. 그림자에 Hue를 넣으면 그라디언트 배경과 충돌할 수 있다. CTA 버튼만 예외적으로 MAIN 컬러 기반 그림자를 사용한다.

---

## 6. Border Radius 시스템

| 토큰명 | 값 | 용도 |
|--------|------|------|
| `radius-xs` | 4px | 체크박스 내부 모서리 |
| `radius-sm` | 6px | 체크박스 |
| `radius-md` | 8px | Ghost Button, 작은 토글 |
| `radius-lg` | 12px | Input Field, Primary Button, Subtle Card (작은) |
| `radius-xl` | 14px | 주간 통계 카드 |
| `radius-2xl` | 16px | D-day 카드, Subtle Card (중간) |
| `radius-3xl` | 20px | 기본 Glass Card, 칩/뱃지 |
| `radius-4xl` | 24px | Elevated Card |
| `radius-5xl` | 28px | Modal/Dialog |
| `radius-full` | 100px | Bottom Nav, 캡슐 형태 버튼, 원형 아바타 |
| `radius-circle` | 50% | 습관 체크(원형), 아이콘 버튼 |

---

## 7. 아이콘 시스템

### 7.1 권장 아이콘 세트

**기본**: Flutter Material Icons (Rounded variant)를 사용한다. 둥근 모서리가 Glassmorphism의 부드러운 느낌과 조화를 이룬다.

**보충**: 이모지를 습관 아이콘으로 사용한다 (사용자 커스텀 지원).

### 7.2 아이콘 크기

| 토큰명 | 크기 | 용도 |
|--------|------|------|
| `icon-xs` | 12px | 인라인 장식 아이콘 |
| `icon-sm` | 16px | 리스트 아이템 부가 아이콘 |
| `icon-md` | 20px | 네비게이션 아이콘, 체크박스 내부 |
| `icon-lg` | 24px | 카드 헤더 아이콘, 액션 버튼 아이콘 |
| `icon-xl` | 28px | 빈 상태 메인 아이콘 |
| `icon-2xl` | 48px | 빈 상태 대형 일러스트 아이콘 |

### 7.3 아이콘 색상 (Glass 모드)

| 상태 | 색상 |
|------|------|
| Active | `#FFFFFF` (opacity 1.0) |
| Inactive | `rgba(255, 255, 255, 0.45)` |
| Disabled | `rgba(255, 255, 255, 0.25)` |
| CTA 아이콘 | `#FFFFFF` on MAIN 배경 |

---

## 8. 도넛 차트 스펙

### 8.1 크기

| 용도 | 외경 | SVG ViewBox | Stroke Width | 내부 반지름 |
|------|------|-------------|-------------|------------|
| 대시보드 메인 차트 | 90px | 90x90 | 8px | 35px |
| 습관 캘린더 미니 차트 | 28px | 28x28 | 3px | 10px |
| 투두 탭 차트 | 120px | 120x120 | 10px | 45px |

### 8.2 색상

| 요소 | 색상 |
|------|------|
| 트랙 (미완료) | `rgba(255, 255, 255, 0.15)` |
| 투두 진행 (완료) | `rgba(255, 255, 255, 0.85)` |
| 습관 진행 (완료) | `#A0F0C0` (밝은 초록) |
| 중앙 퍼센트 텍스트 | `#FFFFFF`, heading-md (22px, ExtraBold) |
| 중앙 레이블 텍스트 | `rgba(255, 255, 255, 0.6)`, caption-sm (10px) |

### 8.3 SVG 속성

| 속성 | 값 |
|------|------|
| Stroke Linecap | `round` |
| 회전 | `-90deg` (12시 방향 시작) |
| 전체 둘레 (r=35) | `2 * pi * 35 = 219.91` |
| Dash Array 계산 | `완료율 * 219.91`, `나머지 = 219.91 - 진행분` |

### 8.4 Flutter 구현 (fl_chart)

```dart
// fl_chart PieChart 사용 시
PieChartData(
  sectionsSpace: 0,
  centerSpaceRadius: 35,
  sections: [
    PieChartSectionData(
      value: completionRate,
      color: Colors.white.withValues(alpha: 0.85),
      radius: 8,
      showTitle: false,
    ),
    PieChartSectionData(
      value: 100 - completionRate,
      color: Colors.white.withValues(alpha: 0.15),
      radius: 8,
      showTitle: false,
    ),
  ],
);
```

---

## 9. 애니메이션 스펙

> 상세 사양은 `/docs/animation-spec.md` 참조. 이 섹션에서는 핵심 원칙과 요약만 다룬다.

### 9.1 애니메이션 원칙

1. **목적 우선**: 모든 애니메이션은 상태 변화 안내, 주의 유도, 또는 피드백 제공 중 하나의 목적을 가진다.
2. **60fps 목표**: 모든 애니메이션은 60fps를 유지한다. `BackdropFilter`와 동시 사용 시 성능 영향을 고려한다.
3. **300ms 규칙**: 대부분의 UI 애니메이션은 200~400ms 범위 안에서 완료한다. 500ms를 초과하는 애니메이션은 사용자를 기다리게 만든다.
4. **Reduced Motion 존중**: `MediaQuery.disableAnimations`를 확인하여, 접근성 설정에서 모션 감소를 요청한 사용자에게는 즉시 상태 전환(duration: 0)을 제공한다.
5. **물리 기반 이징**: Flutter의 `Curves.easeOutCubic`과 `Curves.easeInOutCubic`을 기본으로 사용한다. 선형(linear) 이징은 금지한다.

### 9.2 애니메이션 요약 매핑

| 대상 | 유형 | Duration | Easing | 참조 |
|------|------|----------|--------|------|
| 페이지 전환 (탭) | Fade + 미세 수직 이동 | 250ms | easeOutCubic | AN-01 |
| 카드 등장 | Staggered fade-in + slide-up | 350ms + 50ms 딜레이 | easeOutCubic | AN-02 |
| 도넛 차트 | Sweep (0 -> 목표값) | 800ms | easeInOutCubic | AN-03 |
| 체크박스 완료 | Scale bounce + 체크마크 draw | 300ms | easeOutBack | AN-04 |
| Bottom Nav 전환 | Active pill width + icon opacity | 250ms | easeInOutCubic | AN-05 |
| 모달 열기/닫기 | Scale(0.9->1) + Fade | 250ms / 200ms | easeOutCubic / easeInCubic | AN-06 |
| 리스트 아이템 추가 | Slide-down + Fade-in | 300ms | easeOutCubic | AN-07 |
| 리스트 아이템 제거 | Slide-left + Fade-out | 250ms | easeInCubic | AN-08 |
| 캘린더 뷰 전환 | CrossFade | 300ms | easeInOutCubic | AN-09 |
| D-day 수평 스크롤 | Physics-based scroll | Spring | ClampingScrollPhysics | AN-10 |
| 만다라트 줌 | Scale + Fade | 400ms | easeOutCubic | AN-11 |
| 스트릭 증가 | Counting up + 경미한 scale | 600ms | easeOutCubic | AN-12 |
| 빈 상태 -> 콘텐츠 | Fade transition | 300ms | easeInOutCubic | AN-13 |
| 스켈레톤 시머 | Gradient sweep | 1500ms (반복) | linear (예외 허용) | AN-14 |
| Pull-to-refresh | Overscroll + spinner | Spring | BouncingScrollPhysics | AN-15 |

### 9.3 성능 예산

| 항목 | 제한 |
|------|------|
| 동시 애니메이션 | 최대 3개 |
| BackdropFilter 동시 렌더링 | 화면에 최대 5개 |
| 단일 애니메이션 최대 Duration | 1000ms (스켈레톤 시머 예외) |
| Staggered 최대 딜레이 합계 | 400ms (카드 8개 기준) |
| GPU 레이어 수 | 모바일 기준 20개 미만 |

---

## 10. 반응형 브레이크포인트

### 10.1 정의

| 이름 | 범위 | 전형적 기기 |
|------|------|------------|
| Mobile | < 600px | 스마트폰 (390px 기준 설계) |
| Tablet | 600px ~ 899px | 태블릿 세로, 작은 태블릿 가로 |
| Desktop | 900px ~ 1199px | 태블릿 가로, 작은 노트북 |
| Wide Desktop | >= 1200px | 데스크톱 모니터 |

### 10.2 레이아웃 변형

| 요소 | Mobile | Tablet | Desktop / Wide |
|------|--------|--------|---------------|
| 콘텐츠 최대 너비 | 100% | 100% | 960px (중앙 정렬) |
| 카드 레이아웃 | 1열 풀 너비 | 2열 그리드 | 2열 그리드 |
| 하단 네비게이션 | 표시 (캡슐) | 표시 (캡슐) | 표시 (캡슐) |
| 카드 간격 | 16px | 16px | 20px |
| 콘텐츠 좌우 패딩 | 20px | 24px | 32px |
| 도넛 차트 크기 | 90px | 100px | 120px |
| Header 텍스트 크기 | 26px | 28px | 30px |
| D-day 카드 최소 너비 | 140px | 160px | 180px |
| 주간 통계 | 2열 | 2열 (넓어짐) | 2열 (넓어짐) |

### 10.3 Flutter 반응형 유틸

```dart
// core/utils/responsive_utils.dart
abstract class Responsive {
  static bool isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 900;
  }

  static bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 900;

  static double contentMaxWidth(BuildContext context) =>
    isDesktop(context) ? 960 : double.infinity;

  static int gridCrossAxisCount(BuildContext context) =>
    isMobile(context) ? 1 : 2;

  static double contentPadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 20;
  }
}
```

---

## 11. 다크 모드 스펙

### 11.1 Glassmorphism 다크 모드 적응

다크 모드에서 Glassmorphism의 그라디언트 배경을 어둡게 변환한다. 유리 카드의 투명도와 블러는 유지하되, 배경 그라디언트의 명도를 낮추고 채도를 약간 높여 깊이감을 유지한다.

| 요소 | Light Mode | Dark Mode |
|------|-----------|-----------|
| 배경 그라디언트 | `#667EEA -> #764BA2 -> #F093FB` | `#2D3561 -> #3B1F5C -> #5C2E6B` |
| Glass Card 배경 | `rgba(255, 255, 255, 0.15)` | `rgba(255, 255, 255, 0.08)` |
| Glass Card Border | `rgba(255, 255, 255, 0.25)` | `rgba(255, 255, 255, 0.12)` |
| Glass Card Shadow | `rgba(0, 0, 0, 0.10)` | `rgba(0, 0, 0, 0.30)` |
| Bottom Nav 배경 | `rgba(255, 255, 255, 0.18)` | `rgba(255, 255, 255, 0.10)` |
| Glass Blur 강도 | `blur(20px)` | `blur(24px)` (약간 강화) |

### 11.2 다크 모드 텍스트

| 계층 | Light (Glass) | Dark (Glass) |
|------|-------------|-------------|
| Primary | `#FFFFFF` | `#FFFFFF` |
| Secondary | `rgba(255,255,255,0.7)` | `rgba(255,255,255,0.75)` |
| Tertiary | `rgba(255,255,255,0.5)` | `rgba(255,255,255,0.55)` |

다크 모드에서는 배경이 어두워지므로 텍스트 투명도를 약간 올려 가독성을 보정한다.

### 11.3 다크 모드 비-Glass 화면 (Light Mode 대비)

온보딩, 로그인 등 그라디언트 배경이 아닌 화면에서는 `color-system.md`의 Dark Mode 토큰을 그대로 적용한다.

| 역할 | 값 |
|------|------|
| 페이지 배경 | `#1C1B1E` (gray-900) |
| 카드 배경 | `#2B2A2D` (gray-800) |
| 제목 텍스트 | `#F8F7FB` (gray-50) |
| 본문 텍스트 | `#E5E3E9` (gray-200) |
| CTA 버튼 | `#7C3AED` (MAIN, 동일) |
| 링크 | `#A78BFA` (MAIN 밝은 변형) |

---

## 12. 빈 상태 UI 패턴

### 12.1 구성 규칙

모든 빈 상태 UI는 3요소(아이콘 + 안내 텍스트 + CTA)를 포함하며, Glass Card 위에 중앙 정렬로 배치한다.

### 12.2 시각적 스타일

| 요소 | 스타일 |
|------|--------|
| 아이콘 | Material Icons Rounded, 48px, `rgba(255,255,255,0.3)` |
| 메인 텍스트 | body-lg (14px), `rgba(255,255,255,0.7)` |
| 서브 텍스트 | caption-md (11px), `rgba(255,255,255,0.4)` |
| CTA 버튼 | Secondary Glass Button 또는 텍스트 링크 |
| 카드 최소 높이 | 120px |
| 내부 패딩 | 24px |
| 요소 간 간격 | 아이콘-텍스트 12px, 텍스트-CTA 16px |

### 12.3 탭별 빈 상태 아이콘

| 탭/섹션 | 아이콘 | 메인 텍스트 |
|---------|--------|-----------|
| 홈 - 투두 | `Icons.checklist_rounded` | 오늘 할 일이 없어요 |
| 홈 - 습관 | `Icons.loop_rounded` | 등록된 습관이 없어요 |
| 홈 - D-day | `Icons.event_rounded` | 다가오는 일정이 없어요 |
| 캘린더 - 날짜별 | `Icons.event_note_rounded` | 일정이 없습니다 |
| 투두 - 목록 | `Icons.task_alt_rounded` | 오늘 일정이 없습니다 |
| 습관 - 오늘 | `Icons.emoji_nature_rounded` | 아직 등록된 습관이 없어요 |
| 루틴 - 목록 | `Icons.schedule_rounded` | 아직 등록된 루틴이 없어요 |
| 목표 - 년간 | `Icons.flag_rounded` | 아직 등록된 목표가 없어요 |
| 만다라트 | `Icons.grid_view_rounded` | 만다라트로 목표를 구조화해보세요! |

### 12.4 빈 상태 애니메이션

빈 상태 UI가 표시될 때 아이콘이 미세하게 위아래로 부유하는 애니메이션을 적용한다.

- 수직 이동: 4px
- Duration: 2000ms
- Easing: `Curves.easeInOutSine`
- 반복: 무한 (reverse)

과도한 움직임을 피하기 위해 이동 거리를 4px로 제한한다.

---

## 13. 에러 상태 UI 패턴

### 13.1 에러 유형별 표시

#### 네트워크 에러 (지속 배너)

| 요소 | 스타일 |
|------|--------|
| 위치 | 화면 상단 (Status Bar 아래) |
| 배경 | `rgba(245, 158, 11, 0.25)` (Warning) |
| Border | `1px solid rgba(245, 158, 11, 0.4)` |
| 아이콘 | `Icons.wifi_off_rounded` |
| 텍스트 | "인터넷 연결이 불안정해요" (white) |
| Border Radius | 0 (좌우 끝까지) |
| 높이 | 40px |

#### 인증 에러 (풀스크린 오버레이)

| 요소 | 스타일 |
|------|--------|
| 배경 | Scrim `rgba(0, 0, 0, 0.6)` + Elevated Glass Card |
| 아이콘 | `Icons.lock_outline_rounded`, 48px |
| 메인 텍스트 | "로그인이 만료되었어요" |
| CTA | Primary Button "다시 로그인" |

#### 동기화 에러 (하단 스낵바)

| 요소 | 스타일 |
|------|--------|
| 위치 | Bottom Nav 위 8px |
| 배경 | `rgba(239, 68, 68, 0.25)` (Error) |
| Border Radius | 12px |
| 아이콘 | `Icons.sync_problem_rounded` |
| 텍스트 | "동기화하지 못했어요" |
| 자동 닫힘 | 4000ms |

#### 입력 에러 (인라인)

| 요소 | 스타일 |
|------|--------|
| 위치 | Input Field 바로 아래 4px |
| 색상 | `rgba(239, 68, 68, 0.8)` |
| 아이콘 | 없음 |
| 텍스트 | caption-md (11px), 구체적 안내 ("1자 이상 입력해주세요") |
| Input Border 색상 | `rgba(239, 68, 68, 0.6)` |

### 13.2 에러 상태 애니메이션

- 배너/스낵바 등장: Slide-down + Fade-in, 250ms, `easeOutCubic`
- 배너/스낵바 퇴장: Slide-up + Fade-out, 200ms, `easeInCubic`
- 인라인 에러 텍스트: Fade-in + 미세 slide-down(4px), 200ms
- Shake 효과 (입력 거부 시): 수평 진동 3회, 총 300ms, 이동 거리 4px

---

## 14. 체크박스 / 체크마크 스펙

### 14.1 투두 체크박스 (사각형)

| 속성 | 미완료 | 완료 |
|------|--------|------|
| 크기 | 20px x 20px | 20px x 20px |
| Border Radius | 6px | 6px |
| Border | `2px solid rgba(255,255,255,0.4)` | `2px solid rgba(255,255,255,0.6)` |
| 배경 | 투명 | `rgba(255,255,255,0.3)` |
| 체크마크 | 없음 | 흰색 체크 (12px, Bold) |
| 텍스트 스타일 | 기본 | strikethrough + opacity 0.5 |

### 14.2 습관 체크 (원형)

| 속성 | 미완료 | 완료 |
|------|--------|------|
| 크기 | 22px x 22px | 22px x 22px |
| 형태 | 원형 (50%) | 원형 (50%) |
| Border | `2px solid rgba(255,255,255,0.3)` | `2px solid rgba(76,217,100,0.6)` |
| 배경 | 투명 | `rgba(76,217,100,0.4)` |
| 체크마크 | 없음 | 흰색 체크 (11px) |

---

## 15. 컬러 시스템 참조

컬러 시스템의 상세 정의는 `/docs/color-system.md`에서 관리한다. 구현 시 해당 문서의 CSS Custom Properties 및 Flutter 컬러 토큰을 반드시 참조한다. 하드코딩을 금지한다.

### 15.1 핵심 컬러 요약 (빠른 참조용)

| 역할 | HEX |
|------|------|
| MAIN | `#7C3AED` |
| MAIN Hover | `#6A2DD3` |
| MAIN Pressed | `#5B24BA` |
| SUB | `#EDE9FE` |
| Gradient Start | `#667EEA` |
| Gradient Mid | `#764BA2` |
| Gradient End | `#F093FB` |
| Tinted Grey (50~900) | `#F8F7FB` ~ `#1C1B1E` |

---

## 16. 디자인 비평 결과 및 주의 사항

### 16.1 정보 밀도와 가독성

- Glass Card 위의 텍스트는 반드시 충분한 블러(최소 20px)를 확보해야 한다. 블러가 부족하면 배경 그라디언트가 비쳐 가독성이 떨어진다.
- 도넛 차트의 중앙 퍼센트 텍스트(22px, ExtraBold)는 충분한 크기이나, 미니 도넛차트(28px 외경)의 내부 퍼센트는 표시하지 않는다. 너무 작아 읽을 수 없다.
- 체크리스트 아이템은 최대 5개까지만 홈 카드에 미리보기로 표시한다. 초과 시 "더보기" 링크를 제공한다.

### 16.2 애니메이션 절제

- 생산성 앱에서 과도한 애니메이션은 사용자의 작업 흐름을 방해한다. "더 적은 것이 더 많다" 원칙을 따른다.
- 체크박스 완료 애니메이션은 만족감을 주되, 빠르게 여러 항목을 체크할 때 방해가 되지 않도록 300ms 이내로 제한한다.
- 페이지 전환은 250ms로 빠르게 처리한다. 사용자가 탭을 빠르게 전환할 때 애니메이션이 누적되지 않도록 이전 애니메이션을 즉시 완료(forward)한다.

### 16.3 반응형 주의 사항

- 데스크톱에서 Glass Card가 너무 넓어지면 텍스트 줄 길이가 과도해진다. `maxWidth: 960px`으로 제한한다.
- 태블릿 2열 그리드에서 도넛 차트 + 체크리스트 레이아웃은 카드 너비가 충분히 확보되어야 한다. 최소 카드 너비 300px을 보장한다.
- 모바일(390px)에서 Bottom Nav의 5개 아이템이 촘촘할 수 있다. 라벨은 Active 탭에만 표시하고 Inactive 탭은 아이콘만 표시한다.

### 16.4 접근성 검증 결과

- 모든 Primary 텍스트(White on gradient-mid)는 AA 통과 (6.37:1)
- Secondary 텍스트(0.7 opacity White)는 AA 통과 (4.46:1)
- Tertiary 텍스트(0.5 opacity White)는 AA-Large만 통과 (3.18:1) -- 14px 이상에서만 사용
- CTA 버튼(White on MAIN)은 AA 통과 (5.70:1)
- 색상만으로 정보를 전달하지 않는다 (아이콘 + 텍스트 레이블 병행)

---

## 17. 구현 규칙 요약

1. **컬러 하드코딩 금지**: 반드시 `color_tokens.dart`의 토큰을 참조한다.
2. **순수 무채색 금지**: `#000000`, `#333333` 등 Saturation 0% 색상을 절대 사용하지 않는다.
3. **Glass 위젯 패턴 준수**: 항상 `ClipRRect` + `BackdropFilter` + `Container(decoration)` 패턴을 사용한다.
4. **Reduced Motion 대응**: `MediaQuery.disableAnimations` 확인 후 애니메이션을 조건부 적용한다.
5. **BackdropFilter 성능 관리**: 화면에 동시에 5개 이상의 BackdropFilter를 렌더링하지 않는다. 스크롤 밖 카드는 블러를 비활성화한다.
6. **반응형 우선**: 모든 위젯은 390px(모바일)에서 먼저 설계하고, 태블릿/데스크톱으로 확장한다.
7. **4px 그리드 준수**: 모든 여백과 크기를 4의 배수로 설정한다.
8. **Border Radius 일관성**: 컴포넌트별 정의된 radius 토큰만 사용한다. 임의 값 금지.
