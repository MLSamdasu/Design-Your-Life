// 튜토리얼 탭 정보 데이터 모델
// 5탭 온보딩 가이드에서 사용하는 탭별 아이콘, 제목, 설명, 기능 목록을 정의한다.
// SRP 분리: 튜토리얼 스텝 데이터 정의만 담당한다.
import 'package:flutter/material.dart';

/// 튜토리얼 탭 정보 데이터 클래스
class TutorialTabInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;

  const TutorialTabInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
  });
}

/// 5개 탭별 튜토리얼 데이터
const tutorialTabInfoList = [
  TutorialTabInfo(
    icon: Icons.home_rounded,
    title: '홈',
    subtitle: '오늘 하루를 한눈에',
    description: '투두 요약, 습관 진행률, D-day, 타이머 등\n하루의 모든 정보를 대시보드에서 확인하세요.',
    features: [
      '오늘의 투두 완료율 요약',
      '습관 트래커 진행 현황',
      'D-day 카운트다운',
      '포모도로 타이머 바로가기',
    ],
  ),
  TutorialTabInfo(
    icon: Icons.calendar_today_rounded,
    title: '캘린더',
    subtitle: '일정을 시각적으로 관리',
    description: '월간/주간/일간 뷰로 전환하며\n시간대별 일정을 직관적으로 파악하세요.',
    features: [
      '월간 · 주간 · 일간 뷰 전환',
      '드래그로 일정 시간 조정',
      '범위 일정 (여행, 시험 등)',
      '색상별 카테고리 분류',
    ],
  ),
  TutorialTabInfo(
    icon: Icons.check_circle_rounded,
    title: '투두',
    subtitle: '할 일을 빠르게 정리',
    description: '자연어 빠른 입력과 하루 일정표로\n오늘의 할 일을 효율적으로 관리하세요.',
    features: [
      '자연어로 빠르게 투두 추가',
      '하루 일정표 타임라인 뷰',
      '태그 기반 분류 · 필터링',
      '체크 완료 시 연필 취소선',
    ],
  ),
  TutorialTabInfo(
    icon: Icons.loop_rounded,
    title: '습관',
    subtitle: '꾸준함이 변화를 만든다',
    description: '매일 반복하는 습관을 트래킹하고\n루틴 시간표로 하루 흐름을 설계하세요.',
    features: [
      '습관 트래커 + 스트릭 기록',
      '주간 시간표로 루틴 시각화',
      '인기 습관 프리셋 제공',
      '완료율 도넛 차트',
    ],
  ),
  TutorialTabInfo(
    icon: Icons.flag_rounded,
    title: '목표',
    subtitle: '큰 그림을 그려보세요',
    description: '연간/월간 목표와 만다라트 기법으로\n체계적인 목표 달성 계획을 세우세요.',
    features: [
      '연간 · 월간 목표 관리',
      '만다라트 81칸 목표 설계',
      '체크포인트 진행률 추적',
      '목표별 세부 과제 관리',
    ],
  ),
];
