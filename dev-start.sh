#!/bin/bash
# 개발 환경 시작 스크립트
# 로컬 퍼스트 아키텍처 (Hive + Google Drive) — 별도 백엔드/DB 불필요
# Flutter Web만 시작한다.
# 사용법: ./dev-start.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"

# 색상 출력 헬퍼
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "================================================"
echo "  Design Your Life - 개발 환경 시작"
echo "================================================"
echo ""

# ─── Flutter Web 시작 ──────────────────────────────────────────────────────
info "Flutter Web 시작 중..."

cd "$PROJECT_ROOT"

# 이미 Flutter 개발 서버가 실행 중인지 확인
if lsof -i :3000 -sTCP:LISTEN > /dev/null 2>&1; then
  warn "포트 3000 이미 사용 중 — Flutter Web이 이미 실행 중일 수 있음"
  success "Flutter Web 이미 실행 중 (http://localhost:3000)"
else
  # Flutter Web 개발 서버 시작
  flutter run -d chrome --web-port=3000
fi

echo ""
echo "================================================"
echo "  개발 환경 시작 완료"
echo "================================================"
echo ""
echo "  Flutter:   http://localhost:3000"
echo "  종료: ./dev-stop.sh"
echo ""
