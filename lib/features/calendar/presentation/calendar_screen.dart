// F2: 캘린더 화면 컨테이너
// 상단에 CalendarHeader(월/연도 네비게이션 + 뷰 전환 탭)을 배치한다.
// AN-09: AnimatedSwitcher로 뷰 전환 시 FadeTransition 적용
// FAB: 일정 추가 버튼 (EventCreateDialog 호출)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../shared/enums/view_type.dart';
import '../providers/calendar_provider.dart';
import 'widgets/calendar_header.dart';
import 'widgets/monthly_view.dart';
import 'widgets/weekly_view.dart';
import 'widgets/daily_view.dart';
import 'widgets/event_create_dialog.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/radius_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../shared/widgets/app_snack_bar.dart';

/// 캘린더 화면 메인 컨테이너
/// 다른 화면과 동일한 레이아웃 패턴 (SafeArea + FAB + AnimatedSwitcher) 적용
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(calendarViewTypeProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);

    return Scaffold(
      // 배경: AppBackground의 그라디언트를 투명하게 노출
      backgroundColor: ColorTokens.transparent,
      // FAB: 일정 추가 버튼
      floatingActionButton: _buildFab(context, selectedDate),
      // 상단 SafeArea는 MainShell에서 처리하므로 top: false로 중복 적용을 방지한다
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            // 상단 헤더 (calendar_header.dart로 분리)
            const CalendarHeader(),

            // 뷰 콘텐츠 (AN-09 AnimatedSwitcher)
            Expanded(
              child: AnimatedSwitcher(
                // AN-09: 뷰 전환 시 FadeTransition (300ms, 다른 화면과 duration 통일)
                duration: AppAnimation.medium,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: _buildCurrentView(currentView),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 현재 뷰 타입에 맞는 위젯 반환 (AnimatedSwitcher 키 부여)
  Widget _buildCurrentView(ViewType viewType) {
    switch (viewType) {
      case ViewType.monthly:
        return const MonthlyView(key: ValueKey('monthly'));
      case ViewType.weekly:
        return const WeeklyView(key: ValueKey('weekly'));
      case ViewType.daily:
        return const DailyView(key: ValueKey('daily'));
    }
  }

  /// FAB - 일정 추가 버튼
  Widget _buildFab(BuildContext context, DateTime selectedDate) {
    // FAB 하단 여백 (사이드 네비게이션 레이아웃 기준)
    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.bottomNavArea),
      child: FloatingActionButton(
        onPressed: () => _openEventDialog(context, selectedDate),
        backgroundColor: ColorTokens.main,
        foregroundColor: ColorTokens.white,
        elevation: AppLayout.elevationNone,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.fab)),
        child: const Icon(Icons.add_rounded, size: AppLayout.iconHuge),
      ),
    );
  }

  /// 일정 생성 다이얼로그를 열고 오류 발생 시 SnackBar로 사용자에게 알린다
  Future<void> _openEventDialog(BuildContext context, DateTime selectedDate) async {
    try {
      await showDialog<bool>(
        context: context,
        barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.50),
        builder: (context) => EventCreateDialog(
          initialDate: selectedDate,
        ),
      );
    } catch (e) {
      // 일정 생성 중 예기치 않은 오류 발생 시 사용자에게 알린다
      if (context.mounted) {
        AppSnackBar.showError(context, '일정 추가에 실패했습니다');
      }
    }
  }
}
