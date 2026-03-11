# 라이선스 검증 보고서

**프로젝트명**: Design Your Life
**프로젝트 목적**: 상업용 (Google Play Store + Firebase Hosting 웹 배포)
**검증일**: 2026-03-09
**검증 대상**: 전체 기술 스택 (프레임워크, 패키지, 서비스, 폰트)

---

## 1. 종합 판정

| 항목 | 결과 |
|---|---|
| 프레임워크 라이선스 | GREEN - 전체 안전 |
| 패키지 라이선스 | GREEN - 전체 안전 |
| 서비스 이용약관 | GREEN - 상업적 사용 허용 |
| 폰트 라이선스 | GREEN - 상업적 사용 허용 |
| 라이선스 간 충돌 | 없음 |
| **최종 판정** | **GREEN - 상업적 배포에 전면 적합함** |

---

## 2. 프레임워크 및 런타임 라이선스

| 기술 | 라이선스 | 판정 | 상업적 사용 | 비고 |
|---|---|---|---|---|
| Flutter 3.29 | BSD-3-Clause | GREEN | 허용 | Google 개발, 저작권 고지 필요 |
| Dart SDK | BSD-3-Clause | GREEN | 허용 | Flutter 포함 |

BSD-3-Clause는 허용적(permissive) 라이선스로, 상업적 사용/수정/배포가 자유롭다. 저작권 고지와 라이선스 문구를 앱 내 또는 배포물에 포함하면 된다.

---

## 3. 패키지별 라이선스 상세

### 3.1 상태 관리

| 패키지 | 라이선스 | 판정 | 저작권자 | 귀속 표기 필요 |
|---|---|---|---|---|
| flutter_riverpod 2.6 | MIT | GREEN | Remi Rousselet | 필요 (MIT 조건) |

MIT 라이선스는 가장 허용적인 오픈소스 라이선스 중 하나다. 저작권 고지와 라이선스 사본을 포함하면 상업적 사용에 제한이 없다.

### 3.2 라우팅

| 패키지 | 라이선스 | 판정 | 저작권자 | 귀속 표기 필요 |
|---|---|---|---|---|
| go_router 14.x | BSD-3-Clause | GREEN | Flutter Authors | 필요 (BSD 조건) |

Flutter 공식 패키지로, Flutter 프레임워크와 동일한 BSD-3-Clause 라이선스를 따른다.

### 3.3 Firebase 관련 패키지

| 패키지 | 라이선스 | 판정 | 저작권자 | 귀속 표기 필요 |
|---|---|---|---|---|
| firebase_core | BSD-3-Clause | GREEN | Google LLC | 필요 (BSD 조건) |
| firebase_auth | BSD-3-Clause | GREEN | Google LLC | 필요 (BSD 조건) |
| cloud_firestore | BSD-3-Clause | GREEN | Google LLC | 필요 (BSD 조건) |

모든 Firebase Flutter 플러그인은 BSD-3-Clause 라이선스를 따른다. 단, 이것은 클라이언트 SDK의 라이선스이며, Firebase 서비스 자체는 별도의 이용약관(Firebase Terms of Service)을 따른다. 서비스 이용약관은 섹션 4에서 별도로 검증한다.

### 3.4 로컬 캐시

| 패키지 | 라이선스 | 판정 | 저작권자 | 귀속 표기 필요 |
|---|---|---|---|---|
| hive 4.x | Apache-2.0 | GREEN | Simon Leier | 필요 (Apache 조건) |

Apache-2.0은 상업적 사용이 자유로운 허용적 라이선스다. MIT/BSD보다 조건이 약간 많다:
- 저작권 고지 포함 필수
- 변경 사항 명시 필요 (수정한 경우)
- 특허 사용 권한이 명시적으로 부여됨 (장점)
- NOTICE 파일이 있으면 해당 내용도 포함 필수

### 3.5 UI 위젯

| 패키지 | 라이선스 | 판정 | 저작권자 | 귀속 표기 필요 |
|---|---|---|---|---|
| table_calendar | Apache-2.0 | GREEN | Aleksander Wozniak | 필요 (Apache 조건) |
| fl_chart | MIT | GREEN | Iman Khoshabi | 필요 (MIT 조건) |

