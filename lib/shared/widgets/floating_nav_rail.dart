// 플로팅 네비 레일 컨테이너 위젯
// 롱프레스 드래그로 수직 위치를 실시간 조절하는 기능을 캡슐화한다
// 드래그 모드 시 확대 + 글로우 효과로 시각적 피드백을 제공한다
// Hive에 수직 위치를 영속 저장한다
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/global_providers.dart';
import '../../core/theme/animation_tokens.dart';
import '../../core/theme/layout_tokens.dart';
import '../../core/theme/radius_tokens.dart';
import '../../core/theme/theme_colors.dart';
import 'side_nav_rail.dart';

/// 플로팅 세로 네비게이션 레일 컨테이너
/// 좌/우 배치, 수직 위치 드래그 조절, 글로우 피드백을 담당한다
/// MainShell의 build 메서드에서 직접 사용된다
class FloatingNavRail extends ConsumerStatefulWidget {
  /// 현재 활성 탭 인덱스
  final int currentIndex;

  /// 네비 레일이 왼쪽에 위치하는지 여부
  final bool isLeftSide;

  /// 수직 위치 (Alignment.y 값: -1.0=상단, 0.0=중앙, 1.0=하단)
  final double verticalPos;

  /// 탭 변경 콜백
  final void Function(int) onTabChange;

  const FloatingNavRail({
    super.key,
    required this.currentIndex,
    required this.isLeftSide,
    required this.verticalPos,
    required this.onTabChange,
  });

  @override
  ConsumerState<FloatingNavRail> createState() => _FloatingNavRailState();
}

class _FloatingNavRailState extends ConsumerState<FloatingNavRail> {
  /// 네비 바 드래그 모드 활성화 여부
  bool _isDraggingNav = false;

  /// 드래그 시작 시 초기 수직 위치 값 (Alignment.y)
  double _dragStartVerticalPos = 0.0;

  /// 드래그 시작 시 초기 글로벌 Y 좌표
  double _dragStartGlobalY = 0.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // 좌/우 위치: 설정값에 따라 동적으로 결정된다
      left: widget.isLeftSide ? 0 : null,
      right: widget.isLeftSide ? null : 0,
      top: 0,
      bottom: 0,
      child: SafeArea(
        // 반대쪽 SafeArea 여백을 비활성화한다
        left: !widget.isLeftSide,
        right: widget.isLeftSide,
        child: GestureDetector(
          onLongPressStart: _onLongPressStart,
          onLongPressMoveUpdate: _onLongPressMoveUpdate,
          onLongPressEnd: _onLongPressEnd,
          child: Align(
            // 수직 위치: 설정값(-1.0=상단, 0.0=중앙, 1.0=하단)에 따라 배치
            alignment: Alignment(0, widget.verticalPos),
            child: AnimatedScale(
              // 드래그 모드 시 1.08배 확대로 시각적 피드백을 제공한다
              scale: _isDraggingNav ? 1.08 : 1.0,
              duration: AppAnimation.standard,
              child: AnimatedContainer(
                duration: AppAnimation.standard,
                decoration: _isDraggingNav
                    ? BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppRadius.circle),
                        boxShadow: [
                          BoxShadow(
                            // 악센트 색상 글로우로 드래그 모드를 시각적으로 표현한다
                            color: context.themeColors
                                .accentWithAlpha(0.3),
                            blurRadius: EffectLayout.blurRadiusMd,
                          ),
                        ],
                      )
                    : null,
                child: SideNavRail(
                  currentIndex: widget.currentIndex,
                  isLeftSide: widget.isLeftSide,
                  onTabChange: widget.onTabChange,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 롱프레스 시작: 드래그 모드 진입 + 초기 위치 기록
  void _onLongPressStart(LongPressStartDetails details) {
    setState(() => _isDraggingNav = true);
    _dragStartVerticalPos = ref.read(navVerticalPosProvider);
    _dragStartGlobalY = details.globalPosition.dy;
    // 햅틱 피드백으로 드래그 모드 진입을 알린다
    HapticFeedback.mediumImpact();
  }

  /// 롱프레스 드래그 중: 수직 위치를 실시간 업데이트한다
  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDraggingNav) return;
    // 글로벌 Y 좌표의 변화량을 사용 가능 높이 기준으로 정규화한다
    final screenHeight = MediaQuery.of(context).size.height;
    final safeArea = MediaQuery.of(context).padding;
    final usableHeight = screenHeight - safeArea.top - safeArea.bottom;
    // 드래그 delta를 -1.0 ~ 1.0 범위로 매핑한다
    final deltaY = details.globalPosition.dy - _dragStartGlobalY;
    final normalizedDelta = (deltaY / usableHeight) * 2.0;
    final newPos =
        (_dragStartVerticalPos + normalizedDelta).clamp(-1.0, 1.0);
    ref.read(navVerticalPosProvider.notifier).state = newPos;
  }

  /// 롱프레스 종료: 드래그 모드 해제 + Hive에 위치 영속 저장
  void _onLongPressEnd(LongPressEndDetails details) {
    setState(() => _isDraggingNav = false);
    final pos = ref.read(navVerticalPosProvider);
    ref.read(hiveCacheServiceProvider).saveSetting(
          AppConstants.settingsKeyNavVerticalPos,
          pos,
        );
  }
}
