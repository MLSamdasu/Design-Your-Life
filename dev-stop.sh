#!/bin/bash
# 개발 환경 중지 스크립트
# 로컬 퍼스트 아키텍처 (Hive + Google Drive) — Flutter Web만 중지한다.
# 사용법: ./dev-stop.sh

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# 색상 출력 헬퍼
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo ""
echo "================================================"
echo "  Design Your Life - 개발 환경 중지"
echo "================================================"
echo ""

# ─── Flutter Web 중지 ──────────────────────────────────────────────────────
info "Flutter Web 중지 중..."

FLUTTER_PID=$(lsof -t -i :3000 2>/dev/null || true)
if [ -n "$FLUTTER_PID" ]; then
  kill $FLUTTER_PID 2>/dev/null || true
  success "Flutter Web 중지됨 (포트 3000)"
else
  warn "실행 중인 Flutter Web 없음"
fi

echo ""
echo "================================================"
echo "  개발 환경 중지 완료"
echo "================================================"
echo ""
echo "  다시 시작: ./dev-start.sh"
echo ""