두 패키지 모두 상업적 사용에 안전하다.

### 3.6 유틸리티

| 패키지 | 라이선스 | 판정 | 저작권자 | 귀속 표기 필요 |
|---|---|---|---|---|
| intl | BSD-3-Clause | GREEN | Dart Authors | 필요 (BSD 조건) |
| google_fonts | BSD-3-Clause | GREEN | Google LLC | 필요 (BSD 조건) |

두 패키지 모두 Dart/Google 공식 패키지로, BSD-3-Clause 라이선스를 따른다.

---

## 4. 서비스 이용약관 검증

### 4.1 Firebase 서비스

| 서비스 | 상업적 사용 | 비용 구조 | 비고 |
|---|---|---|---|
| Firebase Auth | GREEN - 허용 | 무료 티어 존재, 초과 시 과금 | Google 로그인 포함 |
| Cloud Firestore | GREEN - 허용 | 읽기/쓰기/저장 기반 과금 | GCP 이용약관 적용 |
| Firebase Hosting | GREEN - 허용 | 대역폭/저장 기반 과금 | 웹 배포용 |

Firebase Terms of Service는 상업적 사용을 명시적으로 허용한다. "trade, business, craft, or profession" 관련 목적의 사용임을 동의하는 조항이 포함되어 있다.

주의 사항:
- 무료 티어(Spark Plan) 한도를 초과하면 Blaze Plan(종량제)으로 전환해야 한다
- Firebase Paid Services Agreement에 따라 결제 정보를 등록해야 한다
- 서비스별 사용량 제한과 요금 체계를 사전에 확인해야 한다

### 4.2 Google Play Store

Google Play Store 배포 시 추가 고려 사항:
- Google Play Developer 계정 등록비: $25 (일회성)
- Google Play 개발자 배포 계약 준수 필요
- 인앱 결제 시 Google 수수료 (15~30%) 적용
- 개인정보 처리방침 필수 제공

---

## 5. 폰트 라이선스 검증

| 폰트 | 라이선스 | 판정 | 상업적 사용 | 비고 |
|---|---|---|---|---|
| Pretendard | SIL Open Font License 1.1 | GREEN | 허용 | 단독 판매 불가, 소프트웨어 번들은 허용 |
| Google Fonts (전체) | SIL OFL / Apache-2.0 | GREEN | 허용 | 폰트별 개별 라이선스 확인 권장 |

Pretendard 폰트는 SIL Open Font License 1.1을 따르며, 상업용 앱에 번들링하여 사용하는 것이 허용된다. 폰트 자체를 단독 상품으로 판매하는 것만 금지된다.

google_fonts 패키지를 통해 사용하는 모든 Google Fonts는 오픈소스이며 상업적 사용이 무료다.

---

## 6. 라이선스 호환성 분석

본 기술 스택에 사용된 라이선스 유형은 다음과 같다:

| 라이선스 | 사용 패키지 수 | 호환성 |
|---|---|---|
| BSD-3-Clause | 7개 | 모든 라이선스와 호환 |
| MIT | 2개 | 모든 라이선스와 호환 |
| Apache-2.0 | 2개 | MIT, BSD와 호환 |
| SIL OFL 1.1 | 1개 (폰트) | 소프트웨어 라이선스와 독립적 |

**충돌 여부: 없음**

BSD-3-Clause, MIT, Apache-2.0은 모두 허용적(permissive) 라이선스 계열에 속하며, 상호 간 호환성 문제가 없다. GPL 계열의 바이럴(copyleft) 라이선스가 포함되어 있지 않으므로, 전체 코드베이스를 독점(proprietary) 소프트웨어로 배포하는 데 법적 장애가 없다.

SIL Open Font License는 폰트에 특화된 라이선스로, 소프트웨어 코드 라이선스와는 별개의 영역이다.

---

## 7. 귀속 표기(Attribution) 요구 사항

상업적 배포 시 다음 귀속 표기 의무가 존재한다:

### 7.1 필수 조치

1. **앱 내 "라이선스" 또는 "오픈소스 라이선스" 화면을 포함해야 한다**
   - Flutter는 `LicensePage` 위젯을 기본 제공하며, 모든 패키지의 라이선스를 자동 수집하여 표시한다
   - `showLicensePage()` 또는 `LicensePage()` 위젯을 설정 화면에 포함하면 된다

