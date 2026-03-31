// F-Book: 독서 캘린더 메인 화면 컨테이너
// "내 책장"/"북 캘린더" 서브탭 전환을 bookSubTabProvider로 관리한다.
// AN-09: 서브탭 전환 시 CrossFade 300ms 애니메이션 적용
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/animation_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../shared/widgets/global_action_bar.dart';
import '../../../shared/widgets/segmented_control.dart';
import 'widgets/bookshelf_view.dart';
import 'widgets/book_calendar_view.dart';

/// 독서 서브탭 유형
enum BookSubTab {
  /// 내 책장
  bookshelf,

  /// 북 캘린더
  calendar,
}

/// 독서 화면 서브탭 Provider
final bookSubTabProvider = StateProvider<BookSubTab>((ref) {
  return BookSubTab.bookshelf;
});

/// 독서 캘린더 메인 화면 (F-Book)
class BookScreen extends ConsumerWidget {
  const BookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subTab = ref.watch(bookSubTabProvider);

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      // 상단 SafeArea는 MainShell에서 처리하므로 top: false로 중복 적용을 방지한다
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 헤더: 화면 타이틀 + 서브탭 전환
            _BookHeader(currentTab: subTab),
            const SizedBox(height: AppSpacing.xl),
            // 서브탭 콘텐츠 (AN-09: CrossFade 전환)
            Expanded(
              child: AnimatedSwitcher(
                duration: AppAnimation.medium,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: subTab == BookSubTab.bookshelf
                    ? const BookshelfView(key: ValueKey('bookshelf'))
                    : const BookCalendarView(
                        key: ValueKey('book-calendar')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 독서 화면 상단 헤더
/// 화면 타이틀 + Glass Pill 서브탭 전환
class _BookHeader extends ConsumerWidget {
  final BookSubTab currentTab;

  const _BookHeader({required this.currentTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.pageVertical,
        AppSpacing.pageHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 화면 타이틀 + 업적/설정 아이콘
          Row(
            children: [
              Expanded(
                child: Text(
                  '독서',
                  style: AppTypography.headingSm
                      .copyWith(color: context.themeColors.textPrimary),
                ),
              ),
              // 업적 + 설정 아이콘 버튼
              const GlobalActionBar(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // 서브탭 전환 (공유 SegmentedControl 사용)
          SegmentedControl<BookSubTab>(
            values: BookSubTab.values,
            selected: currentTab,
            labelBuilder: (tab) => switch (tab) {
              BookSubTab.bookshelf => '내 책장',
              BookSubTab.calendar => '북 캘린더',
            },
            onChanged: (tab) =>
                ref.read(bookSubTabProvider.notifier).state = tab,
          ),
        ],
      ),
    );
  }
}
