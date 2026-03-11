# Design Your Life - 컬러 시스템

> Color Team 최종 합의 결과 (color-psychologist, color-harmony-specialist, color-accessibility-analyst)
> 작성일: 2026-03-09

---

## 1. 컬러 시스템 개요

"Design Your Life" 앱의 Glassmorphism 디자인에 최적화된 **2색 시스템**을 정의한다.
Coolors.co 팔레트에서 MAIN + SUB 2색을 선정하고, MAIN Hue 기반 Tinted Grey 팔레트로 전체 UI를 구성한다.

**Coolors Source URL:** `https://coolors.co/667eea-7c3aed-a855f7-f093fb-ede9fe`
**선정:** color 2 (MAIN) + color 5 (SUB)

---

## 2. MAIN + SUB 2색 시스템

### MAIN COLOR: `#7C3AED` (Violet)

| 속성 | 값 |
|------|------|
| HEX | `#7C3AED` |
| RGB | `124, 58, 237` |
| HSB | `H: 262, S: 75.5%, B: 92.9%` |
| 용도 | CTA 버튼, 주요 하이라이트, 활성 상태, 링크, 포커스 링 |

**상태 변형:**

| 상태 | HEX | 설명 |
|------|------|------|
| Default | `#7C3AED` | 기본 상태 |
| Hover | `#6A2DD3` | 밝기 10% 감소 |
| Pressed | `#5B24BA` | 밝기 20% 감소 |
| Disabled | `#7C3AED` at 40% opacity | 비활성 상태 |
| Focus Ring | `#7C3AED` at 50% opacity, 3px offset | 접근성 포커스 |

### SUB COLOR: `#EDE9FE` (Light Violet)

| 속성 | 값 |
|------|------|
| HEX | `#EDE9FE` |
| RGB | `237, 233, 254` |
| HSB | `H: 251, S: 8.3%, B: 99.6%` |
| 용도 | 페이지 배경, 카드 배경, 보조 보더, 뱃지 배경 |

**상태 변형:**

| 상태 | HEX | 설명 |
|------|------|------|
| Default | `#EDE9FE` | 기본 상태 |
| Light (10% tint) | `#FDFCFE` | 배경 틴트용 |
| Hover | `#DDD8F1` | 밝기 5% 감소 |

---

## 3. 컬러 심리 분석 결과

### 3.1 MAIN (#7C3AED, Violet) 심리 분석

| 심리 요소 | 분석 |
|-----------|------|
| 창의성 | 보라색은 창의성과 상상력을 상징한다. "Design Your Life"의 핵심 철학인 "삶을 디자인한다"는 개념과 완벽히 부합한다. |
| 야망 | 자기계발과 목표 달성에 대한 열망을 내포한다. 한국 20대의 자기성장 문화와 공명한다. |
| 지혜 | 깊이 있는 사고와 통찰을 연상시킨다. 만다라트, 목표 설정 등 전략적 기능에 적합한다. |
| 프리미엄 | 고급스러운 인상을 주어 앱의 품질에 대한 신뢰를 형성한다. |

### 3.2 SUB (#EDE9FE, Light Violet) 심리 분석

| 심리 요소 | 분석 |
|-----------|------|
| 부드러움 | 높은 밝기(B: 99.6%)로 시각적 피로를 최소화한다. 장시간 사용에 적합한다. |
| 환영감 | 차갑지 않으면서도 깔끔한 배경색으로 사용자를 편안하게 맞이한다. |
| 유리질감 | Glassmorphism 디자인에서 유리카드 뒤의 은은한 색감을 제공한다. |

### 3.3 타겟 사용자 적합성 (한국 20대)

- **포부 문화**: 보라색은 한국 20대의 자기계발, 자기성장 열망과 강하게 공명한다.
- **디지털 네이티브**: 현대적이고 세련된 컬러로 디지털 세대에 자연스럽다.
- **트렌드 부합**: 2025-2026 한국 디자인 트렌드에서 부드러운 그라디언트와 바이올렛 톤이 인기를 얻고 있다.
- **생산성 + 감성**: 차가운 기업용 느낌을 피하면서도 생산성 앱으로서의 신뢰감을 유지한다.

