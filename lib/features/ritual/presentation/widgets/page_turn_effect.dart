// 데일리 리추얼: 3D 책 넘김 효과 PageView
// Matrix4 perspective 변환으로 페이지가 책처럼 넘어가는 애니메이션을 구현한다.
// 넘기는 페이지 가장자리에 미세한 그림자를 추가하여 입체감을 높인다.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 3D 책 넘김 효과가 적용된 PageView 래퍼
/// [children]: 각 페이지 위젯 리스트
/// [controller]: 외부에서 주입하는 PageController
/// [onPageChanged]: 페이지 변경 콜백
class BookPageView extends StatefulWidget {
  final List<Widget> children;
  final PageController controller;
  final ValueChanged<int>? onPageChanged;

  const BookPageView({
    super.key,
    required this.children,
    required this.controller,
    this.onPageChanged,
  });

  @override
  State<BookPageView> createState() => _BookPageViewState();
}

class _BookPageViewState extends State<BookPageView> {
  /// 현재 스크롤 위치 (소수점 포함)
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  /// 스크롤 리스너 — 현재 페이지 위치를 갱신한다
  void _onScroll() {
    if (!widget.controller.hasClients) return;
    setState(() => _currentPage = widget.controller.page ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.controller,
      itemCount: widget.children.length,
      onPageChanged: widget.onPageChanged,
      itemBuilder: (context, index) {
        return _BookPage(
          page: widget.children[index],
          index: index,
          currentPage: _currentPage,
        );
      },
    );
  }
}

/// 개별 페이지에 3D 변환 + 그림자를 적용하는 위젯
class _BookPage extends StatelessWidget {
  final Widget page;
  final int index;
  final double currentPage;

  const _BookPage({
    required this.page,
    required this.index,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    // 현재 페이지와의 차이 (-1.0 ~ 1.0 범위로 클램프)
    final delta = (index - currentPage).clamp(-1.0, 1.0);
    // 회전 각도 (최대 90도, 넘기는 동안만 적용)
    final rotationAngle = delta * math.pi / 2;
    // 그림자 강도 (페이지가 겹칠수록 진해진다)
    final shadowAlpha = (delta.abs() * 0.3).clamp(0.0, 0.3);

    return Transform(
      alignment: delta >= 0 ? Alignment.centerLeft : Alignment.centerRight,
      transform: _perspectiveMatrix(rotationAngle),
      child: Stack(
        fit: StackFit.expand,
        children: [
          page,
          // 넘기는 동안 가장자리 그림자 오버레이
          if (delta.abs() > 0.01)
            _buildEdgeShadow(delta, shadowAlpha),
        ],
      ),
    );
  }

  /// 3D perspective가 적용된 Y축 회전 행렬을 생성한다
  Matrix4 _perspectiveMatrix(double angle) {
    final matrix = Matrix4.identity()
      // perspective 깊이 (값이 작을수록 3D 효과가 강해진다)
      ..setEntry(3, 2, 0.001)
      ..rotateY(angle);
    return matrix;
  }

  /// 페이지 가장자리에 반투명 그림자를 그린다
  Widget _buildEdgeShadow(double delta, double alpha) {
    // 왼쪽으로 넘길 때는 오른쪽에, 오른쪽으로 넘길 때는 왼쪽에 그림자
    final isForward = delta > 0;
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isForward ? Alignment.centerLeft : Alignment.centerRight,
            end: isForward ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              Colors.black.withValues(alpha: alpha),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
      ),
    );
  }
}
