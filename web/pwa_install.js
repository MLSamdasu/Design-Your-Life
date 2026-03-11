/**
 * PWA 커스텀 설치 프롬프트
 *
 * 브라우저의 기본 설치 배너 대신 앱 디자인에 맞는 커스텀 배너를 표시한다.
 * 방문 횟수(3회 이상) 또는 체류 시간(2분 이상)을 조건으로 배너를 노출한다.
 * iOS Safari는 Web Install API를 지원하지 않으므로 별도 안내 메시지를 표시한다.
 */

(function () {
  'use strict';

  // ── 상수 정의 ──────────────────────────────────────────────────────────────

  /** localStorage 키: 설치 완료 또는 영구 닫기 여부 */
  var STORAGE_KEY_DISMISSED = 'dyl_pwa_install_dismissed';

  /** localStorage 키: 누적 방문 횟수 */
  var STORAGE_KEY_VISIT_COUNT = 'dyl_pwa_visit_count';

  /** 배너를 표시하기 위한 최소 방문 횟수 */
  var MIN_VISIT_COUNT = 3;

  /** 배너를 표시하기 위한 최소 체류 시간 (밀리초, 2분) */
  var MIN_DWELL_MS = 2 * 60 * 1000;

  /** 앱 메인 퍼플 컬러 (디자인 토큰: --color-primary) */
  var COLOR_PRIMARY = '#7C3AED';

  // ── 전역 상태 ──────────────────────────────────────────────────────────────

  /** beforeinstallprompt 이벤트 객체를 저장한다 */
  var deferredPrompt = null;

  /** 배너 DOM 요소 참조 */
  var banner = null;

  /** 페이지 진입 시각 (체류 시간 계산용) */
  var pageEntryTime = Date.now();

  /** 체류 시간 조건 충족 여부를 주기적으로 확인하는 타이머 ID */
  var dwellTimerId = null;

  // ── 유틸리티 함수 ──────────────────────────────────────────────────────────

  /**
   * 이미 PWA로 실행 중인지 확인한다.
   * standalone 모드이거나 iOS의 navigator.standalone이 true이면 설치된 상태다.
   * @returns {boolean} PWA로 실행 중이면 true
   */
  function isRunningAsStandalone() {
    var isStandaloneMedia = window.matchMedia('(display-mode: standalone)').matches;
    var isIosStandalone = /** @type {any} */ (window.navigator).standalone === true;
    return isStandaloneMedia || isIosStandalone;
  }

  /**
   * 사용자가 이미 배너를 닫았거나 설치를 완료했는지 확인한다.
   * @returns {boolean} 배너를 더 이상 표시하지 않아야 하면 true
   */
  function isDismissed() {
    return localStorage.getItem(STORAGE_KEY_DISMISSED) === 'true';
  }

  /**
   * 배너 닫기 상태를 localStorage에 저장한다.
   */
  function saveDismissed() {
    localStorage.setItem(STORAGE_KEY_DISMISSED, 'true');
  }

  /**
   * 현재 방문을 기록하고 누적 방문 횟수를 반환한다.
   * @returns {number} 업데이트 후의 방문 횟수
   */
  function incrementAndGetVisitCount() {
    var count = parseInt(localStorage.getItem(STORAGE_KEY_VISIT_COUNT) || '0', 10);
    count += 1;
    localStorage.setItem(STORAGE_KEY_VISIT_COUNT, String(count));
    return count;
  }

  /**
   * iOS Safari 환경인지 확인한다.
   * User Agent 기반으로 판단하므로 완벽하지 않지만 실용적인 수준이다.
   * @returns {boolean} iOS Safari이면 true
   */
  function isIosSafari() {
    var ua = window.navigator.userAgent;
    var isIos = /iPad|iPhone|iPod/.test(ua);
    // Chrome, Firefox on iOS는 다른 UA를 가진다
    var isSafari = /Safari/.test(ua) && !/CriOS|FxiOS|EdgiOS/.test(ua);
    return isIos && isSafari;
  }

  // ── 배너 UI 생성 ───────────────────────────────────────────────────────────

  /**
   * 스타일 문자열 배열을 CSS 인라인 스타일 문자열로 변환하는 헬퍼 함수.
   * @param {string[]} rules - CSS 선언 배열
   * @returns {string} 세미콜론으로 연결된 CSS 문자열
   */
  function buildStyle(rules) {
    return rules.join('; ');
  }

  /**
   * 닫기(X) 버튼 요소를 생성한다.
   * @param {function} onClick - 클릭 시 실행할 콜백
   * @returns {HTMLButtonElement} 닫기 버튼
   */
  function createDismissButton(onClick) {
    var btn = document.createElement('button');
    btn.style.cssText = buildStyle([
      'background: transparent',
      'border: none',
      'color: rgba(255, 255, 255, 0.75)',
      'font-size: 20px',
      'line-height: 1',
      'padding: 4px',
      'cursor: pointer',
      'border-radius: 4px',
    ]);
    btn.setAttribute('aria-label', '닫기');
    btn.textContent = '✕';
    btn.addEventListener('click', onClick);
    return btn;
  }

  /**
   * 일반(Android/데스크톱) 환경용 설치 배너를 생성하여 DOM에 추가한다.
   * beforeinstallprompt 이벤트가 저장된 경우에만 의미가 있다.
   */
  function createInstallBanner() {
    if (banner) return; // 중복 생성 방지

    banner = document.createElement('div');
    banner.id = 'pwa-install-banner';
    banner.style.cssText = buildStyle([
      'position: fixed',
      'bottom: 0',
      'left: 0',
      'right: 0',
      'z-index: 9999',
      'display: flex',
      'align-items: center',
      'justify-content: space-between',
      'padding: 12px 16px',
      'background-color: ' + COLOR_PRIMARY,
      'color: #ffffff',
      'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
      'font-size: 14px',
      'box-shadow: 0 -2px 12px rgba(0, 0, 0, 0.25)',
      'gap: 12px',
    ]);

    // 왼쪽 영역: 앱 소개 텍스트
    var textArea = document.createElement('div');
    textArea.style.cssText = 'flex: 1; line-height: 1.4;';

    var title = document.createElement('div');
    title.style.cssText = 'font-weight: 600; font-size: 15px;';
    title.textContent = 'Design Your Life 설치';

    var subtitle = document.createElement('div');
    subtitle.style.cssText = 'font-size: 12px; opacity: 0.85; margin-top: 2px;';
    subtitle.textContent = '홈 화면에 추가하면 더 빠르게 접근할 수 있어요';

    textArea.appendChild(title);
    textArea.appendChild(subtitle);

    // 오른쪽 영역: 버튼 그룹
    var buttonArea = document.createElement('div');
    buttonArea.style.cssText = 'display: flex; align-items: center; gap: 8px; flex-shrink: 0;';

    // 닫기 버튼: 이번 세션만 숨김 (재방문 시 다시 표시 가능)
    var dismissBtn = createDismissButton(function () {
      hideBanner();
    });

    // 설치 버튼
    var installBtn = document.createElement('button');
    installBtn.style.cssText = buildStyle([
      'background: #ffffff',
      'color: ' + COLOR_PRIMARY,
      'border: none',
      'border-radius: 20px',
      'padding: 8px 16px',
      'font-size: 13px',
      'font-weight: 600',
      'cursor: pointer',
      'white-space: nowrap',
    ]);
    installBtn.textContent = '홈 화면에 추가';
    installBtn.addEventListener('click', function () {
      triggerInstallPrompt();
    });

    buttonArea.appendChild(dismissBtn);
    buttonArea.appendChild(installBtn);

    banner.appendChild(textArea);
    banner.appendChild(buttonArea);
    document.body.appendChild(banner);
  }

  /**
   * iOS Safari 전용 안내 배너를 생성하여 DOM에 추가한다.
   * iOS는 beforeinstallprompt를 지원하지 않으므로 수동 안내를 제공한다.
   * DOM API만 사용하여 XSS 위험 없이 요소를 구성한다.
   */
  function createIosGuidanceBanner() {
    if (banner) return; // 중복 생성 방지

    banner = document.createElement('div');
    banner.id = 'pwa-install-banner-ios';
    banner.style.cssText = buildStyle([
      'position: fixed',
      'bottom: 0',
      'left: 0',
      'right: 0',
      'z-index: 9999',
      'padding: 14px 16px',
      'background-color: ' + COLOR_PRIMARY,
      'color: #ffffff',
      'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
      'font-size: 14px',
      'box-shadow: 0 -2px 12px rgba(0, 0, 0, 0.25)',
    ]);

    // 상단 행: 제목 + 닫기 버튼
    var headerRow = document.createElement('div');
    headerRow.style.cssText = buildStyle([
      'display: flex',
      'align-items: center',
      'justify-content: space-between',
      'margin-bottom: 8px',
    ]);

    var title = document.createElement('span');
    title.style.cssText = 'font-weight: 600; font-size: 15px;';
    title.textContent = 'Design Your Life 설치';

    // iOS 닫기 버튼: 영구 저장하여 재방문 시 재표시 방지
    var dismissBtn = createDismissButton(function () {
      hideBanner();
      saveDismissed();
    });

    headerRow.appendChild(title);
    headerRow.appendChild(dismissBtn);

    // 안내 메시지: DOM API로 구성하여 XSS 위험 없이 강조 텍스트 표현
    var guide = document.createElement('div');
    guide.style.cssText = 'font-size: 13px; line-height: 1.6; opacity: 0.92;';

    var line1 = document.createElement('div');
    var line1Prefix = document.createTextNode('하단의 ');
    var line1Bold = document.createElement('strong');
    line1Bold.textContent = '공유 버튼(↑)';
    var line1Suffix = document.createTextNode('을 탭한 후');
    line1.appendChild(line1Prefix);
    line1.appendChild(line1Bold);
    line1.appendChild(line1Suffix);

    var line2 = document.createElement('div');
    var line2Bold = document.createElement('strong');
    line2Bold.textContent = '홈 화면에 추가';
    var line2Suffix = document.createTextNode('를 선택하세요');
    line2.appendChild(line2Bold);
    line2.appendChild(line2Suffix);

    guide.appendChild(line1);
    guide.appendChild(line2);

    banner.appendChild(headerRow);
    banner.appendChild(guide);
    document.body.appendChild(banner);
  }

  /**
   * 배너를 화면에서 숨긴다 (DOM에서 제거).
   */
  function hideBanner() {
    if (banner && banner.parentNode) {
      banner.parentNode.removeChild(banner);
      banner = null;
    }
    if (dwellTimerId !== null) {
      clearTimeout(dwellTimerId);
      dwellTimerId = null;
    }
  }

  // ── 설치 프롬프트 실행 ─────────────────────────────────────────────────────

  /**
   * 저장된 beforeinstallprompt 이벤트를 통해 브라우저 설치 다이얼로그를 표시한다.
   * 사용자 선택 결과를 확인하여 설치 완료 시 배너를 영구 숨김 처리한다.
   */
  function triggerInstallPrompt() {
    if (!deferredPrompt) return;

    deferredPrompt.prompt();

    deferredPrompt.userChoice.then(function (choiceResult) {
      if (choiceResult.outcome === 'accepted') {
        // 설치 완료: 다시는 배너를 표시하지 않는다
        saveDismissed();
      }
      // 거부의 경우에도 현재 배너는 닫는다 (재방문 시 다시 표시 가능)
      deferredPrompt = null;
      hideBanner();
    });
  }

  // ── 표시 조건 판단 ─────────────────────────────────────────────────────────

  /**
   * 배너 표시 조건(방문 횟수 또는 체류 시간)이 충족되었는지 확인하여
   * 조건이 맞으면 배너를 생성한다.
   */
  function tryShowBanner() {
    if (isRunningAsStandalone() || isDismissed()) return;

    if (isIosSafari()) {
      createIosGuidanceBanner();
    } else {
      // deferredPrompt가 없으면 브라우저가 아직 설치 가능 상태로 판단하지 않은 것이다
      if (!deferredPrompt) return;
      createInstallBanner();
    }
  }

  /**
   * 체류 시간 조건을 비동기로 확인한다.
   * MIN_DWELL_MS 경과 후에도 배너가 없으면 배너 표시를 시도한다.
   */
  function scheduleDwellCheck() {
    var remaining = MIN_DWELL_MS - (Date.now() - pageEntryTime);
    var delay = remaining > 0 ? remaining : 0;

    dwellTimerId = setTimeout(function () {
      dwellTimerId = null;
      if (banner) return; // 이미 방문 횟수 조건으로 표시됨
      tryShowBanner();
    }, delay);
  }

  // ── 초기화 ─────────────────────────────────────────────────────────────────

  /**
   * PWA 설치 프롬프트 모듈을 초기화한다.
   * DOM이 완성된 후 실행되어야 한다.
   */
  function init() {
    // 이미 PWA로 실행 중이면 아무것도 하지 않는다
    if (isRunningAsStandalone()) return;

    // 이전에 영구 닫기를 선택한 경우 표시하지 않는다
    if (isDismissed()) return;

    // 방문 횟수 기록
    var visitCount = incrementAndGetVisitCount();

    // 체류 시간 조건 대기 타이머 시작 (방문 횟수 조건 미충족 시 대안 트리거)
    scheduleDwellCheck();

    // beforeinstallprompt 이벤트 리스너 등록
    // 브라우저가 PWA 설치 가능하다고 판단하면 이 이벤트가 발생한다
    window.addEventListener('beforeinstallprompt', function (event) {
      // 브라우저 기본 설치 배너를 막고 이벤트 객체를 저장한다
      event.preventDefault();
      deferredPrompt = event;

      // 방문 횟수 조건이 이미 충족된 경우 즉시 배너를 표시한다
      if (visitCount >= MIN_VISIT_COUNT && !banner) {
        tryShowBanner();
      }
    });

    // 설치 완료 이벤트 리스너 등록
    // 사용자가 외부 방법(브라우저 주소창 등)으로 설치한 경우도 처리한다
    window.addEventListener('appinstalled', function () {
      saveDismissed();
      hideBanner();
      deferredPrompt = null;
    });

    // 방문 횟수 조건이 충족된 경우 iOS 안내 배너를 즉시 표시한다
    // (iOS는 beforeinstallprompt 없이 배너를 표시할 수 있다)
    if (visitCount >= MIN_VISIT_COUNT && isIosSafari()) {
      tryShowBanner();
    }
  }

  // DOMContentLoaded 이후 초기화한다
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    // 이미 DOM이 준비된 경우 즉시 실행한다 (defer 속성으로 늦게 로드된 경우)
    init();
  }
})();