---

## 4. Tinted Grey 팔레트 (MAIN Hue 기반)

MAIN 컬러의 Hue(262도)를 모든 Grey에 동일하게 적용한다.
순수 무채색(Saturation 0%)은 금지하며, HSB 곡선에 따라 밝을수록 S를 낮게, 어두울수록 S를 높게 설정한다.

| 토큰 | HEX | HSB (H/S/B) | 용도 |
|------|------|-------------|------|
| `gray-50` | `#F8F7FB` | 263 / 1.5% / 98.5% | 가장 밝은 배경, 페이지 배경 |
| `gray-100` | `#F1EFF4` | 263 / 2.0% / 96.0% | 카드 배경, 섹션 구분 |
| `gray-200` | `#E5E3E9` | 263 / 2.5% / 91.5% | 보더, 디바이더 |
| `gray-300` | `#D9D7DC` | 263 / 2.5% / 86.5% | 비활성 보더, 입력 필드 배경 |
| `gray-400` | `#A19FA5` | 263 / 4.0% / 65.0% | 플레이스홀더 텍스트, 비활성 아이콘 |
| `gray-500` | `#7B797F` | 263 / 5.0% / 50.0% | 보조 텍스트, 캡션 |
| `gray-600` | `#5D5B60` | 263 / 5.5% / 38.0% | 본문 보조 텍스트 |
| `gray-700` | `#49474C` | 263 / 7.0% / 30.0% | 본문 텍스트 |
| `gray-800` | `#2B2A2D` | 263 / 8.0% / 18.0% | 제목 텍스트 |
| `gray-900` | `#1C1B1E` | 263 / 10.0% / 12.0% | 가장 어두운 텍스트, 다크모드 배경 |

### 순수 무채색 검증 결과

모든 Grey 값의 Saturation이 0%를 초과함을 확인한다.

| 토큰 | Saturation | 판정 |
|------|-----------|------|
| gray-50 | 1.59% | TINTED (적합) |
| gray-100 | 2.05% | TINTED (적합) |
| gray-200 | 2.58% | TINTED (적합) |
| gray-300 | 2.27% | TINTED (적합) |
| gray-400 | 3.64% | TINTED (적합) |
| gray-500 | 4.72% | TINTED (적합) |
| gray-600 | 5.21% | TINTED (적합) |
| gray-700 | 6.58% | TINTED (적합) |
| gray-800 | 6.67% | TINTED (적합) |
| gray-900 | 10.00% | TINTED (적합) |

**금지 색상 목록**: `#000000`, `#333333`, `#666666`, `#999999`, `#CCCCCC`, `#F5F5F5` 등 Saturation 0% 순수 무채색은 절대 사용하지 않는다.

---

## 5. WCAG 대비비 검증 결과

### 5.1 핵심 대비비 테스트

| 조합 | 대비비 | AA (일반) | AA (대형) | AAA |
|------|--------|----------|----------|-----|
| MAIN on White | 5.70:1 | PASS | PASS | FAIL |
| White on MAIN | 5.70:1 | PASS | PASS | FAIL |
| MAIN on SUB | 4.80:1 | PASS | PASS | FAIL |
| gray-900 on White | 16.90:1 | PASS | PASS | PASS |
| gray-900 on SUB | 14.24:1 | PASS | PASS | PASS |
| White on gray-900 | 16.90:1 | PASS | PASS | PASS |
| MAIN on Black | 3.69:1 | FAIL | PASS | FAIL |

### 5.2 Tinted Grey 대비비