2. **NOTICE 파일을 프로젝트 루트에 유지해야 한다**
   - Apache-2.0 라이선스 패키지(Hive, table_calendar)는 NOTICE 파일이 존재하면 해당 내용을 포함해야 한다

3. **각 라이선스의 저작권 고지를 보존해야 한다**
   - 소스 코드 재배포 시 원본 저작권 고지를 제거하면 안 된다

### 7.2 BSD-3-Clause 고유 조건

BSD-3-Clause 라이선스 패키지(Flutter, go_router, Firebase 플러그인, intl, google_fonts)는 다음 조건을 추가로 준수해야 한다:
- 저작권자의 이름을 사전 서면 허가 없이 제품 홍보에 사용하면 안 된다

### 7.3 SIL OFL 고유 조건 (Pretendard)

- Pretendard 폰트를 단독으로 판매할 수 없다 (앱에 번들링하는 것은 허용)
- 원본 저작권 고지와 라이선스 사본을 번들에 포함해야 한다

---

## 8. 리스크 요약

| 영역 | 리스크 등급 | 설명 |
|---|---|---|
| 프레임워크 | GREEN | BSD-3-Clause, 완전히 안전함 |
| 상태 관리 | GREEN | MIT, 완전히 안전함 |
| 라우팅 | GREEN | BSD-3-Clause, 완전히 안전함 |
| Firebase SDK | GREEN | BSD-3-Clause, 완전히 안전함 |
| Firebase 서비스 | GREEN | 상업적 사용 허용, 사용량 기반 과금 |
| 로컬 캐시 | GREEN | Apache-2.0, 특허 보호 포함 |
| UI 위젯 | GREEN | Apache-2.0 / MIT, 안전함 |
| 유틸리티 | GREEN | BSD-3-Clause, 안전함 |
| 폰트 | GREEN | SIL OFL 1.1, 번들링 사용 허용 |
| 라이선스 호환성 | GREEN | 충돌 없음 |

**전체 기술 스택은 상업적 배포(Google Play Store + Firebase Hosting)에 완전히 적합하다.**

---

## 9. 최종 권장 기술 스택 (라이선스 검증 완료)

| 구분 | 기술 | 라이선스 | 판정 |
|---|---|---|---|
| 프레임워크 | Flutter 3.29 (Stable) | BSD-3-Clause | GREEN |
| 언어 | Dart SDK | BSD-3-Clause | GREEN |
| 상태 관리 | Riverpod 2.6 | MIT | GREEN |
| 라우팅 | GoRouter 14.x | BSD-3-Clause | GREEN |
| 인증 | Firebase Auth | BSD-3-Clause (SDK) | GREEN |
| 데이터베이스 | Cloud Firestore | BSD-3-Clause (SDK) | GREEN |
| 웹 배포 | Firebase Hosting | 서비스 이용약관 | GREEN |
| 로컬 캐시 | Hive 4.x | Apache-2.0 | GREEN |
| 캘린더 UI | table_calendar | Apache-2.0 | GREEN |
| 차트 | fl_chart | MIT | GREEN |
| 국제화 | intl | BSD-3-Clause | GREEN |
| 폰트 패키지 | google_fonts | BSD-3-Clause | GREEN |
| 폰트 | Pretendard | SIL OFL 1.1 | GREEN |

**모든 기술 선택이 라이선스 관점에서 승인되었다. 상업적 배포를 진행해도 된다.**

---

## 10. 권장 조치 체크리스트

- [ ] 앱 설정 화면에 Flutter `LicensePage` 위젯 포함
- [ ] 프로젝트 루트에 NOTICE 파일 생성 (Apache-2.0 패키지 귀속 표기)
- [ ] Pretendard 폰트 저작권 고지를 앱 라이선스 화면에 포함
- [ ] Firebase Blaze Plan 전환 시점 및 예상 비용 사전 검토
- [ ] Google Play 개발자 계정 등록 및 개인정보 처리방침 준비
- [ ] 배포 전 `flutter pub run flutter_oss_licenses:generate` 등으로 전체 라이선스 목록 자동 생성 검토