| 조합 | 대비비 | 용도 적합성 |
|------|--------|------------|
| gray-600 on White | 6.71:1 | 본문 보조 텍스트 (AA PASS) |
| gray-700 on White | 9.17:1 | 본문 텍스트 (AAA PASS) |
| gray-800 on White | 14.27:1 | 제목 텍스트 (AAA PASS) |
| gray-900 on White | 17.14:1 | 최고 대비 텍스트 (AAA PASS) |
| gray-50 on gray-900 | 16.10:1 | 다크모드 밝은 배경 (AAA PASS) |
| gray-100 on gray-900 | 15.04:1 | 다크모드 카드 배경 (AAA PASS) |

### 5.3 Glassmorphism 특수 사항

| 조합 | 대비비 | 비고 |
|------|--------|------|
| White on gradient-start (#667EEA) | 3.66:1 | AA-Large만 통과 - 대형 텍스트/아이콘에만 사용 |
| White on gradient-mid (#764BA2) | 6.37:1 | AA PASS - 본문 텍스트 사용 가능 |
| White on gradient-end (#F093FB) | 2.04:1 | FAIL - 텍스트 배치 금지, 장식적 용도만 |

**Glassmorphism 접근성 가이드라인:**
- 유리 카드 위 텍스트는 반드시 `backdrop-filter: blur(20px)` 이상 적용한다.
- 그라디언트 밝은 영역(#F093FB 근처)에서는 텍스트를 배치하지 않는다.
- CTA 버튼은 MAIN 컬러 단색 배경 + 흰색 텍스트를 사용한다 (5.70:1 대비비 확보).

---

## 6. 색맹 안전성 검증

### 6.1 적록 색맹 (Protanopia / Deuteranopia)

| 컬러 | 원래 인식 | 색맹 인식 | 판정 |
|------|----------|----------|------|
| MAIN #7C3AED | 보라-바이올렛 | 푸른 남색으로 인식 | SAFE |
| SUB #EDE9FE | 밝은 보라 틴트 | 밝은 회청색으로 인식 | SAFE |
| Success #22C55E | 초록 | 갈색/황색 계열로 변환 | 아이콘/텍스트 레이블 병행 필수 |
| Error #EF4444 | 빨강 | 어두운 갈색으로 변환 | 아이콘/텍스트 레이블 병행 필수 |

### 6.2 청색맹 (Tritanopia)

| 컬러 | 원래 인식 | 색맹 인식 | 판정 |
|------|----------|----------|------|
| MAIN #7C3AED | 보라-바이올렛 | 적색-핑크 쪽으로 이동 | SAFE (대비 유지) |
| SUB #EDE9FE | 밝은 보라 | 따뜻한 크림색으로 변환 | SAFE |

### 6.3 전색맹 (Achromatopsia)

| 컬러 | 상대 명도 | 판정 |
|------|----------|------|
| MAIN #7C3AED | 낮음 (Luminance ~0.12) | 어두운 회색으로 인식 |
| SUB #EDE9FE | 높음 (Luminance ~0.82) | 매우 밝은 회색으로 인식 |
| MAIN vs SUB 명도 대비 | 4.80:1 | SAFE - 충분한 명도 차이 |

**결론:** 모든 색맹 유형에서 MAIN과 SUB의 구분이 가능한다. 다만 Semantic 컬러(성공/오류)는 색상에만 의존하지 않고 반드시 아이콘 또는 텍스트 레이블을 병행한다.

---

## 7. Light Mode + Dark Mode 색상 적용 가이드

### 7.1 Light Mode

| 역할 | 토큰 | 값 |
|------|------|------|
| 페이지 배경 | `--bg-primary` | `#F8F7FB` (gray-50) |
| 카드 배경 | `--bg-card` | `#FFFFFF` |
| 카드 보더 | `--border-card` | `#E5E3E9` (gray-200) |
| 섹션 배경 | `--bg-section` | `#F1EFF4` (gray-100) |
| 제목 텍스트 | `--text-heading` | `#1C1B1E` (gray-900) |
| 본문 텍스트 | `--text-body` | `#49474C` (gray-700) |
| 보조 텍스트 | `--text-secondary` | `#5D5B60` (gray-600) |
| 캡션/힌트 | `--text-caption` | `#7B797F` (gray-500) |
| 플레이스홀더 | `--text-placeholder` | `#A19FA5` (gray-400) |
| 디바이더 | `--border-divider` | `#E5E3E9` (gray-200) |
| 입력 필드 배경 | `--bg-input` | `#F1EFF4` (gray-100) |
| 입력 필드 보더 | `--border-input` | `#D9D7DC` (gray-300) |
| CTA 버튼 배경 | `--bg-cta` | `#7C3AED` (MAIN) |
| CTA 버튼 텍스트 | `--text-cta` | `#FFFFFF` |
| 링크 | `--text-link` | `#7C3AED` (MAIN) |
| 뱃지 배경 | `--bg-badge` | `#EDE9FE` (SUB) |
| 뱃지 텍스트 | `--text-badge` | `#7C3AED` (MAIN) |

### 7.2 Dark Mode

| 역할 | 토큰 | 값 |
|------|------|------|
| 페이지 배경 | `--bg-primary` | `#1C1B1E` (gray-900) |
| 카드 배경 | `--bg-card` | `#2B2A2D` (gray-800) |
| 카드 보더 | `--border-card` | `#49474C` (gray-700) |
| 섹션 배경 | `--bg-section` | `#2B2A2D` (gray-800) |
| 제목 텍스트 | `--text-heading` | `#F8F7FB` (gray-50) |
| 본문 텍스트 | `--text-body` | `#E5E3E9` (gray-200) |
| 보조 텍스트 | `--text-secondary` | `#D9D7DC` (gray-300) |
| 캡션/힌트 | `--text-caption` | `#A19FA5` (gray-400) |
| 플레이스홀더 | `--text-placeholder` | `#7B797F` (gray-500) |
| 디바이더 | `--border-divider` | `#49474C` (gray-700) |
| 입력 필드 배경 | `--bg-input` | `#2B2A2D` (gray-800) |
| 입력 필드 보더 | `--border-input` | `#5D5B60` (gray-600) |
| CTA 버튼 배경 | `--bg-cta` | `#7C3AED` (MAIN) |
| CTA 버튼 텍스트 | `--text-cta` | `#FFFFFF` |
| 링크 | `--text-link` | `#A78BFA` (MAIN 밝은 변형) |
| 뱃지 배경 | `--bg-badge` | `rgba(124, 58, 237, 0.15)` |
| 뱃지 텍스트 | `--text-badge` | `#A78BFA` (MAIN 밝은 변형) |

### 7.3 Glassmorphism Mode (그라디언트 배경)

| 역할 | 토큰 | 값 |
|------|------|------|
| 앱 배경 그라디언트 | `--bg-gradient` | `linear-gradient(135deg, #667EEA 0%, #764BA2 40%, #F093FB 100%)` |
| 유리 카드 배경 | `--bg-glass` | `rgba(255, 255, 255, 0.15)` |
| 유리 카드 보더 | `--border-glass` | `rgba(255, 255, 255, 0.25)` |
| 유리 블러 | `--glass-blur` | `blur(20px)` |
| 유리 그림자 | `--glass-shadow` | `0 8px 32px rgba(0, 0, 0, 0.1)` |
| 텍스트 (유리 위) | `--text-glass-primary` | `#FFFFFF` |
| 보조 텍스트 (유리 위) | `--text-glass-secondary` | `rgba(255, 255, 255, 0.7)` |
| 캡션 (유리 위) | `--text-glass-caption` | `rgba(255, 255, 255, 0.5)` |
| CTA 버튼 (유리 위) | `--bg-glass-cta` | `rgba(255, 255, 255, 0.25)` |
| 활성 네비게이션 | `--bg-glass-active` | `rgba(255, 255, 255, 0.25)` |

---

## 8. Semantic Colors

### 8.1 Light Mode Semantic

| 역할 | 기본 HEX | 배경 (10% opacity) | 텍스트/아이콘 (진한) |
|------|---------|-------------------|-------------------|
| Success (성공) | `#22C55E` | `rgba(34, 197, 94, 0.1)` | `#16A34A` |
| Warning (경고) | `#F59E0B` | `rgba(245, 158, 11, 0.1)` | `#D97706` |
| Error (오류) | `#EF4444` | `rgba(239, 68, 68, 0.1)` | `#DC2626` |
| Info (정보) | `#3B82F6` | `rgba(59, 130, 246, 0.1)` | `#2563EB` |

### 8.2 Dark Mode Semantic

| 역할 | 기본 HEX | 배경 (15% opacity) | 텍스트/아이콘 (밝은) |
|------|---------|-------------------|-------------------|
| Success (성공) | `#22C55E` | `rgba(34, 197, 94, 0.15)` | `#4ADE80` |
| Warning (경고) | `#F59E0B` | `rgba(245, 158, 11, 0.15)` | `#FBBF24` |
| Error (오류) | `#EF4444` | `rgba(239, 68, 68, 0.15)` | `#F87171` |
| Info (정보) | `#3B82F6` | `rgba(59, 130, 246, 0.15)` | `#60A5FA` |

### 8.3 Glassmorphism Mode Semantic

| 역할 | 배경 | 보더 | 텍스트 |
|------|------|------|--------|
| Success | `rgba(76, 217, 100, 0.4)` | `rgba(76, 217, 100, 0.6)` | `#FFFFFF` |
| Warning | `rgba(245, 158, 11, 0.4)` | `rgba(245, 158, 11, 0.6)` | `#FFFFFF` |
| Error | `rgba(255, 69, 58, 0.25)` | `rgba(255, 69, 58, 0.4)` | `#FFFFFF` |
| Info | `rgba(59, 130, 246, 0.4)` | `rgba(59, 130, 246, 0.6)` | `#FFFFFF` |

### 8.3 Semantic WCAG 대비비

**Light Mode (텍스트/아이콘 진한 변형 on White):**

| 역할 | HEX | 대비비 | AA |
|------|------|--------|-----|
| Success Text | `#16A34A` | 3.30:1 | AA-Large PASS (아이콘/레이블용) |
| Warning Text | `#D97706` | 3.19:1 | AA-Large PASS (아이콘/레이블용) |
| Error Text | `#DC2626` | 4.83:1 | AA PASS |
| Info Text | `#2563EB` | 5.17:1 | AA PASS |

**Dark Mode (텍스트/아이콘 밝은 변형 on gray-900):**

| 역할 | HEX | 대비비 | AA |
|------|------|--------|-----|
| Success Text | `#4ADE80` | 9.84:1 | AAA PASS |
| Warning Text | `#FBBF24` | 10.27:1 | AAA PASS |
| Error Text | `#F87171` | 6.20:1 | AA PASS |
| Info Text | `#60A5FA` | 6.74:1 | AA PASS |

---

## 9. 캘린더 이벤트/일정 색상 팔레트 (8색)

캘린더에서 다양한 일정 유형을 시각적으로 구분하기 위한 8가지 색상을 정의한다.
모든 색상은 MAIN 컬러(Violet)와 시각적 조화를 이루며, 색맹 사용자도 구분 가능하도록 명도 차이를 확보한다.

### 9.1 Light Mode 이벤트 색상

| ID | 카테고리 | HEX | 배경 (15% opacity) | 심리/용도 |
|----|---------|------|-------------------|----------|
| `work` | 업무/회의 | `#7C3AED` | `rgba(124, 58, 237, 0.15)` | MAIN 컬러 - 가장 중요한 업무 카테고리 |
| `personal` | 개인 일정 | `#EC4899` | `rgba(236, 72, 153, 0.15)` | 핑크 - 그라디언트 스펙트럼에서 따뜻한 개인적 느낌 |
| `study` | 학습/공부 | `#3B82F6` | `rgba(59, 130, 246, 0.15)` | 블루 - 집중, 학습, 지적 활동 |
| `health` | 운동/건강 | `#22C55E` | `rgba(34, 197, 94, 0.15)` | 그린 - 건강, 활력, 자연 |
| `social` | 약속/모임 | `#F59E0B` | `rgba(245, 158, 11, 0.15)` | 앰버 - 따뜻함, 사교, 즐거움 |
| `finance` | 재무/금융 | `#06B6D4` | `rgba(6, 182, 212, 0.15)` | 시안 - 안정, 신뢰, 재정 관리 |
| `creative` | 창작/취미 | `#F97316` | `rgba(249, 115, 22, 0.15)` | 오렌지 - 에너지, 창의성, 열정 |
| `important` | 중요/긴급 | `#EF4444` | `rgba(239, 68, 68, 0.15)` | 레드 - 주의, 긴급, 마감 |

### 9.2 Dark Mode 이벤트 색상

| ID | 카테고리 | HEX (밝은 변형) | 배경 (20% opacity) |
|----|---------|----------------|-------------------|
| `work` | 업무/회의 | `#A78BFA` | `rgba(167, 139, 250, 0.20)` |
| `personal` | 개인 일정 | `#F472B6` | `rgba(244, 114, 182, 0.20)` |
| `study` | 학습/공부 | `#60A5FA` | `rgba(96, 165, 250, 0.20)` |
| `health` | 운동/건강 | `#4ADE80` | `rgba(74, 222, 128, 0.20)` |
| `social` | 약속/모임 | `#FBBF24` | `rgba(251, 191, 36, 0.20)` |
| `finance` | 재무/금융 | `#22D3EE` | `rgba(34, 211, 238, 0.20)` |
| `creative` | 창작/취미 | `#FB923C` | `rgba(251, 146, 60, 0.20)` |
| `important` | 중요/긴급 | `#F87171` | `rgba(248, 113, 113, 0.20)` |

### 9.3 이벤트 색상 WCAG 대비비

**Light Mode (색상 dot/indicator on White):**

| ID | 대비비 | AA-Large |
|----|--------|---------|
| work | 5.70:1 | PASS |
| personal | 3.50:1 | PASS |
| study | 3.68:1 | PASS |
| health | 2.28:1 | 색상 도트 + 텍스트 레이블 병행 |
| social | 2.15:1 | 색상 도트 + 텍스트 레이블 병행 |
| finance | 2.43:1 | 색상 도트 + 텍스트 레이블 병행 |
| creative | 2.82:1 | 색상 도트 + 텍스트 레이블 병행 |
| important | 3.76:1 | PASS |

**Dark Mode (밝은 변형 on gray-900):**

| ID | 대비비 | AA |
|----|--------|-----|
| work | 6.30:1 | PASS |
| personal | 6.47:1 | PASS |
| study | 6.74:1 | PASS |
| health | 9.84:1 | PASS |
| social | 10.27:1 | PASS |
| finance | 9.49:1 | PASS |
| creative | 7.58:1 | PASS |
| important | 6.20:1 | PASS |

### 9.4 색맹 구분성

8가지 이벤트 색상은 Hue가 충분히 분산되어 있으며(약 45도 간격), 명도 차이를 추가로 확보하여 색맹 사용자도 구분 가능한다.
다만, 접근성 완전 보장을 위해 모든 이벤트 표시에 색상 + 카테고리 텍스트 레이블 + 아이콘을 함께 사용한다.

---

## 10. CSS Custom Properties (구현 참조)

```css
:root {
  /* MAIN + SUB */
  --color-main: #7C3AED;
  --color-main-hover: #6A2DD3;
  --color-main-pressed: #5B24BA;
  --color-main-disabled: rgba(124, 58, 237, 0.4);
  --color-main-focus: rgba(124, 58, 237, 0.5);
  --color-main-light: #A78BFA;
  --color-sub: #EDE9FE;
  --color-sub-light: #FDFCFE;
  --color-sub-hover: #DDD8F1;

  /* Tinted Grey */
  --gray-50: #F8F7FB;
  --gray-100: #F1EFF4;
  --gray-200: #E5E3E9;
  --gray-300: #D9D7DC;
  --gray-400: #A19FA5;
  --gray-500: #7B797F;
  --gray-600: #5D5B60;
  --gray-700: #49474C;
  --gray-800: #2B2A2D;
  --gray-900: #1C1B1E;

  /* Semantic */
  --color-success: #22C55E;
  --color-success-light: #4ADE80;
  --color-success-dark: #16A34A;
  --color-warning: #F59E0B;
  --color-warning-light: #FBBF24;
  --color-warning-dark: #D97706;
  --color-error: #EF4444;
  --color-error-light: #F87171;
  --color-error-dark: #DC2626;
  --color-info: #3B82F6;
  --color-info-light: #60A5FA;
  --color-info-dark: #2563EB;

  /* Event Colors */
  --event-work: #7C3AED;
  --event-personal: #EC4899;
  --event-study: #3B82F6;
  --event-health: #22C55E;
  --event-social: #F59E0B;
  --event-finance: #06B6D4;
  --event-creative: #F97316;
  --event-important: #EF4444;

  /* Glassmorphism */
  --gradient-start: #667EEA;
  --gradient-mid: #764BA2;
  --gradient-end: #F093FB;
  --glass-bg: rgba(255, 255, 255, 0.15);
  --glass-border: rgba(255, 255, 255, 0.25);
  --glass-blur: blur(20px);
  --glass-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
}
```

### Flutter 컬러 토큰 참조

```dart
// MAIN + SUB
static const Color main = Color(0xFF7C3AED);
static const Color mainHover = Color(0xFF6A2DD3);
static const Color mainPressed = Color(0xFF5B24BA);
static const Color mainLight = Color(0xFFA78BFA);
static const Color sub = Color(0xFFEDE9FE);
static const Color subLight = Color(0xFFFDFCFE);
static const Color subHover = Color(0xFFDDD8F1);

// Tinted Grey
static const Color gray50 = Color(0xFFF8F7FB);
static const Color gray100 = Color(0xFFF1EFF4);
static const Color gray200 = Color(0xFFE5E3E9);
static const Color gray300 = Color(0xFFD9D7DC);
static const Color gray400 = Color(0xFFA19FA5);
static const Color gray500 = Color(0xFF7B797F);
static const Color gray600 = Color(0xFF5D5B60);
static const Color gray700 = Color(0xFF49474C);
static const Color gray800 = Color(0xFF2B2A2D);
static const Color gray900 = Color(0xFF1C1B1E);
```

---

## 11. 핵심 규칙 요약

1. **2색 원칙**: UI 요소에는 MAIN(`#7C3AED`) + SUB(`#EDE9FE`) + Tinted Grey 팔레트만 사용한다.
2. **순수 무채색 금지**: `#000000`, `#333333`, `#666666` 등 Saturation 0% 색상을 절대 사용하지 않는다.
3. **Glassmorphism 그라디언트**: 배경 그라디언트(`#667EEA` - `#764BA2` - `#F093FB`)는 앱 배경 전용이며, UI 컴포넌트 색상으로 사용하지 않는다.
4. **Semantic 색상**: Success, Warning, Error, Info는 표준 값을 사용하며 장식적 용도로 쓰지 않는다.
5. **접근성 필수**: 모든 텍스트는 WCAG AA 이상 대비비를 확보한다. 색상만으로 정보를 전달하지 않는다.
6. **이벤트 색상**: 캘린더 이벤트 8색은 정의된 팔레트만 사용하며, 사용자 임의 색상 추가 시에도 이 팔레트 내에서 선택하도록 제한한다.
7. **구현 에이전트 규칙**: 하드코딩 금지. 반드시 CSS Custom Properties 또는 Flutter 컬러 토큰을 통해 참조한다.
